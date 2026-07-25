"""
Test only gpt-4o-mini (the paid fallback for QuantCore when free models are rate-limited).
"""
import os
import asyncio
import httpx
from dotenv import load_dotenv
load_dotenv()

async def test():
    key = os.environ.get("OPENROUTER_API_KEY", "")
    headers = {
        "Authorization": f"Bearer {key}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://quantmessage.app",
    }

    models = [
        "openai/gpt-4o-mini",           # paid but cheap
        "meta-llama/llama-3.1-8b-instruct:free",  # another free tier
        "google/gemma-3-4b-it:free",    # another free option
    ]

    async with httpx.AsyncClient(timeout=30.0) as client:
        for model in models:
            print(f"\nTesting {model}...")
            try:
                resp = await client.post(
                    "https://openrouter.ai/api/v1/chat/completions",
                    headers=headers,
                    json={
                        "model": model,
                        "messages": [{"role": "user", "content": "say hi in one sentence"}],
                        "max_tokens": 30,
                    }
                )
                print(f"  Status: {resp.status_code}")
                data = resp.json()
                if data.get("error"):
                    print(f"  Error: {data['error'].get('message','')[:120]}")
                else:
                    msg = data.get("choices",[{}])[0].get("message",{})
                    print(f"  Content: {repr(msg.get('content','')[:100])}")
            except Exception as e:
                print(f"  Exception: {e}")

asyncio.run(test())
