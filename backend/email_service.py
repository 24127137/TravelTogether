# email_service.py
from fastapi_mail import FastMail, MessageSchema, ConnectionConfig, MessageType
from typing import List
from backend.config import Settings
# Cấu hình kết nối


conf = ConnectionConfig(
    MAIL_USERNAME=Settings.MAIL_USERNAME,
    MAIL_PASSWORD=Settings.MAIL_PASSWORD,
    MAIL_FROM=Settings.MAIL_USERNAME,
    MAIL_PORT=Settings.MAIL_PORT,
    MAIL_SERVER=Settings.MAIL_SERVER,
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
        if alert_type == "overdue":
            subject = f"⚠️ CẢNH BÁO: Người thân {user_name} đã mất liên lạc!"
            body = f"""
            <div style="font-family: Arial, sans-serif; padding: 20px; border: 1px solid #e0e0e0; border-radius: 5px;">
                <h2 style="color: #d9534f;">Hệ thống Cảnh báo Du lịch</h2>
                <p>Xin chào,</p>
                <p>Hệ thống phát hiện người dùng <b>{user_name}</b> đã không xác nhận an toàn trong hơn 36 giờ.</p>
                <p>Trạng thái hiện tại: <b style="color: red;">OVERDUE (QUÁ HẠN)</b></p>
                <p>Vị trí cuối cùng đã được lưu vào hệ thống. Vui lòng thử liên lạc với người dùng ngay lập tức.</p>
                {location_html}
                <hr>
                <small>Đây là email tự động, vui lòng không trả lời.</small>
            </div>
            """
            
        # 2. Nội dung Email cho trường hợp Nguy hiểm (Danger PIN)
        elif alert_type == "danger":
            subject = f"🆘 KHẨN CẤP: {user_name} báo động nguy hiểm!"
            body = f"""
            <div style="font-family: Arial, sans-serif; padding: 20px; border: 2px solid red; border-radius: 5px; background-color: #fff5f5;">
                <h2 style="color: red;">CẢNH BÁO KHẨN CẤP</h2>
                <p>Người dùng <b>{user_name}</b> vừa kích hoạt mã PIN nguy hiểm hoặc nhập sai PIN nhiều lần.</p>
                <p>Hệ thống đang bí mật theo dõi vị trí.</p>
                <p><b>Hành động khuyến nghị:</b> Kiểm tra vị trí và liên hệ khẩn cấp.</p>
                {location_html}
            </div>
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