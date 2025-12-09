import hashlib
import asyncio
from datetime import datetime, timezone, timedelta, time
from typing import Optional, Dict, Any
from sqlmodel import Session, select
from sqlalchemy import Column, text, or_
from sqlalchemy.dialects.postgresql import UUID, JSONB, TEXT, TIME
from supabase import Client
from firebase_admin import messaging

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
        if not profile or not profile.emergency_contact:
            print(f"⚠️ [Security] Không tìm thấy emergency contact cho user {user_id}")
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
                email_to=[profile.emergency_contact],
                user_name=profile.fullname or "Người dùng",
                alert_type=alert_type,
                map_link=map_link # Truyền thêm link bản đồ
            ))
        except RuntimeError:
            # Nếu chạy trong Scheduler (chưa có loop), dùng asyncio.run
            asyncio.run(EmailService.send_security_alert(
                email_to=[profile.emergency_contact],
                user_name=profile.fullname or "Người dùng",
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
    
    def save_location(self, session: Session, user_id: str, reason: str, location: Optional[Dict[str, Any]] = None):
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
        limit_time = datetime.now(timezone.utc) - timedelta(hours=36)

        # Query Join để lấy cả thông tin Security lẫn Email của User
        statement = select(UserSecurity, Profiles.emergency_contact, Profiles.fullname)\
            .join(Profiles, UserSecurity.user_id == Profiles.auth_user_id)\
            .where(
                UserSecurity.last_confirmation_ts < limit_time,
                UserSecurity.status != "overdue"
            )
    
        results = session.exec(statement).all()
        if not results:
            print("[scan_overdue_users] No overdue users found.")
            return 0

        count = 0
        for sec, _, _ in results:
            try:
                # Update status and timestamp
                sec.status = "overdue"
                sec.updated_at = datetime.now(timezone.utc)

                # Save a location/event record (no location available here)
                self.save_location(session, sec.user_id, reason="timeout", location=None)

                # Send email notification (uses profile emergency_contact via _trigger_email)
                try:
                    self._trigger_email(session, sec.user_id, "overdue")
                except Exception as e:
                    print(f"[scan_overdue_users] Failed to send email for {sec.user_id}: {e}")

                count += 1
            except Exception as e:
                print(f"[scan_overdue_users] Error processing user {getattr(sec, 'user_id', 'unknown')}: {e}")

        if count > 0:
            session.commit()
            print(f"[Scheduler] Đã update {count} user sang trạng thái OVERDUE.")
        
        return count
    
    def _send_push_notification(self, token: str, user_id: str) -> bool:
        """
        Hỗ trợ gửi FCM cho 1 device token.
        - token: str (device token)
        - user_id: str (for logs / potential cleanup)
        Returns True on success, False on failure.
        """
        if not token:
            print(f"   -> No device token for user {user_id}")
            return False

        try:
            message = messaging.Message(
                notification=messaging.Notification(
                    title="Yêu cầu xác thực bảo mật",
                    body="Đã quá 24h kể từ lần xác thực cuối. Vui lòng nhập PIN để tiếp tục."
                ),
                data={
                    "type": "SECURITY_ALERT",
                    "action": "OPEN_PIN_SCREEN",
                    "user_id": user_id
                },
                token=token,
            )
            response = messaging.send(message)
            print(f"   -> Đã gửi FCM tới User {user_id} | Message ID: {response}")
            return True
        except Exception as e:
            # Nếu token lỗi/hết hạn, ghi log; (nếu cần) xóa token khỏi DB ở đây
            print(f"   -> Gửi thất bại tới User {user_id}: {e}")
            return False

    def notify_unconfirmed_24h(self, session: Session) -> int:
        """
        DB-based notifier:
        - Tìm user có last_confirmation_ts > 24h và status not in (waiting, overdue)
        - Cập nhật status -> "waiting"
        - Gửi FCM nếu có device token (TokenSecurity table), ngược lại fallback gửi email
        Returns number of users processed.
        """
        # lazy-import TokenSecurity (table may not exist in all schemas)
        try:
            from db_tables import TokenSecurity
        except Exception:
            TokenSecurity = None

        threshold_time = datetime.now(timezone.utc) - timedelta(hours=24)

        stmt = select(UserSecurity, Profiles.emergency_contact, Profiles.fullname)\
            .join(Profiles, UserSecurity.user_id == Profiles.auth_user_id)\
            .where(
                UserSecurity.last_confirmation_ts < threshold_time,
                ~UserSecurity.status.in_(["waiting", "overdue"])
            )

        results = session.exec(stmt).all()
        if not results:
            print("[notify_unconfirmed_24h] No users found.")
            return 0

        count = 0
        for sec, email, full_name in results:
            device_token = None
            if TokenSecurity is not None:
                tok = session.exec(
                    select(TokenSecurity).where(
                        TokenSecurity.user_id == sec.user_id,
                        TokenSecurity.device_token != None
                    )
                ).first()
                if tok:
                    device_token = getattr(tok, "device_token", None)

            notified = False
            if device_token:
                notified = self._send_push_notification(device_token, sec.user_id)
            if not notified:
                # fallback to email notification
                print(f"[notify_unconfirmed_24h] Fallback email for user {sec.user_id}")
                try:
                    self._trigger_email(session, sec.user_id, "confirmation_reminder")
                    notified = True
                except Exception as e:
                    print(f"[notify_unconfirmed_24h] Email send failed for {sec.user_id}: {e}")

            # update status and timestamp regardless of notification success to avoid repeat spam
            sec.status = "waiting"
            sec.updated_at = datetime.now(timezone.utc)
            count += 1

        if count > 0:
            session.commit()
            print(f"[notify_unconfirmed_24h] Updated and notified {count} users.")
        return count
