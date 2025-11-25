import google.generativeai as genai
import json
from typing import List, Dict, Any, Optional
from recommend_models import RecommendationOutput
from db_tables import Destination, Profiles 
from config import settings 

# ====================================================================
# CẤU HÌNH GEMINI (Sử dụng model Flash cho tốc độ và chi phí)
# ====================================================================
try:
    genai.configure(api_key=settings.GEMINI_API_KEY)
    
    # Cấu hình JSON Mode (cho các hàm trả về dữ liệu)
    generation_config_json = genai.GenerationConfig(
        response_mime_type="application/json",
        temperature=0.3 # Giữ thấp để đảm bảo cấu trúc JSON chính xác
    )
    
    # Cấu hình Text Mode (cho Chat Bot)
    generation_config_text = genai.GenerationConfig(
        response_mime_type="text/plain",
        temperature=0.8 # Tăng cao để chat tự nhiên, sáng tạo hơn
    )

    # Model chính (Dùng Flash để cân bằng giữa thông minh và tốc độ)
    model_json = genai.GenerativeModel(
        'gemini-2.5-flash-preview-09-2025', 
        generation_config=generation_config_json
    )
    model_text = genai.GenerativeModel(
        'gemini-2.5-flash-preview-09-2025', 
        generation_config=generation_config_text
    )
    
except Exception as e:
    print(f"LỖI KHỞI TẠO AI: {e}")
    model_json = None
    model_text = None

# ====================================================================
# 1. TÍNH NĂNG: GỢI Ý ĐỊA ĐIỂM (Prompt Nâng cao)
# ====================================================================
async def rank_destinations_by_ai(
    user_interests: List[str],
    destinations: List[Destination]
) -> List[RecommendationOutput]:
    
    if not model_json: return []

    locations_text_list = []
    for dest in destinations:
        locations_text_list.append(f"ID: {dest.id} | Tên: {dest.location_name} | Mô tả: {dest.description}")
    
    locations_blob = "\n".join(locations_text_list)
    
    # Prompt Kỹ càng
    prompt = f"""
    Bạn là một hướng dẫn viên du lịch địa phương với 20 năm kinh nghiệm, cực kỳ am hiểu về văn hóa và địa lý Việt Nam.
    Nhiệm vụ của bạn là xếp hạng các địa điểm du lịch dựa trên sự phù hợp sâu sắc với sở thích của người dùng.

    === HỒ SƠ NGƯỜI DÙNG ===
    - Sở thích chính: {json.dumps(user_interests, ensure_ascii=False)}
    
    === DANH SÁCH ĐỊA ĐIỂM ỨNG VIÊN ===
    {locations_blob}

    === TIÊU CHÍ CHẤM ĐIỂM (0-100) ===
    Hãy phân tích kỹ lưỡng "Mô tả" của từng địa điểm và so sánh với "Sở thích":
    1. **Sự phù hợp trực tiếp (40%):** Địa điểm có đúng loại hình user thích không? (VD: Thích 'biển' -> Bãi biển = 100đ).
    2. **Sự phù hợp gián tiếp (30%):** Địa điểm có mang lại *cảm giác* (vibe) mà user thích không? (VD: Thích 'yên tĩnh' -> Chùa chiền = 90đ, Quán Bar = 10đ).
    3. **Độ hấp dẫn nội tại (30%):** Dựa trên mô tả, địa điểm này có đặc sắc, nổi tiếng không?

    === YÊU CẦU OUTPUT ===
    Trả về một JSON Array, chứa các object gồm:
    - "location_name": (String) Tên địa điểm y hệt đầu vào.
    - "score": (Integer) Điểm số từ 0 đến 100.

    KHÔNG giải thích gì thêm. Chỉ trả về JSON.
    """

    try:
        response = await model_json.generate_content_async(prompt)
        data = json.loads(response.text)
        results = []
        for item in data:
            if "location_name" in item and "score" in item:
                results.append(RecommendationOutput(
                    location_name=item["location_name"],
                    score=int(item["score"])
                ))
        return results
    except Exception as e:
        print(f"Lỗi AI Rank Destinations: {e}")
        return []

# ====================================================================
# 2. TÍNH NĂNG: CHAT BOT THÔNG MINH (Prompt Persona)
# ====================================================================
async def chat_with_gemini_text(
    user_message: str,
    user_profile: Any
) -> str:
    
    if not model_text: return "Xin lỗi, hệ thống AI đang bảo trì."

    name = user_profile.fullname or "Bạn"
    interests = ", ".join(user_profile.interests or [])
    city = user_profile.preferred_city or "Chưa rõ"
    
    system_prompt = f"""
    [VAI TRÒ]
    Bạn là "Travel Buddy", một người bạn đồng hành ảo cực kỳ thân thiện, hài hước và thông thái. Bạn không phải là một cái máy trả lời khô khan.
    
    [THÔNG TIN NGƯỜI DÙNG]
    - Tên: {name}
    - Sở thích: {interests}
    - Đang quan tâm thành phố: {city}

    [HƯỚNG DẪN TRẢ LỜI]
    1. **Giọng điệu:** Vui vẻ, dùng emoji phù hợp 🌴✈️, xưng hô "mình" và gọi user bằng tên (nếu có).
    2. **Cá nhân hóa:** Luôn cố gắng liên hệ câu trả lời với sở thích hoặc thành phố mà user quan tâm.
    3. **Ngắn gọn:** Trả lời súc tích (dưới 150 từ), chia đoạn rõ ràng dễ đọc.
    4. **Gợi mở:** Kết thúc câu trả lời bằng một câu hỏi nhỏ để duy trì cuộc trò chuyện.
    5. **Phạm vi:** Nếu user hỏi ngoài chủ đề du lịch/ăn uống/văn hóa, hãy khéo léo lái câu chuyện về du lịch một cách hài hước.
    """
    
    full_prompt = f"{system_prompt}\n\nUser: {user_message}\nTravel Buddy:"

    try:
        response = await model_text.generate_content_async(full_prompt)
        return response.text
    except Exception as e:
        print(f"Lỗi AI Chat: {e}")
        return "Opps! Mạng hơi lag chút xíu, bạn hỏi lại giúp mình nha! 😅"

# ====================================================================
# 3. TÍNH NĂNG: GỢI Ý NHÓM (Prompt Semantic Matching)
# ====================================================================
async def rank_groups_by_itinerary_ai(
    user_itinerary: Dict[str, str],
    candidate_groups: List[Dict[str, Any]]
) -> Dict[int, float]:
    """
    So sánh ngữ nghĩa sâu (Deep Semantic Matching) giữa Lịch trình User và các Group.
    """
    if not model_json: return {}
    if not candidate_groups or not user_itinerary: return {}

    # 1. Chuẩn bị dữ liệu User
    user_text = "; ".join([f"{k}. {v}" for k, v in user_itinerary.items()])

    # 2. Chuẩn bị dữ liệu Groups
    groups_text = ""
    for g in candidate_groups:
        iti = g.get('itinerary') or {}
        iti_str = "; ".join([f"{k}. {v}" for k, v in iti.items()])
        groups_text += f"- GROUP_ID {g['id']}: {iti_str}\n"

    # 3. Prompt Siêu chi tiết (Few-shot Learning)
    prompt = f"""
    Bạn là một thuật toán ghép đôi du lịch (Travel Matchmaker) cấp cao.
    Nhiệm vụ: So sánh sự tương đồng về **LỊCH TRÌNH** (Itinerary) giữa một USER và danh sách các GROUP ứng viên.

    === DỮ LIỆU ĐẦU VÀO ===
    USER ITINERARY:
    {user_text}

    CANDIDATE GROUPS:
    {groups_text}

    === HƯỚNG DẪN CHẤM ĐIỂM CHI TIẾT (0-100) ===
    Bạn cần chấm điểm dựa trên **Độ tương đồng về Ngữ Nghĩa (Semantic Similarity)**, không phải so sánh chuỗi ký tự.

    **Quy tắc 1: Hiểu Từ Đồng Nghĩa & Khái Niệm**
    - "Hồ Gươm" == "Hồ Hoàn Kiếm" == "Bờ Hồ" -> Trùng khớp hoàn toàn.
    - "Uống cà phê" == "Đi cafe" == "Cafe sáng" -> Trùng khớp hoàn toàn.
    - "Tắm biển" == "Bơi lội" == "Ra biển Mỹ Khê" -> Trùng khớp hoàn toàn.
    
    **Quy tắc 2: Phân cấp Điểm số**
    - **90-100 điểm (Xuất sắc):** Lịch trình gần như giống hệt nhau về các địa điểm cụ thể. (Ví dụ: Cả 2 đều đi Bà Nà Hills, Cầu Rồng, Hội An).
    - **70-89 điểm (Tốt):** Có nhiều hoạt động giống nhau nhưng khác địa điểm cụ thể, hoặc trùng khoảng 50-70% địa điểm. (Ví dụ: Cùng đi tắm biển và ăn hải sản, nhưng user ăn quán A, group ăn quán B).
    - **40-69 điểm (Trung bình):** Có chung "vibe" (phong cách) du lịch (ví dụ: cùng thích nghỉ dưỡng, hoặc cùng thích khám phá), nhưng địa điểm cụ thể ít trùng.
    - **0-39 điểm (Kém):** Hoàn toàn trái ngược. (Ví dụ: User muốn đi leo núi, Group lại đi shopping trong mall).

    **Quy tắc 3: Bỏ qua nhiễu**
    - Bỏ qua thứ tự ngày (Ngày 1 so với Ngày 2 vẫn tính là trùng).
    - Bỏ qua lỗi chính tả nhỏ.
    - Bỏ qua các từ nối (đi, đến, tại...).

    === ĐỊNH DẠNG OUTPUT ===
    Trả về duy nhất một JSON Array chứa các object:
    [
      {{"group_id": 123, "score": 85}},
      {{"group_id": 456, "score": 40}}
    ]
    """

    print(f"--- AI (GĐ 23) đang phân tích sâu cho {len(candidate_groups)} nhóm... ---")

    try:
        response = await model_json.generate_content_async(prompt)
        result_json = json.loads(response.text)
        
        # Map {id: score}
        score_map = {}
        for item in result_json:
            gid = item.get("group_id")
            sc = item.get("score", 0)
            if gid is not None:
                score_map[gid] = float(sc)
        
        return score_map

    except Exception as e:
        print(f"Lỗi AI Group Scoring: {e}")
        return {}