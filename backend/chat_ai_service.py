import uuid
import asyncio
import logging
from typing import Dict, List, Optional, Any
from supabase import create_client, Client

# Import Model và Config
from chat_ai_model import gemini_client
from config import settings

# ====================================================================
# KHỞI TẠO SUPABASE CLIENT
# ====================================================================
try:
    sb_client: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
    logging.info("Supabase client initialized successfully")
except Exception as e:
    logging.exception(f"Lỗi khởi tạo Supabase trong AI Service: {e}")
    sb_client = None

class ChatService:
    
    # ====================================================================
    # HELPER: THAO TÁC DATABASE (SUPABASE)
    # ====================================================================
    def _get_session_by_user_id(self, user_id: str) -> Optional[Dict]:
        """✅ FIXED: Tìm session theo user_id (vì user_id là UNIQUE)"""
        if not sb_client: 
            logging.warning("Supabase client not initialized")
            return None
        try:
            response = sb_client.table("chat_sessions").select("*").eq("user_id", user_id).execute()
            if response.data and len(response.data) > 0:
                return response.data[0]
            return None
        except Exception as e:
            logging.error(f"DB Error (Get Session by User): {e}")
            return None

    def _get_session_by_id(self, session_id: str) -> Optional[Dict]:
        """✅ NEW: Tìm session theo session_id"""
        if not sb_client: return None
        try:
            response = sb_client.table("chat_sessions").select("*").eq("session_id", session_id).execute()
            if response.data and len(response.data) > 0:
                return response.data[0]
            return None
        except Exception as e:
            logging.error(f"DB Error (Get Session by ID): {e}")
            return None

    def _get_history_from_db(self, session_id: str) -> List[Dict]:
        """Lấy lịch sử chat của 1 session"""
        if not sb_client: return []
        try:
            response = sb_client.table("chat_sessions").select("history").eq("session_id", session_id).execute()
            if response.data and len(response.data) > 0:
                return response.data[0].get('history', [])
            return []
        except Exception as e:
            logging.error(f"DB Error (Get History): {e}")
            return []

    def _save_session_to_db(self, session_id: str, history: List[Dict], user_id: str = None):
        """✅ FIXED: Lưu hoặc cập nhật session vào Supabase"""
        if not sb_client: 
            logging.warning("Cannot save session: Supabase client not initialized")
            return
        try:
            data = {
                "session_id": session_id,
                "history": history
            }
            if user_id:
                data["user_id"] = user_id
            
            # Upsert: Nếu có rồi thì update, chưa có thì insert
            sb_client.table("chat_sessions").upsert(data, on_conflict="session_id").execute()
            logging.info(f"Session {session_id} saved successfully")
        except Exception as e:
            logging.error(f"DB Error (Save Session): {e}")

    def _get_all_sessions_by_user(self, user_id: str) -> List[Dict]:
        """Lấy tất cả sessions của user"""
        if not sb_client: return []
        try:
            response = sb_client.table("chat_sessions").select("*").eq("user_id", user_id).execute()
            return response.data if response.data else []
        except Exception as e:
            logging.error(f"DB Error (Get All Sessions): {e}")
            return []

    def _delete_session_from_db(self, session_id: str):
        """Xóa session khỏi DB"""
        if not sb_client: return
        try:
            sb_client.table("chat_sessions").delete().eq("session_id", session_id).execute()
            logging.info(f"Session {session_id} deleted")
        except Exception as e:
            logging.error(f"DB Error (Delete Session): {e}")

    # ====================================================================
    # LOGIC CHÍNH: XỬ LÝ SESSION & TIN NHẮN
    # ====================================================================
    def create_or_restore_session(self, user_id: str) -> Dict[str, Any]:
        """
        ✅ FIXED: Tạo session mới hoặc khôi phục session cũ.
        - Nếu user_id đã có session → trả về session cũ
        - Nếu chưa có → tạo mới và gắn user_id
        
        Returns: {"session_id": str, "is_restored": bool}
        """
        # 1. Cố gắng khôi phục session cũ
        existing_session = self._get_session_by_user_id(user_id)
        if existing_session:
            logging.info(f"Restored session for user {user_id}")
            return {
                "session_id": existing_session['session_id'],
                "is_restored": True
            }

        # 2. Tạo mới hoàn toàn
        new_sid = uuid.uuid4().hex
        logging.info(f"Created new session {new_sid} for user {user_id}")
        
        # 3. Lưu session rỗng vào DB để giữ chỗ
        self._save_session_to_db(new_sid, [], user_id)
        
        return {
            "session_id": new_sid,
            "is_restored": False
        }

    def _build_prompt(self, history: List[Dict[str, str]], user_message: str) -> str:
        """Helper: Tạo prompt cho Gemini"""
        pieces = []
        for msg in history:
            role = msg.get("role", "user")
            text = msg.get("text", "")
            pieces.append(f"{role.upper()}: {text}")
        
        pieces.append(f"USER: {user_message}")
        pieces.append("ASSISTANT:")
        
        system_instruction = "Bạn là một trợ lý du lịch thân thiện, trả lời ngắn gọn, rõ ràng và lịch sự."
        return system_instruction + "\n\n" + "\n".join(pieces)

    async def process_message(self, session_id: str, message: str) -> str:
        """
        ✅ FIXED: Flow xử lý tin nhắn:
        1. Kiểm tra session có tồn tại không
        2. Lấy lịch sử từ DB
        3. Gọi Gemini
        4. Lưu cập nhật vào DB
        """
        # 1. Kiểm tra session tồn tại
        session = self._get_session_by_id(session_id)
        if not session:
            raise ValueError(f"Session {session_id} không tồn tại")
        
        # 2. Lấy lịch sử
        history = session.get('history', [])
        
        # 3. Thêm tin nhắn user (KHÔNG thêm vào prompt build vì đã có trong _build_prompt)
        history.append({"role": "user", "text": message})

        # 4. Tạo Prompt
        prompt = self._build_prompt(history[:-1], message)  

        # 5. Gọi Model
        try:
            ai_response_text = await asyncio.wait_for(
                gemini_client.generate_content(prompt), 
                timeout=30.0
            )
        except asyncio.TimeoutError:
            logging.error("Gemini API timeout")
            raise TimeoutError("AI phản hồi quá lâu")
        except Exception as e:
            logging.error(f"Gemini API error: {e}")
            raise
        
        # 6. Thêm tin nhắn AI
        history.append({"role": "assistant", "text": ai_response_text})

        # 7. Lưu xuống DB
        user_id = session.get('user_id')
        self._save_session_to_db(session_id, history, user_id)

        return ai_response_text

# Instance service
chat_service = ChatService()