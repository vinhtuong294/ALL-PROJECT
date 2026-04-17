import requests

# Try login with test account
res = requests.post('http://localhost:8000/api/auth/login', json={'ten_dang_nhap': 'shipper01', 'mat_khau': 'shipper01'})
print(res.json())

if 'token' in res.json():
    headers = {'Authorization': 'Bearer ' + res.json()['token']}
    res2 = requests.get('http://localhost:8000/api/shipper/orders/available', headers=headers)
    print("Available:", res2.status_code)
    try:
        print(res2.json())
    except:
        print(res2.text)

    res3 = requests.get('http://localhost:8000/api/shipper/orders/my', headers=headers)
    print("My:", res3.status_code)
    try:
        print(res3.json())
    except:
        print(res3.text)
