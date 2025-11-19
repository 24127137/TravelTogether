from pydantic import BaseModel

# ====================================================================
# Model cho Output của Gợi ý AI
# ====================================================================
class RecommendationOutput(BaseModel):
    """
    (Model đã refactor GĐ 8.1)
    Dữ liệu (JSON) mà AI sẽ trả về, và cũng là output của API
    """
    location_name: str
    score: int
    
    class Config:
        json_schema_extra = {
            "example": {
                "location_name": "Biển Mỹ Khê",
                "score": 95
            }
        }