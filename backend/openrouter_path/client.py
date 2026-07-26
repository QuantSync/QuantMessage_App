"""
QuantMessage — openrouter_path/client.py
=========================================
TERTIARY AI PATH — OpenRouter / QuantCore Direct httpx Calls

This module contains all direct httpx-based calls to:
  1. Groq API   (fastest, separate free quota)
  2. OpenRouter free models (50/day shared quota)
  3. OpenRouter paid fallback (gpt-4o-mini safety net)

This code was extracted from agent/graph.py's _call_quantcore_direct()
function. The agent/graph.py module imports from here so both the
LangGraph fallback path and the OpenRouter tertiary path share the
same implementation with no duplication.

This path is used:
  a) As the last-resort fallback when both LiteLLM and LangGraph fail.
  b) Directly when model_id starts with "quantcore/" (user explicitly chose it).
"""

import os
import httpx

# ─────────────────────────────────────────────────────────────────────────────
#  CONSTANTS
# ─────────────────────────────────────────────────────────────────────────────

# Priority order:
#  1. Groq llama-3.1-8b-instant (free, unlimited daily quota, fastest)
#  2. OpenRouter free models (50/day shared quota, may be exhausted)
#  3. openai/gpt-4o-mini via OpenRouter (paid safety net)
QUANTCORE_GROQ_MODEL = "llama-3.1-8b-instant"

QUANTCORE_FREE_MODELS = [
    "nvidia/nemotron-3-ultra-550b-a55b:free",
    "cohere/north-mini-code:free",
    "inclusionai/ling-3.0-flash:free",
]

QUANTCORE_PAID_FALLBACK = "openai/gpt-4o-mini"


# ─────────────────────────────────────────────────────────────────────────────
#  RESPONSE EXTRACTOR
# ─────────────────────────────────────────────────────────────────────────────

def _extract_from_raw_response(data: dict) -> str:
    """
    Extract text from an OpenRouter/OpenAI-format JSON response.
    Handles both normal models (content field) and reasoning-only models
    (content: null, output in reasoning / reasoning_details).
    """
    try:
        choices = data.get("choices", [])
        if not choices:
            return ""
        msg = choices[0].get("message", {})

        # 1. Normal content field
        content = msg.get("content") or ""
        if content.strip():
            return content.strip()

        # 2. Top-level reasoning field
        reasoning = msg.get("reasoning") or ""
        if reasoning.strip():
            return reasoning.strip()

        # 3. reasoning_details array (OpenRouter format for thinking models)
        details = msg.get("reasoning_details") or []
        if details:
            parts = [d.get("text", "") for d in details if d.get("text")]
            combined = "\n".join(parts).strip()
            if combined:
                return combined

        # 4. Error block from OpenRouter
        error = data.get("error", {})
        if error:
            return f"[OpenRouter error: {error.get('message', 'Unknown error')}]"

    except Exception as e:
        return f"[Parse error: {e}]"

    return ""


# ─────────────────────────────────────────────────────────────────────────────
#  CORE DIRECT-CALL FUNCTIONS
# ─────────────────────────────────────────────────────────────────────────────

async def call_groq_direct(
    messages: list[dict],
    model: str = QUANTCORE_GROQ_MODEL,
    max_tokens: int = 4096,
    temperature: float = 0.3,
) -> str:
    """
    Direct async httpx call to Groq's OpenAI-compatible API.
    Returns content string, or raises on failure.
    """
    groq_key = os.environ.get("GROQ_API_KEY", "")
    if not groq_key:
        raise ValueError("GROQ_API_KEY not set")

    async with httpx.AsyncClient(timeout=30.0) as client:
        resp = await client.post(
            "https://api.groq.com/openai/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {groq_key}",
                "Content-Type": "application/json",
            },
            json={
                "model": model,
                "messages": messages,
                "max_tokens": max_tokens,
                "temperature": temperature,
            },
        )

    if resp.status_code == 200:
        data = resp.json()
        content = (
            data.get("choices", [{}])[0]
            .get("message", {})
            .get("content", "") or ""
        )
        if content.strip():
            return content.strip()
        raise ValueError("Groq returned empty content")
    elif resp.status_code == 429:
        raise RuntimeError("Groq rate limited (429)")
    else:
        raise RuntimeError(f"Groq returned HTTP {resp.status_code}")


async def call_openrouter_direct(
    messages: list[dict],
    model: str = QUANTCORE_PAID_FALLBACK,
    max_tokens: int = 4096,
    temperature: float = 0.3,
) -> str:
    """
    Direct async httpx call to OpenRouter API.
    Returns content string, or raises on failure.
    """
    or_key = os.environ.get("OPENROUTER_API_KEY", "")
    if not or_key:
        raise ValueError("OPENROUTER_API_KEY not set")

    headers = {
        "Authorization": f"Bearer {or_key}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://quantmessage.app",
        "X-Title": "QuantMessage AI",
    }

    async with httpx.AsyncClient(timeout=90.0) as client:
        resp = await client.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers=headers,
            json={
                "model": model,
                "messages": messages,
                "max_tokens": max_tokens,
                "temperature": temperature,
            },
        )

    if resp.status_code == 429:
        raise RuntimeError(f"OpenRouter rate limited (429) for {model}")
    if resp.status_code == 401:
        raise ValueError("OpenRouter: 401 Unauthorized — check OPENROUTER_API_KEY")
    if resp.status_code >= 500:
        raise RuntimeError(f"OpenRouter server error ({resp.status_code}) for {model}")

    data = resp.json()
    error_block = data.get("error")
    if error_block:
        code = error_block.get("code", 0)
        msg = error_block.get("message", "Unknown error")
        raise RuntimeError(f"OpenRouter API error {code}: {msg[:120]}")

    result = _extract_from_raw_response(data)
    if result and not result.startswith("["):
        return result
    raise ValueError(f"OpenRouter returned empty/invalid content from {model}")


# ─────────────────────────────────────────────────────────────────────────────
#  QUANTCORE WATERFALL (Groq → Free OpenRouter → Paid OpenRouter)
# ─────────────────────────────────────────────────────────────────────────────

async def call_quantcore_direct(
    messages: list[dict],
    max_tokens: int = 4096,
    temperature: float = 0.3,
) -> str:
    """
    Full QuantCore waterfall:
      1. Groq llama-3.1-8b-instant (free, fast)
      2. OpenRouter free models (3 candidates)
      3. OpenRouter gpt-4o-mini (paid safety net)

    Returns a string response. Raises only if ALL steps fail.
    """
    # ── Step 1: Groq ─────────────────────────────────────────────────────────
    try:
        result = await call_groq_direct(messages, max_tokens=max_tokens, temperature=temperature)
        print(f"   ✅ QuantCore responded via Groq/{QUANTCORE_GROQ_MODEL}")
        return result
    except Exception as e:
        print(f"   ⚠️  Groq failed: {e}. Trying OpenRouter free models...")

    # ── Step 2: OpenRouter free models ───────────────────────────────────────
    or_key = os.environ.get("OPENROUTER_API_KEY", "")
    if not or_key:
        raise RuntimeError("No API keys configured for QuantCore path")

    models_to_try = QUANTCORE_FREE_MODELS + [QUANTCORE_PAID_FALLBACK]
    for model in models_to_try:
        try:
            result = await call_openrouter_direct(
                messages, model=model, max_tokens=max_tokens, temperature=temperature
            )
            print(f"   ✅ QuantCore responded via OpenRouter/{model}")
            return result
        except RuntimeError as e:
            if "429" in str(e) or "rate limited" in str(e).lower():
                print(f"   ⚠️  {model} rate limited, trying next...")
            else:
                print(f"   ⚠️  {model} failed: {e}, trying next...")
        except Exception as e:
            print(f"   ⚠️  {model} exception: {e}, trying next...")

    raise RuntimeError(
        "[QuantCore: All models are currently rate-limited or unavailable. "
        "Please try again later or add credits to your OpenRouter account.]"
    )


# ─────────────────────────────────────────────────────────────────────────────
#  PUBLIC ENTRY POINT (called by pathways/router.py as Path 3)
# ─────────────────────────────────────────────────────────────────────────────

async def quantcore_run(
    query: str,
    model_id: str = "quantcore/auto",
    mode: str = "drive",
    conversation_id: str = "default",
    user_id: str = "guest_user",
    is_guest: bool = True,
) -> dict:
    """
    Runs a simple single-call response via the QuantCore direct path.
    Used as Path 3 (last resort) by the PathwayRouter, and directly
    when model_id starts with 'quantcore/'.

    Returns:
        {"output": str, "steps": list[str], "path": "openrouter"}
    """
    mode_tag = "[GUEST]" if is_guest else f"[USER:{user_id[:8]}]"
    print(f"   🔴 {mode_tag} [PATH 3: OpenRouter/QuantCore] Starting → model={model_id}")

    system_prompt = (
        "You are QuantCore, an advanced AI assistant built into QuantMessage. "
        "Provide a comprehensive, well-structured, and accurate response to the user's query. "
        "Use Markdown formatting for clarity. Be thorough and leave nothing out."
    )
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user",   "content": query},
    ]

    final = await call_quantcore_direct(messages, max_tokens=4096, temperature=0.4)

    steps = [
        "🔴 Path 3 (OpenRouter/QuantCore): Direct httpx response produced",
    ]
    if is_guest:
        steps.append("👤 Mode: Guest session (sign in to save history)")

    return {
        "output": final,
        "steps":  steps,
        "path":   "openrouter",
    }
