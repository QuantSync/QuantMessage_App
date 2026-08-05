import requests
import json

base_url = "https://web-production-aa98e.up.railway.app"

try:
    print("Testing GET /")
    res = requests.get(base_url, timeout=5)
    print(f"Status: {res.status_code}")
    print(res.text)
except Exception as e:
    print(f"GET / failed: {e}")

try:
    print("\nTesting POST /api/v1/chat")
    payload = {
        "message": "test",
        "model_id": "groq/llama-3.1-8b-instant",
        "conversation_id": "test",
        "user_id": "guest_user",
        "mode": "drive"
    }
    res = requests.post(f"{base_url}/api/v1/chat", json=payload, timeout=5)
    print(f"Status: {res.status_code}")
    print(res.text)
except Exception as e:
    print(f"POST /api/v1/chat failed: {e}")
