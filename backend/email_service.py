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
    async def send_security_alert(email_to: List[str], user_name: str, alert_type: str, map_link: str = None):
        """
        Gửi email cảnh báo khẩn cấp.
        alert_type: "overdue" | "danger"
        """
        
        subject = ""
        body = ""

        location_html = ""
        if map_link:
            location_html = f"""
            <p>📍 <b>Vị trí ghi nhận:</b> <a href="{map_link}" style="background-color: #007bff; color: white; padding: 10px 15px; text-decoration: none; border-radius: 5px;">Xem trên Google Maps</a></p>
            <p><small>(Link: {map_link})</small></p>
            """
        else:
            location_html = "<p>📍 <i>Không có dữ liệu vị trí GPS.</i></p>"

        # Chèn location_html vào body
        if alert_type == "overdue":
            body = f"""
            ... (các thẻ html cũ) ...
            <p>Vui lòng liên hệ với người dùng ngay lập tức.</p>
            {location_html} 
            ...
            """
        elif alert_type == "danger":
             body = f"""
            ... (các thẻ html cũ) ...
            <p>Hệ thống đang bí mật theo dõi vị trí.</p>
            {location_html}
            ...
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