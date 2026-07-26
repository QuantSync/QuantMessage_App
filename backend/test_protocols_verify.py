# backend/test_protocols_verify.py
# Load .env FIRST before any litellm imports
import os
from dotenv import load_dotenv
load_dotenv(override=True)

import asyncio
from litellm_path.client import (
    analyze_query_complexity,
    quick_answer_protocol,
    autopilot_protocol,
)

async def test_protocols():
    q1 = "What is 2+2?"
    q2 = "Analyze the economic impact of artificial intelligence on software engineering jobs"

    c1 = analyze_query_complexity(q1)
    c2 = analyze_query_complexity(q2)
    print(f"[COMPLEXITY] Q1 score: {c1}  (expected: ~0.05 -> Quick Answer)")
    print(f"[COMPLEXITY] Q2 score: {c2}  (expected: >= 0.30 -> Deep or Adaptive)")
    assert c1 < 0.30, f"Q1 should be LOW complexity, got {c1}"
    print("PASS: Complexity scoring correct.")

    print("\nRunning Quick Answer Protocol...")
    res_quick = await quick_answer_protocol(q1, "groq/llama-3.1-8b-instant", is_guest=True)
    print("Steps:", res_quick["steps"])
    print("Output sample:", res_quick["output"][:150])
    assert res_quick["output"].strip(), "Quick Answer returned empty output!"
    print("PASS: Quick Answer Protocol succeeded.")

    print("\nRunning Autopilot Protocol (should Deep Search)...")
    res_auto = await autopilot_protocol(q2, "groq/llama-3.1-8b-instant", is_guest=True)
    print("Steps:", res_auto["steps"])
    print("Output sample:", res_auto["output"][:150])
    assert res_auto["output"].strip(), "Autopilot returned empty output!"
    print("PASS: Autopilot Protocol succeeded.")

if __name__ == "__main__":
    asyncio.run(test_protocols())
