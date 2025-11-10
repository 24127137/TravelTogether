from datetime import date

# ========== DATA CLASSES ==========

class Place:
    def __init__(self, name, tags):
        self.name = name
        self.tags = tags

class TravelPlan:
    def __init__(self, destination, start_date, end_date, places=None):
        self.destination = destination
        self.start_date = start_date
        self.end_date = end_date
        self.places = places or []

class User:
    def __init__(self, name, tags, travel_plan=None):
        self.name = name
        self.tags = tags
        self.travel_plan = travel_plan

class TravelGroup:
    def __init__(self, group_name, host, members, capacity):
        self.group_name = group_name
        self.host = host
        self.members = members
        self.capacity = capacity

    def is_full(self):
        return len(self.members) >= self.capacity

# ========== MATCHING ENGINE ==========

class MatchingEngine:
    def __init__(self, all_groups, places_db):
        self.all_groups = all_groups
        self.places_db = places_db

    def suggest_destinations(self, user):
        scored = []
        for dest, places in self.places_db.items():
            place_tags = set()
            for p in places:
                place_tags.update(p.tags)
            shared_tags = set(user.tags) & place_tags
            score = len(shared_tags) / max(len(place_tags),1)
            scored.append((dest, round(score*100,1)))
        scored.sort(key=lambda x: x[1], reverse=True)
        return scored

    def suggest_places(self, user, destination, top_k=5):
        if destination not in self.places_db:
            return []
        scored = []
        for p in self.places_db[destination]:
            shared_tags = set(user.tags) & set(p.tags)
            score = len(shared_tags) / max(len(p.tags),1)
            scored.append((p.name, round(score*100,1)))
        scored.sort(key=lambda x: x[1], reverse=True)
        return scored[:top_k]

    def suggest_groups(self, user):
        if not user.travel_plan:
            return []
        suggestions = []
        u_tp = user.travel_plan
        for group in self.all_groups:
            g_tp = group.host.travel_plan
            if (g_tp.destination.lower() == u_tp.destination.lower() 
                and g_tp.start_date == u_tp.start_date
                and g_tp.end_date == u_tp.end_date
                and not group.is_full()):
                user_places = set([p.name for p in u_tp.places])
                host_places = set([p.name for p in g_tp.places])
                shared_places = user_places & host_places
                place_score = len(shared_places) / max(len(host_places),1)
                shared_tags = set(user.tags) & set(group.host.tags)
                tag_score = len(shared_tags) / max(len(group.host.tags),1)
                total_score = (0.7*place_score + 0.3*tag_score)*100
                suggestions.append((group, round(total_score,2)))
        suggestions.sort(key=lambda x: x[1], reverse=True)
        return suggestions

# ================== REALISTIC SAMPLE DATA ==================

# --- Places database ---
places_db = {
    "Đà Lạt": [
        Place("Thung lũng Tình Yêu", ["nature","romantic","photography"]),
        Place("Hồ Xuân Hương", ["nature","photography","relax"]),
        Place("Quảng trường Lâm Viên", ["photography","food","fun"]),
        Place("Langbiang", ["hiking","nature","adventure"]),
        Place("Thác Datanla", ["adventure","nature","fun"])
    ],
    "Phú Quốc": [
        Place("Bãi Sao", ["beach","sun","relax"]),
        Place("Vinpearl Safari", ["animals","family","fun"]),
        Place("Suối Tranh", ["nature","hiking","photo"]),
        Place("Dinh Cậu", ["culture","photography","sunset"]),
        Place("Hòn Thơm", ["beach","relax","adventure"])
    ],
    "Sa Pa": [
        Place("Fansipan", ["hiking","nature","adventure"]),
        Place("Bản Cát Cát", ["culture","photography","nature"]),
        Place("Thác Bạc", ["nature","relax","photography"]),
        Place("Núi Hàm Rồng", ["nature","adventure","view"]),
        Place("Chợ Sa Pa", ["culture","food","shopping"])
    ]
}

# --- User ---
user_tp = TravelPlan(
    destination="Đà Lạt",
    start_date=date(2025,12,20),
    end_date=date(2025,12,25),
    places=[places_db["Đà Lạt"][0], places_db["Đà Lạt"][1], places_db["Đà Lạt"][3]]
)
user = User("An", ["nature","photography","hiking","coffee"], user_tp)

# --- Groups ---
g1_tp = TravelPlan("Đà Lạt", date(2025,12,20), date(2025,12,25),
                   [places_db["Đà Lạt"][0], places_db["Đà Lạt"][3], places_db["Đà Lạt"][4]])
g1_host = User("Minh", ["nature","hiking","adventure","foodie"], g1_tp)
group1 = TravelGroup("Nature Explorers", g1_host, members=[], capacity=5)

g2_tp = TravelPlan("Đà Lạt", date(2025,12,20), date(2025,12,25),
                   [places_db["Đà Lạt"][1], places_db["Đà Lạt"][2], places_db["Đà Lạt"][4]])
g2_host = User("Linh", ["photography","nature","coffee","foodie"], g2_tp)
group2 = TravelGroup("Dalat Dreamers", g2_host, members=[User("Bao", [], None)], capacity=4)

g3_tp = TravelPlan("Phú Quốc", date(2025,12,22), date(2025,12,28),
                   [places_db["Phú Quốc"][0], places_db["Phú Quốc"][2], places_db["Phú Quốc"][3]])
g3_host = User("Trang", ["beach","relax","sun"], g3_tp)
group3 = TravelGroup("Beach Lovers", g3_host, members=[], capacity=5)

g4_tp = TravelPlan("Sa Pa", date(2025,12,20), date(2025,12,25),
                   [places_db["Sa Pa"][0], places_db["Sa Pa"][1], places_db["Sa Pa"][4]])
g4_host = User("Tuan", ["hiking","nature","culture"], g4_tp)
group4 = TravelGroup("Mountain Trekkers", g4_host, members=[], capacity=4)

groups = [group1, group2, group3, group4]

# ================== RUN MATCHING ENGINE ==================

engine = MatchingEngine(groups, places_db)

print("📍 Destination Suggestions:")
for dest, score in engine.suggest_destinations(user):
    print(f"- {dest}: {score}%")

print("\n📌 Place Suggestions in Đà Lạt:")
for place, score in engine.suggest_places(user,"Đà Lạt"):
    print(f"- {place}: {score}%")

print("\n👥 Group Suggestions:")
for g, score in engine.suggest_groups(user):
    print(f"- {g.group_name} | Host: {g.host.name} | Dest: {g.host.travel_plan.destination} | Compatibility: {score}%")
