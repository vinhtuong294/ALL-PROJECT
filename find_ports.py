import urllib.request, threading
urls_to_test = [f"http://localhost:{p}" for p in [59087, 59012, 58998, 58937, 58842, 59090, 59089, 59007, 59006, 59003, 58931, 58899, 58898, 58839]]

def check(url):
    try:
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=2) as r:
            body = r.read().decode('utf-8')
            if 'flutter' in body.lower() or 'dart' in body.lower():
                titles = [line for line in body.splitlines() if "<title>" in line]
                print(f"{url:25s} -> Found Flutter! Title: {titles}")
    except Exception as e:
        pass

threads = [threading.Thread(target=check, args=(u,)) for u in urls_to_test]
for t in threads: t.start()
for t in threads: t.join()
