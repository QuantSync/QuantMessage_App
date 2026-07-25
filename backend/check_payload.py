import os
import requests
import json
from dotenv import load_dotenv
load_dotenv()

key = os.environ.get("OPENROUTER_API_KEY", "")

models = [
    "cohere/north-mini-code:free",
    "nvidia/nemotron-3.5-content-safety:free",
    "inclusionai/ling-3.0-flash:free",
    "nvidia/nemotron-3-ultra-550b-a55b:free"
]

for model in models:
    url = "https://openrouter.ai/api/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {key}",
        "Content-Type": "application/json"
    }
    payload = {
        "model": model,
        "messages": [{"role": "user", "content": "hi"}],
        "max_tokens": 20
    }
    resp = requests.post(url, json=payload, headers=headers, timeout=15)
    print(f"\n--- Response for {model} ---")
    print(json.dumps(resp.json(), indent=2))
