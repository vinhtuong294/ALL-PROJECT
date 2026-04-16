import urllib.request
import json
import os
import urllib.error

login_url = 'http://207.180.233.84:8000/api/auth/login'

# try with password first
data = json.dumps({'ten_dang_nhap': 'shipper_test_auto_002', 'password': 'Trinh123456@'}).encode()
req = urllib.request.Request(login_url, data=data, headers={'Content-Type': 'application/json'})

token = None
try:
    with urllib.request.urlopen(req) as res:
        token = json.loads(res.read().decode())['token']
        print('Login success with password field!')
except Exception as e:
    # try with mat_khau
    data = json.dumps({'ten_dang_nhap': 'shipper_test_auto_002', 'mat_khau': 'Trinh123456@'}).encode()
    req = urllib.request.Request(login_url, data=data, headers={'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(req) as res:
            token = json.loads(res.read().decode())['token']
            print('Login success with mat_khau field!')
    except urllib.error.URLError as e2:
         print(f'Login Failed: {getattr(e2, "read", lambda: b"")().decode()}')
         exit(1)

with open('test_upload.jpg', 'wb') as f:
    f.write(b'dummy image content')

boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW'
body = (
    '--' + boundary + '\r\n' +
    'Content-Disposition: form-data; name="file"; filename="test_upload.jpg"\r\n' +
    'Content-Type: image/jpeg\r\n\r\n' +
    'dummy image content\r\n' +
    '--' + boundary + '--\r\n'
).encode('utf-8')

upload_url = 'http://207.180.233.84:8000/api/upload/single'
req2 = urllib.request.Request(upload_url, data=body, headers={'Content-Type': f'multipart/form-data; boundary={boundary}', 'Authorization': f'Bearer {token}'})
try:
    with urllib.request.urlopen(req2) as res:
        print('Upload Success:')
        print(res.read().decode())
except urllib.error.URLError as e:
    print('Upload Failed:')
    print(getattr(e, 'read', lambda: e.reason.encode())().decode())
