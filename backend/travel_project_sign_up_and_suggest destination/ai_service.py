import google.generativeai as genai
import json
from typing import List, Dict, Any
from models import Destination, RecommendationOutput
from config import settings # <-- Đọc "bí mật" từ config

# Cấu hình model (Đọc key từ file config)
try:
    genai.configure(api_key=settings.GEMINI_API_KEY)
    
    generation_config = genai.GenerationConfig(
        response_mime_type="application/json",
    )
    model = genai.GenerativeModel(
        'gemini-2.5-flash-preview-09-2025',
        generation_config=generation_config
    )
except Exception as e:
    print(f"LỖI: Không thể cấu hình Gemini. API Key có đúng không? Lỗi: {e}")
    model = None

# SỬA ĐỔI (GĐ 4.3): Bỏ "reasoning" khỏi Schema
JSON_OUTPUT_SCHEMA = {
    "type": "array",
    "items": {
        "type": "object",
        "properties": {
            "location_name": {"type": "string"},
            "score": {"type": "integer"}
        },
        "required": ["location_name", "score"]
    }
}

async def rank_destinations_by_ai(
    user_interests: List[str],
    destinations: List[Destination]
) -> List[RecommendationOutput]:
    
    if not model:
        print("LỖI: Model AI chưa được khởi tạo. Bỏ qua bước xếp hạng.")
        return []

    locations_text_list = []
    for dest in destinations:
        locations_text_list.append(
            f"Tên: {dest.location_name}\nMô tả: {dest.description}\n---"
        )
    locations_text_blob = "\n".join(locations_text_list)
    
    # SỬA ĐỔI (GĐ 4.3): Bỏ yêu cầu "reasoning" khỏi Prompt
    prompt = f"""
    Bạn là một chuyên gia du lịch cực kỳ thông minh.
    Nhiệm vụ của bạn là xếp hạng các địa điểm du lịch dựa trên sở thích của người dùng.

    Đây là SỞ THÍCH của người dùng:
    {json.dumps(user_interests, ensure_ascii=False)}

    Và đây là DANH SÁCH CÁC ĐỊA ĐIỂM (ở cùng 1 thành phố) để bạn phân tích:
    {locations_text_blob}

    Yêu cầu:
    1.  Đọc kỹ MÔ TẢ của từng địa điểm.
    2.  So sánh mô tả đó với SỞ THÍCH của người dùng.
    3.  Cho điểm tương thích (score) từ 0 đến 100 cho MỖI địa điểm. (Ví dụ: 90 điểm, 80 điểm)
    4.  Trả về một danh sách JSON (định dạng: {json.dumps(JSON_OUTPUT_SCHEMA)})
        được sắp xếp (sort) theo 'score' từ cao xuống thấp.
        KHÔNG GIẢI THÍCH GÌ THÊM.
    """

    print(f"--- Đang gửi prompt (GĐ 4.3: No Reasoning) đến AI. Phân tích {len(destinations)} địa điểm... ---")

    try:
        response = await model.generate_content_async(prompt)
        raw_json_text = response.text
        print(f"--- AI đã trả về (JSON): {raw_json_text} ---")

        ranked_list_json = json.loads(raw_json_text)
        
        # Chuyển đổi dicts thành Pydantic models (RecommendationOutput mới)
        ranked_list_models = [RecommendationOutput(**item) for item in ranked_list_json]
        return ranked_list_models
            
    except Exception as e:
        print(f"LỖI khi gọi AI (Ranking) hoặc xử lý JSON: {e}")
        return []