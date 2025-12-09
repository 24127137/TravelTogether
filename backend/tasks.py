# tasks.py
from apscheduler.schedulers.background import BackgroundScheduler
from sqlmodel import Session, create_engine, select
from config import settings
from security_service import SecurityService
from email_service import EmailService  # Import service mới
from db_tables import UserSecurity, Profiles # Cần import Profiles để lấy email
from datetime import datetime, timezone, timedelta
import asyncio
from firebase_admin import credentials, initialize_app, get_app

# 1. Tạo Engine riêng cho Scheduler (để tạo Session thủ công)
# Lưu ý: Engine này nên dùng chung connection string với app chính
engine = create_engine(settings.DATABASE_URL) 

# Khởi tạo Service
service = SecurityService()

# Vì gửi mail là hàm async (bất đồng bộ), mà APScheduler chạy sync,
# ta cần hàm wrapper này để chạy async trong sync context.
def run_async(coro):
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    loop.run_until_complete(coro)
    loop.close()

# 2. Định nghĩa Job (Công việc cụ thể)
def job_check_overdue_users():
    """
    Hàm này sẽ được gọi mỗi 30 phút.
    Nó tự mở Session, chạy logic, rồi tự đóng Session.
    """
    print("--- [Job Start] Checking overdue users... ---")
    try:
        with Session(engine) as session:
            # 1. Logic quét user cũ (Copy logic từ scan_overdue_users nhưng sửa một chút để lấy email)
            limit_time = datetime.now(timezone.utc) - timedelta(hours=36)
            
            # Query Join để lấy cả thông tin Security lẫn Email của User
            statement = select(UserSecurity, Profiles.emergency_contact, Profiles.fullname)\
                .join(Profiles, UserSecurity.user_id == Profiles.auth_user_id)\
                .where(
                    UserSecurity.last_confirmation_ts < limit_time,
                    UserSecurity.status != "overdue"
                )
            
            results = session.exec(statement).all()
            
            count = 0
            for sec, email, full_name in results:
                # Update DB
                sec.status = "overdue"
                sec.updated_at = datetime.now(timezone.utc)
                service.save_location(session, sec.user_id, reason="timeout", location=None)
                
                # GỬI EMAIL (Chạy bất đồng bộ)
                if email:
                    print(f"Found overdue: {email}. Sending email...")
                    run_async(EmailService.send_security_alert(
                        email_to=[email], # Hoặc email người thân
                        user_name=full_name or "Người dùng",
                        alert_type="overdue"
                    ))

                count += 1
            
            if count > 0:
                session.commit()
                print(f"[Job] Đã update và gửi mail cho {count} user.")
            else:
                print("[Job] Không có user nào quá hạn.")

    except Exception as e:
        print(f"[Job Error] {e}")
    print("--- [Job End] ---")

def job_check_24hour_confirmation():
    """
    === NEW JOB ===
    Chạy mỗi 1 giờ để kiểm tra user nào chưa xác nhận trong 24 giờ.
    - Tìm user có last_confirmation_ts cách hiện tại > 24 giờ
    - Update status thành "waiting"
    - Gửi notification nhắc nhở
    """
    print("--- [Job Start] Checking 24-hour unconfirmed users... ---")
    try:
        with Session(engine) as session:
            processed = service.notify_unconfirmed_24h(session)
            if processed > 0:
                print(f"[Job] Đã đánh dấu và gửi thông báo cho {processed} user chưa xác nhận.")
            else:
                print("[Job] Không có user nào chưa xác nhận > 24 giờ.")
    except Exception as e:
        print(f"[Job Error] {e}")
    print("--- [Job End] ---")

# 3. Khởi tạo Scheduler
scheduler = BackgroundScheduler()

# Thêm job vào lịch: chạy mỗi 30 phút
scheduler.add_job(
    job_check_overdue_users, 
    'interval', 
    minutes=30, 
    id='check_overdue_job',
    replace_existing=True
)

# === JOB 2: Kiểm tra user chưa confirm 24 giờ ===
scheduler.add_job(
    job_check_24hour_confirmation,
    'interval',
    hours=1,  # Chạy mỗi 1 giờ
    id='check_24hour_confirmation_job',
    replace_existing=True
)