import requests
import sys
sys.stdout.reconfigure(encoding='utf-8')
try:
    print("Trying login...")
    # Thử shipper01/shipper01 hoặc shipper/shipper123
    res = requests.post('http://localhost:8000/api/auth/login', json={'ten_dang_nhap': 'shipper', 'mat_khau': 'shipper123'}, timeout=5)
    
    data = res.json()
    if 'token' not in data:
        print("Login failed format, trying another account...")
        res = requests.post('http://localhost:8000/api/auth/login', json={'ten_dang_nhap': 'shipper01', 'mat_khau': 'shipper123'}, timeout=5)
        data = res.json()
        
    print(data)
    
    if 'token' in data:
        headers = {'Authorization': 'Bearer ' + data['token']}
        print("Trying get available orders...")
        res2 = requests.get('http://localhost:8000/api/shipper/orders/available', headers=headers, timeout=5)
        print("Available:", res2.status_code)
        import json
        print(json.dumps(res2.json(), ensure_ascii=False, indent=2))
        
except Exception as e:
    print("Error:", e)
