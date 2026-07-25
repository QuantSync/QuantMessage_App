"""
Test Groq directly since it has its own separate rate limit (not OpenRouter's 50/day cap).
"""
import os
import asyncio
import httpx
from dotenv import load_dotenv
load_dotenv()

async def test():
    groq_key = os.environ.get("GROQ_API_KEY", "")
    headers = {
        "Authorization": f"Bearer {groq_key}",
        "Content-Type": "application/json",
    }

    models = [
        "llama-3.1-8b-instant",
        "llama3-8b-8192",
        "gemma2-9b-it",
    ]

    async with httpx.AsyncClient(timeout=15.0) as client:
        for model in models:
            print(f"\nTesting Groq {model}...")
            try:
                resp = await client.post(
                    "https://api.groq.com/openai/v1/chat/completions",
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
