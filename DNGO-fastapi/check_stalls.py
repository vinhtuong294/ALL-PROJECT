from app.database import SessionLocal
from app.models.models import Stall

def main():
    db = SessionLocal()
    stalls = db.query(Stall).all()
    categories = {}
    
    for stall in stalls:
        loc = stall.stall_location
        if loc not in categories:
            categories[loc] = 0
        categories[loc] += 1
        
    print(f"Total Stalls: {len(stalls)}")
    print("Categories/Locations found:")
    for loc, count in categories.items():
        print(f" - {loc}: {count} stalls")
    db.close()

if __name__ == "__main__":
    main()
