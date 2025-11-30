# email_service.py
from fastapi_mail import FastMail, MessageSchema, ConnectionConfig, MessageType
from typing import List

# Cấu hình kết nối
MAIL_USERNAME = "apptraveltogether@gmail.com"
MAIL_PASSWORD = "okgi nsdg lkhb cspa"
MAIL_PORT = 587
MAIL_SERVER = "smtp.gmail.com"
MAIL_FROM_NAME = "Travel Security Alert"

conf = ConnectionConfig(
    MAIL_USERNAME=MAIL_USERNAME,
    MAIL_PASSWORD=MAIL_PASSWORD,
    MAIL_FROM=MAIL_USERNAME,
    MAIL_PORT=MAIL_PORT,
    MAIL_SERVER=MAIL_SERVER,
    MAIL_STARTTLS=True,
    MAIL_SSL_TLS=False,
    USE_CREDENTIALS=True,
    VALIDATE_CERTS=True
)

class EmailService:
    
    @staticmethod
    async def send_security_alert(email_to: List[str], user_name: str, alert_type: str):
        """
        Gửi email cảnh báo khẩn cấp.
        alert_type: "overdue" | "danger"
        """
        
        subject = ""
        body = ""

        if alert_type == "overdue":
            subject = f"⚠️ CẢNH BÁO: Người thân {user_name} đã mất liên lạc!"
            body = f"""
            <h3>Hệ thống Travel Security thông báo</h3>
            <p>Người dùng <b>{user_name}</b> đã không xác nhận an toàn trong hơn 36 giờ.</p>
            <p>Vị trí cuối cùng đã được ghi nhận vào hệ thống.</p>
            <p>Vui lòng liên hệ với người dùng ngay lập tức.</p>
            """
        elif alert_type == "danger":
            subject = f"🆘 KHẨN CẤP: {user_name} báo động nguy hiểm!"
            body = f"""
            <h3>CẢNH BÁO KHẨN CẤP</h3>
            <p>Người dùng <b>{user_name}</b> vừa kích hoạt mã PIN nguy hiểm hoặc nhập sai nhiều lần.</p>
            <p>Hệ thống đang theo dõi vị trí.</p>
            """

        message = MessageSchema(
            subject=subject,
            recipients=email_to,
            body=body,
            subtype=MessageType.html
        )

        fm = FastMail(conf)
        
        try:
            await fm.send_message(message)
            print(f"📧 Đã gửi email cảnh báo tới {email_to}")
            return True
        except Exception as e:
            print(f"❌ Lỗi gửi email: {str(e)}")
            return False