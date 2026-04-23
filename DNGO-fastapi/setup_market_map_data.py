from app.database import SessionLocal
from app.models.models import Stall

def setup_map_data():
    db = SessionLocal()
    stalls = db.query(Stall).all()
    
    # Define bounding boxes logic: (start_x, end_x, start_y, end_y)
    # Market size is assumed to be 20x15 (X: 1-20, Y: 1-15).
    # NOTE: Our zero-indexed or 1-indexed? The frontend code expects 
    # xCol from 0 to 19, and yRow from 0 to 14. 
    # Because position = (xCol + 1) * cellWidth. We'll use 0-indexed for DB.
    zones = {
        'RC': {'x_range': (0, 9), 'y_range': (0, 4), 'current_x': 0, 'current_y': 0},
        'TH': {'x_range': (10, 19), 'y_range': (0, 4), 'current_x': 10, 'current_y': 0},
        'HS': {'x_range': (0, 7), 'y_range': (5, 9), 'current_x': 0, 'current_y': 5},
        'KH': {'x_range': (8, 19), 'y_range': (5, 9), 'current_x': 8, 'current_y': 5},
        'GV': {'x_range': (0, 9), 'y_range': (10, 14), 'current_x': 0, 'current_y': 10},
        'OTHER': {'x_range': (10, 19), 'y_range': (10, 14), 'current_x': 10, 'current_y': 10}
    }
    
    def get_next_coord(loc):
        zone = zones.get(loc, zones['OTHER'])
        cx, cy = zone['current_x'], zone['current_y']
        
        # Advance for next time
        zone['current_x'] += 1
        if zone['current_x'] > zone['x_range'][1]:
            zone['current_x'] = zone['x_range'][0]
            zone['current_y'] += 1
            if zone['current_y'] > zone['y_range'][1]:
                zone['current_y'] = zone['y_range'][0] # Wrap around if full (safeguard)
                
        return cx, cy

    for stall in stalls:
        loc = stall.stall_location
        cx, cy = get_next_coord(loc)
        stall.grid_col = cx
        stall.grid_row = cy
        
    db.commit()
    print("Market Map data seeded successfully!")
    db.close()

if __name__ == "__main__":
    setup_map_data()
