"""
Minimal test: call _call_quantcore_direct directly (the Groq-first path).
This bypasses LangChain entirely and should always return a response.
"""
import os
import asyncio
import sys
if sys.platform == "win32":
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

from dotenv import load_dotenv
load_dotenv()

from agent.graph import _call_quantcore_direct

async def test():
    print("Testing _call_quantcore_direct with 'hi'...")
    result = await _call_quantcore_direct(
        messages=[{"role": "user", "content": "hi"}],
        max_tokens=100,
        temperature=0.3
    )
    print("Result:", result[:300])
    success = bool(result) and not result.startswith("[Error") and not result.startswith("[QuantCore: All")
    print("SUCCESS:", success)

asyncio.run(test())
