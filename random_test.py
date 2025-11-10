from datetime import date
import random

# ========== CLASS DEFINITIONS ==========

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
            score = len(shared_tags) / max(len(place_tags), 1)
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

# ========== DATA ==========

# Destination + places database
destinations = ["Đà Lạt","Phú Quốc","Sa Pa","Hà Nội","Hồ Chí Minh","Nha Trang","Huế","Đà Nẵng"]
places_db = {}

place_tags_pool = ["nature","hiking","photography","coffee","camping","beach","relax","adventure","foodie","culture","shopping","sun","family","romantic"]

for dest in destinations:
    places = []
    for i in range(5):  # 5 places per destination
        tags = random.sample(place_tags_pool, k=3)
        places.append(Place(f"{dest} Place {i+1}", tags))
    places_db[dest] = places

# Create 20 groups with random hosts
groups = []
for i in range(20):
    dest = random.choice(destinations)
    start_date = date(2025, 12, random.randint(18,28))
    end_date = date(2025, 12, random.randint(29,31))
    tp_places = random.sample(places_db[dest], k=3)
    tp = TravelPlan(dest, start_date, end_date, tp_places)
    host_tags = random.sample(place_tags_pool, k=4)
    host = User(f"Host{i+1}", host_tags, tp)
    members = []
    capacity = random.randint(3,6)
    groups.append(TravelGroup(f"Group{i+1}", host, members, capacity))

# User
user_tp = TravelPlan(
    destination="Đà Lạt",
    start_date=date(2025,12,20),
    end_date=date(2025,12,25),
    places=random.sample(places_db["Đà Lạt"], k=3)
)
user = User("An", ["nature","photography","hiking","coffee","relax"], user_tp)

# ========== RUN MATCHING ENGINE ==========

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
