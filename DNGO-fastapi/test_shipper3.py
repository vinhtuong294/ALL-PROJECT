import requests
import sys
import json
sys.stdout.reconfigure(encoding='utf-8')
print("Trying login...")
res = requests.post('http://localhost:8000/api/auth/login', json={'ten_dang_nhap': '389562426', 'mat_khau': 'Abcxyz12!'})
data = res.json()
print("Login:", data)
if 'token' in data:
    headers = {'Authorization': 'Bearer ' + data['token']}
    res2 = requests.get('http://localhost:8000/api/shipper/orders/available', headers=headers)
    print("Available Status:", res2.status_code)
    try:
        j = res2.json()
        print("Items received:", len(j.get('items', [])))
        if j.get('items'):
            print(json.dumps(j['items'][0], ensure_ascii=False, indent=2))
    except Exception as e:
        print("Decode Error:", e)
        print("Raw text:", res2.text[:500])
