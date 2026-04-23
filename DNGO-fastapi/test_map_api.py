import requests

BASE_URL = "http://207.180.233.84:8000"

def test_api():
    print("Testing Login with Manager Account...")
    res = requests.post(f"{BASE_URL}/api/auth/login", json={
        "ten_dang_nhap": "hieuquanly",
        "mat_khau": "Trinh123456@"
    })
    
    if res.status_code != 200:
        print("Login failed:", res.text)
        return
        
    json_data = res.json()
    token = json_data.get("token")
    if not token and "data" in json_data:
        token = json_data["data"].get("token")
    
    if not token:
        print("Could not find token in response:", json_data)
        return
        
    print("Manager Token:", token[:20], "...")
    
    print("\nFetching Map Stalls API...")
    headers = {"Authorization": f"Bearer {token}"}
    map_res = requests.get(f"{BASE_URL}/api/quan-ly-cho/stalls/map", headers=headers)
    
    if map_res.status_code == 200:
        data = map_res.json().get("data", [])
        print(f"Success! Map Stalls API returned {len(data)} items.")
        if len(data) > 0:
            sample = data[0]
            print("Sample data mapping:")
            print(f" - ID: {sample.get('stall_id')}")
            print(f" - Name: {sample.get('ten_gian_hang')}")
            print(f" - X_COL: {sample.get('x_col')}")
            print(f" - Y_ROW: {sample.get('y_row')}")
            print(f" - Type: {sample.get('loai_hang')}")
            
            # verify coordinates
            has_valid_coords = any(item.get('x_col') > 0 or item.get('y_row') > 0 for item in data)
            if has_valid_coords:
                print("Coordinates validation: PASSED (Data is spread out)")
            else:
                print("Coordinates validation: FAILED (All zeros or null)")
    else:
        print("Failed to fetch map stalls:", map_res.text)

if __name__ == "__main__":
    test_api()
