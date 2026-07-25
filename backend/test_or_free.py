import os
import requests
from dotenv import load_dotenv
load_dotenv()

key = os.environ.get("OPENROUTER_API_KEY", "")

models = [
    "cohere/north-mini-code:free",
    "nvidia/nemotron-3.5-content-safety:free",
    "inclusionai/ling-3.0-flash:free",
    "nvidia/nemotron-3-ultra-550b-a55b:free"
]

print("Testing OpenRouter Free Models...")
for model in models:
    url = "https://openrouter.ai/api/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {key}",
        "Content-Type": "application/json"
    }
    payload = {
        "model": model,
        "messages": [{"role": "user", "content": "ping"}],
        "max_tokens": 10
    }
    try:
        print(f"Testing {model}...")
        resp = requests.post(url, json=payload, headers=headers, timeout=15)
        if resp.status_code == 200:
            print(f" - {model}: [OK] Response: {resp.json()['choices'][0]['message']['content']}")
        else:
            print(f" - {model}: [FAILED] Status {resp.status_code} - {resp.text[:150]}")
    except Exception as e:
        print(f" - {model}: [EXCEPTION] {e}")
