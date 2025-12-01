import logging
import google.generativeai as genai
from google.generativeai import GenerationConfig, GenerativeModel
from config import settings 

# ====================================================================
# CẤU HÌNH GEMINI CLIENT
# ====================================================================
class GeminiClient:
    def __init__(self):
        self.model_name = "gemini-2.5-flash"
        self.api_key = settings.GEMINI_API_KEY
        self._model = None
        self._initialize()

    def _initialize(self):
        """Khởi tạo model và config"""
        try:
            genai.configure(api_key=self.api_key)
            generation_config = GenerationConfig(
                response_mime_type="text/plain"
            )
            self._model = GenerativeModel(self.model_name, generation_config=generation_config)
            logging.info(f"Gemini Model {self.model_name} initialized successfully.")
        except Exception as e:
            # Ghi log lỗi nghiêm trọng nếu không init được
            logging.exception("Không thể khởi tạo model Gemini: %s", e)
            raise

    async def generate_content(self, prompt: str) -> str:
        """
        Gửi prompt lên Google và nhận về text.
        """
        if not self._model:
            raise RuntimeError("Gemini Model chưa được khởi tạo.")
        
        try:
            # model.generate_content_async trả về coroutine
            response = await self._model.generate_content_async(prompt)
            
            # Lấy text an toàn
            text = getattr(response, "text", None)
            if text is None:
                text = str(response)
            return text
        except Exception as e:
            logging.error(f"Lỗi khi gọi Google API: {e}")
            raise e

# Tạo instance dùng chung (Singleton)
gemini_client = GeminiClient()