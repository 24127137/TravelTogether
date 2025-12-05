from sqlmodel import Session, select
from database import engine
from db_tables import Profiles, UserTripPlans
from datetime import datetime

def migrate_profiles_to_plans():
    print("--- BẮT ĐẦU DI TRÚ DỮ LIỆU TỪ PROFILES SANG TRIP PLANS ---")
    
    with Session(engine) as session:
        # 1. Lấy tất cả profile có dữ liệu du lịch (City & Dates không null)
        statement = select(Profiles).where(
            Profiles.preferred_city != None,
            Profiles.travel_dates != None
        )
        profiles = session.exec(statement).all()
        
        count = 0
        skipped = 0
        
        for p in profiles:
            # 2. Kiểm tra xem user này đã có dữ liệu trong bảng mới chưa
            # (Để tránh tạo trùng lặp nếu bạn lỡ chạy script này 2 lần)
            existing_plan = session.exec(
                select(UserTripPlans).where(UserTripPlans.user_id == p.auth_user_id)
            ).first()
            
            if not existing_plan:
                print(f"[Create] Đang tạo plan cho User: {p.email} | Đi: {p.preferred_city}")
                
                # 3. Tạo bản ghi mới trong UserTripPlans
                new_plan = UserTripPlans(
                    user_id=p.auth_user_id,
                    preferred_city=p.preferred_city,
                    travel_dates=p.travel_dates,
                    itinerary=p.itinerary,
                    created_at=datetime.now(),
                    updated_at=datetime.now()
                )
                session.add(new_plan)
                count += 1
            else:
                # print(f"[Skip] User {p.email} đã có dữ liệu.")
                skipped += 1
        
        # 4. Lưu thay đổi vào DB
        session.commit()
        print("-------------------------------------------------------")
        print(f"HOÀN TẤT!")
        print(f"- Đã tạo mới: {count} kế hoạch.")
        print(f"- Đã bỏ qua (đã có): {skipped} kế hoạch.")

if __name__ == "__main__":
    # Chạy hàm migration
    try:
        migrate_profiles_to_plans()
    except Exception as e:
        print(f"LỖI: {e}")