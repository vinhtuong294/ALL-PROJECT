#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys, json, urllib.request, urllib.error
sys.stdout.reconfigure(encoding='utf-8')

BASE = 'http://localhost:8000'

candidates = [
    {'login_name': 'quanlycho', 'password': '123456'},
    {'login_name': '905123734', 'password': '123456'},
    {'login_name': 'hieuquanly', 'password': '123456'},
    {'login_name': '777352787', 'password': '123456'},
]

TOKEN = None
for creds in candidates:
    try:
        data = json.dumps(creds).encode()
        req = urllib.request.Request(
            BASE + '/api/auth/login', data=data,
            headers={'Content-Type': 'application/json'}
        )
        resp = urllib.request.urlopen(req, timeout=8)
        body = json.loads(resp.read().decode('utf-8'))
        TOKEN = body.get('access_token', '')
        print(f"LOGIN OK: login_name={creds['login_name']}, role={body.get('role')}")
        print(f"TOKEN={TOKEN[:50]}...")
        break
    except urllib.error.HTTPError as e:
        err = e.read().decode('utf-8')
        print(f"FAIL {creds['login_name']}: {e.code} => {err}")
    except Exception as ex:
        print(f"ERR {creds['login_name']}: {ex}")

if not TOKEN:
    print("CANNOT LOGIN - Check passwords in DB")
