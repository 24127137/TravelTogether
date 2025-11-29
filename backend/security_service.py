"""
security_service.py
Business logic layer for security operations
"""

import hashlib
from datetime import datetime, timedelta, time, timezone
from typing import Optional, List, Tuple
from sqlmodel import Session, select
from sqlalchemy import or_
from supabase import create_client, Client
from db_tables import UserSecurity, SecurityLocations
from config import settings

# ==================== CONFIGURATION ====================

supabase: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)

# Security thresholds
REMINDER_HOURS = 24
DANGER_HOURS = 36
MAX_RETRY_ATTEMPTS = 5

VN_TZ = timezone(timedelta(hours=7))

class SecurityService:

    @staticmethod
    def hash_pin(pin: str) -> str:
        """Hash PIN using SHA256"""
        return hashlib.sha256(pin.encode()).hexdigest()

    @staticmethod
    def verify(plain: str, hashed: str) -> bool:
        """Verify plain text against hashed value"""
        return SecurityService.hash_pin(plain) == hashed

    def get_user_security(self, session: Session, user_id: str) -> Optional[UserSecurity]:
        stmt = select(UserSecurity).where(UserSecurity.user_id == user_id)
        return session.exec(stmt).first()

    def create_user_security(self, session: Session, user_id: str) -> UserSecurity:

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
        current_location: Optional[dict[str, any]] = None # Cần truyền location từ API vào đây
    ) -> str:
        """
        Returns: "safe", "danger", "wrong"
        """
        sec = self.get_user_security(session, user_id)
        if not sec:
            return "wrong"

        # 1. Check Danger PIN
        # Sửa tên hàm self.verify_pin -> self.verify
        if sec.danger_pin_hash and self.verify(pin, sec.danger_pin_hash):
            # Truyền location thực tế vào
            self.save_location(session, user_id, reason="danger_pin", location=current_location)
            
            sec.wrong_attempt_count = 0
            sec.status = "danger"
            session.commit()
            return "danger"

        # 2. Check Safe PIN
        if sec.safe_pin_hash and self.verify(pin, sec.safe_pin_hash):
            # SỬA 4: Luôn dùng UTC để lưu vào DB
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
        
        session.commit()
        return "wrong"

    def save_location(self, session: Session, user_id: str, reason: str, location: Optional[dict[str, any]] = None):
        record = SecurityLocations(
            user_id=user_id,
            reason=reason,
            location=location, # JSON toạ độ
            timestamp=datetime.now(timezone.utc), # SỬA 4: Dùng UTC
        )
        session.add(record)
        session.commit()
        return True

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

        if delta_hours >= DANGER_HOURS:
            # Chỉ update trạng thái nếu nó chưa phải là overdue để tránh spam DB
            if sec.status != "overdue":
                sec.status = "overdue"
                # Lưu location (lúc này cronjob chạy nên có thể không có location, để None)
                self.save_location(session, user_id, reason="timeout")
                session.commit()
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
            
            # Commit một lần cho tất cả thay đổi
            if count > 0:
                session.commit()
                print(f"[Scheduler] Đã update {count} user sang trạng thái OVERDUE.")
            
            return count    