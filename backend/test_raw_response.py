"""
Check raw JSON to see exactly what OpenRouter returns for these models.
"""
import os
import asyncio
import httpx
import json
from dotenv import load_dotenv
load_dotenv()

async def test():
    key = os.environ.get("OPENROUTER_API_KEY", "")
    headers = {
        "Authorization": f"Bearer {key}",
        "Content-Type": "application/json",
    }
    models = [
        "nvidia/nemotron-3-ultra-550b-a55b:free",
        "cohere/north-mini-code:free",
        "inclusionai/ling-3.0-flash:free",
    ]
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        for model in models:
            print(f"\n{'='*60}")
            print(f"Testing {model} ...")
            try:
                resp = await client.post(
                    "https://openrouter.ai/api/v1/chat/completions",
                    headers=headers,
                    json={
                        "model": model,
                        "messages": [{"role": "user", "content": "say hi"}],
                        "max_tokens": 50,
                    }
                )
                print(f"  Status: {resp.status_code}")
                raw = resp.text
                print(f"  Raw response (first 600 chars):\n{raw[:600]}")
            except httpx.TimeoutException:
                print(f"  TIMED OUT after 30s!")
            except Exception as e:
                print(f"  ERROR: {e}")

asyncio.run(test())
