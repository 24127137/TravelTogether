# tasks.py
from apscheduler.schedulers.background import BackgroundScheduler
from sqlmodel import Session, create_engine
from config import settings
from security_service import SecurityService

# 1. Tạo Engine riêng cho Scheduler (để tạo Session thủ công)
# Lưu ý: Engine này nên dùng chung connection string với app chính
engine = create_engine(settings.DATABASE_URL) 

# Khởi tạo Service
service = SecurityService()

# 2. Định nghĩa Job (Công việc cụ thể)
def job_check_overdue_users():
    """
    Hàm này sẽ được gọi mỗi 30 phút.
    Nó tự mở Session, chạy logic, rồi tự đóng Session.
    """
    print("--- [Job Start] Checking overdue users... ---")
    try:
        # Tự tạo session context (vì không có Depends của FastAPI ở đây)
        with Session(engine) as session:
            count = service.scan_overdue_users(session)
            if count == 0:
                print("[Job] Không tìm thấy user nào quá hạn.")
    except Exception as e:
        print(f"[Job Error] Lỗi khi chạy quét user: {e}")
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