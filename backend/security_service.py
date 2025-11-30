import hashlib
import asyncio
from datetime import datetime, timezone, timedelta, time
from typing import Optional, Dict, Any
from sqlmodel import Session, select
from sqlalchemy import Column, text, or_
from sqlalchemy.dialects.postgresql import UUID, JSONB, TEXT, TIME

# Import các bảng
from db_tables import UserSecurity, SecurityLocations, Profiles 
# Import Email Service
from email_service import EmailService

# ==================== CONSTANTS ====================
MAX_RETRY_ATTEMPTS = 5

class SecurityService:
    
    # SỬA 1: Dùng @staticmethod để không cần 'self' và sửa logic gọi hàm
    @staticmethod
    def hash_pin(pin: str) -> str:
        """Hash PIN using SHA256"""
        return hashlib.sha256(pin.encode()).hexdigest()

    @staticmethod
    def verify(plain: str, hashed: str) -> bool:
        """Verify plain text against hashed value"""
        return SecurityService.hash_pin(plain) == hashed
    def _trigger_email(self, session: Session, user_id: str, alert_type: str, location: Optional[Dict[str, Any]] = None):
        """
        Tìm email user và gửi cảnh báo. 
        Tự động tạo Google Maps Link nếu có toạ độ.
        """
        # 1. Lấy thông tin User (Email & Tên)
        profile = session.exec(select(Profiles).where(Profiles.auth_user_id == user_id)).first()
        if not profile or not profile.email:
            print(f"⚠️ [Security] Không tìm thấy email cho user {user_id}")
            return

        # 2. Tạo Link Google Maps (nếu có toạ độ)
        map_link = None
        if location and 'latitude' in location and 'longitude' in location:
            lat = location['latitude']
            long = location['longitude']
            map_link = f"https://www.google.com/maps?q={lat},{long}"

        # 3. Gọi EmailService (Xử lý bất đồng bộ trong môi trường đồng bộ)
        # Vì EmailService là async, ta cần trick này để nó chạy được trong hàm def thường
        try:
            loop = asyncio.get_running_loop()
            # Nếu đang chạy trong FastAPI (đã có loop), dùng create_task để không chặn luồng chính
            loop.create_task(EmailService.send_security_alert(
                email_to=[profile.email],
                user_name=profile.full_name or "Người dùng",
                alert_type=alert_type,
                map_link=map_link # Truyền thêm link bản đồ
            ))
        except RuntimeError:
            # Nếu chạy trong Scheduler (chưa có loop), dùng asyncio.run
            asyncio.run(EmailService.send_security_alert(
                email_to=[profile.email],
                user_name=profile.full_name or "Người dùng",
                alert_type=alert_type,
                map_link=map_link
            ))
    def get_user_security(self, session: Session, user_id: str) -> Optional[UserSecurity]:
        stmt = select(UserSecurity).where(UserSecurity.user_id == user_id)
        return session.exec(stmt).first()

    def create_user_security(self, session: Session, user_id: str) -> UserSecurity:
        # SỬA 2: Các trường datetime nên để None hoặc set UTC ngay lúc tạo nếu cần
        sec = UserSecurity(
            user_id=user_id,
            safe_pin_hash=None,
            danger_pin_hash=None,
            default_confirmation_time=None,
            status="safe",
            wrong_attempt_count=0
        )
        session.add(sec)
        session.commit()
        session.refresh(sec)
        return sec

    def set_safe_pin(self, session: Session, user_id: str, pin: str):
        sec = self.get_user_security(session, user_id)
        if not sec:
            sec = self.create_user_security(session, user_id)
        
        # Gọi static method đúng cách
        sec.safe_pin_hash = self.hash_pin(pin)
        session.commit()
        return True

    def set_danger_pin(self, session: Session, user_id: str, pin: str):
        sec = self.get_user_security(session, user_id)
        if not sec:
            sec = self.create_user_security(session, user_id)

        sec.danger_pin_hash = self.hash_pin(pin)
        session.commit()
        return True

    # ============================================================
    # SỬA 3: Validate PIN & Save Location Logic
    # ============================================================
    def validate_pin(
        self, 
        session: Session, 
        user_id: str, 
        pin: str, 
        current_location: Optional[Dict[str, Any]] = None
    ) -> str:
        sec = self.get_user_security(session, user_id)
        if not sec:
            return "wrong"

        # 1. Check Danger PIN
        if sec.danger_pin_hash and self.verify(pin, sec.danger_pin_hash):
            self.save_location(session, user_id, reason="danger_pin", location=current_location)
            
            sec.wrong_attempt_count = 0
            sec.status = "danger"
            session.commit()
            
            # [CẬP NHẬT] Gửi mail báo động ngay lập tức
            self._trigger_email(session, user_id, "danger", current_location)
            
            return "danger"

        # 2. Check Safe PIN
        if sec.safe_pin_hash and self.verify(pin, sec.safe_pin_hash):
            sec.last_confirmation_ts = datetime.now(timezone.utc)
            sec.wrong_attempt_count = 0
            sec.status = "safe"
            session.commit()
            return "safe"

        # 3. Handle Wrong PIN
        sec.wrong_attempt_count += 1
        
        # Nếu sai quá 5 lần -> Trigger Danger
        if sec.wrong_attempt_count >= MAX_RETRY_ATTEMPTS:
            self.save_location(session, user_id, reason="wrong_pin", location=current_location)
            sec.status = "danger"
            
            # [CẬP NHẬT] Gửi mail khi sai quá nhiều lần
            self._trigger_email(session, user_id, "danger", current_location)
        
        session.commit()
        return "wrong"
    # ============================================================
    # SỬA 5: Check Overdue logic
    # ============================================================
    def check_overdue(self, session: Session, user_id: str) -> bool:
        sec = self.get_user_security(session, user_id)
        if not sec or not sec.last_confirmation_ts:
            return False

        # Lấy thời gian UTC hiện tại
        now_utc = datetime.now(timezone.utc)
        
        # Đảm bảo sec.last_confirmation_ts có timezone. 
        # Nếu DB trả về naive (không có tz), ta phải gán nó là UTC trước khi so sánh.
        last_ts = sec.last_confirmation_ts
        if last_ts.tzinfo is None:
            last_ts = last_ts.replace(tzinfo=timezone.utc)

        delta_hours = (now_utc - last_ts).total_seconds() / 3600

        if delta_hours >= 36:
            # Chỉ update trạng thái nếu nó chưa phải là overdue để tránh spam DB
            if sec.status != "overdue":
                sec.status = "overdue"
                # Lưu location (lúc này cronjob chạy nên có thể không có location, để None)
                self.save_location(session, user_id, reason="timeout")
                session.commit()
                self._trigger_email(session, user_id, "overdue", location=None)
            return True

        return False
    def scan_overdue_users(self, session: Session) -> int:
        """
        Quét tất cả user có last_confirmation_ts quá 36h 
        và chưa set status='overdue'.
        Returns: Số lượng user bị update.
        """
        # 1. Tính mốc thời gian giới hạn (Hiện tại - 36 tiếng)
        # Lưu ý: Luôn dùng UTC
        limit_time = datetime.now(timezone.utc) - timedelta(hours=36)

        # 2. Query tìm các nạn nhân
        # Điều kiện: (last_confirmation < limit_time) VÀ (status != 'overdue')
        statement = select(UserSecurity).where(
            UserSecurity.last_confirmation_ts < limit_time,
            UserSecurity.status != "overdue"
        )
        
        results = session.exec(statement).all()
        count = 0

        # 3. Update từng user
        for sec in results:
            sec.status = "overdue"
            sec.updated_at = datetime.now(timezone.utc)
            
            # Lưu log location (Không có toạ độ vì chạy ngầm)
            self.save_location(session, sec.user_id, reason="timeout", location=None)
            count += 1
            self._trigger_email(session, sec.user_id, "overdue", location=None)
        # Commit một lần cho tất cả thay đổi
        if count > 0:
            session.commit()
            print(f"[Scheduler] Đã update {count} user sang trạng thái OVERDUE.")
        
        return count