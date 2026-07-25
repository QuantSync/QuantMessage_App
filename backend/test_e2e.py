import os
import asyncio
import sys
# Fix Windows encoding for Unicode output
if sys.platform == "win32":
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

from dotenv import load_dotenv
from agent.graph import run_agent_graph
load_dotenv()

async def test():
    print("=== Testing QuantCore pipeline end-to-end ===")
    result = await run_agent_graph(
        query="hi",
        model_id="quantcore-native",
        mode="drive",
        conversation_id="test-123",
        user_id="guest_user",
        is_guest=True
    )
    print("\n=== RESULT ===")
    output = result.get("output", "")
    if output and output != "[No response content returned by model]":
        print("SUCCESS! Got response:", output[:300])
    else:
        print("FAILED - empty output:", repr(output))
    
    print("\nSteps:", result.get("steps", []))

asyncio.run(test())
