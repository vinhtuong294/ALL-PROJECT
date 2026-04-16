import json

with open("scratch/openapi.json", "r", encoding="utf-8") as f:
    schema = json.load(f)

for path, obj in schema["paths"].items():
    if "checkout" in path.lower() or "orders" in path.lower():
        print("Path:", path)
        print("Method:", list(obj.keys())[0])
        req_body = obj[list(obj.keys())[0]].get("requestBody")
        if req_body:
            content = req_body.get("content", {}).get("application/json", {}).get("schema", {})
            if "$ref" in content:
                ref = content["$ref"].split("/")[-1]
                print(json.dumps(schema["components"]["schemas"].get(ref, {}), indent=2, ensure_ascii=False))
            print("SelectedItem:", json.dumps(schema["components"]["schemas"].get("SelectedItem", {}), indent=2))
        print("---")

