"""
Quick test: call nemotron-3-ultra directly with a 30s timeout and print raw JSON.
This tells us if the model hangs or returns quickly.
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
    ]
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        for model in models:
            print(f"\nTesting {model} ...")
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
                data = resp.json()
                msg = data.get("choices", [{}])[0].get("message", {})
                content = msg.get("content") or ""
                reasoning = msg.get("reasoning") or ""
                details = msg.get("reasoning_details") or []
                detail_text = " | ".join(d.get("text","")[:50] for d in details)
                print(f"  content: {repr(content[:100])}")
                print(f"  reasoning: {repr(reasoning[:100])}")
                print(f"  reasoning_details: {repr(detail_text[:100])}")
            except httpx.TimeoutException:
                print(f"  TIMED OUT after 30s!")
            except Exception as e:
                print(f"  ERROR: {e}")

asyncio.run(test())
