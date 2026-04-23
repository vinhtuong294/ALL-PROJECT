from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.models.models import Stall
from dotenv import load_dotenv
import os

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
print(f"Connecting to {DATABASE_URL} ...")

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def setup_map_data():
    db = SessionLocal()
    stalls = db.query(Stall).all()
    print(f"Found {len(stalls)} stalls in REMOTE database.")
    
    zones = {
        'RC': {'x_range': (0, 9), 'y_range': (0, 4), 'current_x': 0, 'current_y': 0},
        'TH': {'x_range': (10, 19), 'y_range': (0, 4), 'current_x': 10, 'current_y': 0},
        'HS': {'x_range': (0, 7), 'y_range': (5, 9), 'current_x': 0, 'current_y': 5},
        'KH': {'x_range': (8, 19), 'y_range': (5, 9), 'current_x': 8, 'current_y': 5},
        'GV': {'x_range': (0, 9), 'y_range': (10, 14), 'current_x': 0, 'current_y': 10},
        'OTHER': {'x_range': (10, 19), 'y_range': (10, 14), 'current_x': 10, 'current_y': 10}
    }
    
    def get_next_coord(loc):
        # We handle cases where stall_location might be None or unexpected
        zone_key = loc if loc in zones else 'OTHER'
        zone = zones[zone_key]
        cx, cy = zone['current_x'], zone['current_y']
        
        # Advance for next time
        zone['current_x'] += 1
        if zone['current_x'] > zone['x_range'][1]:
            zone['current_x'] = zone['x_range'][0]
            zone['current_y'] += 1
            if zone['current_y'] > zone['y_range'][1]:
                zone['current_y'] = zone['y_range'][0]
                
        return cx, cy

    updated_count = 0
    for stall in stalls:
        # User requirement: "DỮ LIỆU ĐƯỢC SỬA X_COL, Y_COL CỦA SELLER KHÔNG SỬA GÌ NỮA"
        cx, cy = get_next_coord(stall.stall_location)
        stall.grid_col = cx
        stall.grid_row = cy
        updated_count += 1
        
    db.commit()
    print(f"Successfully updated {updated_count} stalls on the REMOTE database.")
    db.close()

if __name__ == "__main__":
    setup_map_data()
