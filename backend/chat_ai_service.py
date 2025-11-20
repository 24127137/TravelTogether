import logging
from typing import List, Optional
from sqlmodel import Session, select
from sqlalchemy import desc
from datetime import datetime, timezone

# Import Model và Config
from chat_ai_model import gemini_client
from db_tables import AIMessages # Đảm bảo file chứa class AIMessages tên là db_tables.py hoặc sửa lại cho đúng

class ChatService:
    
    def __init__(self, db_session: Session):
        """Inject db_session từ Dependency của FastAPI"""
        self.db = db_session
    
    # ====================================================================
    # 1. DATABASE OPERATIONS (Dùng SQLModel)
    # ====================================================================

    def _get_user_messages(self, user_id: str, limit: int = 20) -> List[AIMessages]:
        """Lấy lịch sử chat gần nhất để làm context cho AI"""
        try:
            # Lấy tin nhắn mới nhất, sau đó đảo ngược lại để đúng thứ tự thời gian (Cũ -> Mới)
            statement = select(AIMessages)\
                .where(AIMessages.user_id == user_id)\
                .order_by(desc(AIMessages.created_at))\
                .limit(limit)
            
            messages = self.db.exec(statement).all()
            return list(reversed(messages)) 
        except Exception as e:
            logging.error(f"DB Error (Get User Messages): {e}")
            return []

    def _save_message(self, user_id: str, role: str, content: str, message_type: str = "text", image_url: Optional[str] = None) -> AIMessages:
        """Lưu tin nhắn (User hoặc AI) vào DB"""
        try:
            message = AIMessages(
                user_id=user_id,
                role=role, # 'user' hoặc 'model'
                message_type=message_type,
                content=content,
                image_url=image_url,
                created_at=datetime.now(timezone.utc)
            )
            self.db.add(message)
            self.db.commit()
            self.db.refresh(message)
            return message
        except Exception as e:
            logging.error(f"DB Error (Save Message): {e}")
            self.db.rollback()
            raise e

    def get_chat_history(self, user_id: str, limit: int = 50) -> List[dict]:
        """Lấy lịch sử trả về cho API (Format JSON)"""
        messages = self._get_user_messages(user_id, limit)
        return [
            {
                "id": msg.id,
                "role": msg.role,
                "content": msg.content,
                "message_type": msg.message_type,
                "image_url": msg.image_url,
                "created_at": msg.created_at.isoformat() if msg.created_at else None
            }
            for msg in messages
        ]

    def delete_chat_history(self, user_id: str):
        """Xóa toàn bộ chat của user"""
        try:
            statement = select(AIMessages).where(AIMessages.user_id == user_id)
            messages = self.db.exec(statement).all()
            for msg in messages:
                self.db.delete(msg)
            self.db.commit()
        except Exception as e:
            self.db.rollback()
            logging.error(f"Error clearing chat: {e}")
            raise e

    # ====================================================================
    # 2. CORE LOGIC: GỌI GEMINI & XỬ LÝ
    # ====================================================================

    def _build_context_prompt(self, history: List[AIMessages], new_question: str) -> str:
        """
        Tạo prompt chứa lịch sử chat để Gemini hiểu ngữ cảnh.
        Format:
        User: ...
        Model: ...
        User: [Câu hỏi mới]
        """
        prompt_parts = [
            "Bạn là trợ lý AI hữu ích. Hãy trả lời dựa trên lịch sử cuộc trò chuyện sau đây (nếu có):",
            "--- Bắt đầu lịch sử ---"
        ]

        for msg in history:
            role_label = "User" if msg.role == "user" else "Model"
            content = msg.content if msg.content else "[Hình ảnh]"
            prompt_parts.append(f"{role_label}: {content}")
        
        prompt_parts.append("--- Kết thúc lịch sử ---")
        prompt_parts.append(f"User (Mới nhất): {new_question}")
        prompt_parts.append("Model:")
        
        return "\n".join(prompt_parts)

    async def process_user_message(self, user_id: str, message: str) -> str:
        """
        Hàm chính được API gọi:
        1. Lưu câu hỏi của User vào DB.
        2. Lấy lịch sử cũ làm context.
        3. Gọi Gemini.
        4. Lưu câu trả lời của AI vào DB.
        5. Trả về text.
        """
        # Bước 1: Lưu tin nhắn User
        # Lưu ý: Nếu có ảnh thì cần logic xử lý ảnh ở đây, tạm thời ta xử lý text
        self._save_message(user_id=user_id, role="user", content=message)

        # Bước 2: Lấy lịch sử (bao gồm cả câu vừa lưu)
        # Lấy khoảng 10 tin gần nhất để tiết kiệm token
        history_msgs = self._get_user_messages(user_id, limit=10)

        # Bước 3: Tạo prompt
        full_prompt = self._build_context_prompt(history_msgs, message)

        # Bước 4: Gọi Gemini
        try:
            ai_response_text = await gemini_client.generate_content(full_prompt)
        except Exception as e:
            # Nếu lỗi API, có thể xóa tin nhắn user vừa lưu để tránh bị lẻ loi (tuỳ chọn)
            raise e

        # Bước 5: Lưu tin nhắn AI
        self._save_message(user_id=user_id, role="model", content=ai_response_text)

        return ai_response_text