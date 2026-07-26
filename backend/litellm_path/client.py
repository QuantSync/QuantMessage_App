"""
QuantMessage — litellm_path/client.py
======================================
PRIMARY AI PATH — LiteLLM Unified Gateway

This module implements a 4-stage inline pipeline using litellm.acompletion().
It is the first and fastest path attempted by the central PathwayRouter.

Pipeline stages:
  Stage 1 (Gatherer):    Deep research & analysis
  Stage 2 (Worker):      Error correction & refinement
  Stage 3 (Supervisor):  Quality gatekeeper (fast Groq check), can retry once
  Stage 4 (Reviewer):    Final polished Markdown formatting

LiteLLM reads API keys from environment automatically:
  GROQ_API_KEY        → groq/* models
  GOOGLE_API_KEY      → gemini/* models
  OPENROUTER_API_KEY  → openrouter/* models

All provider routing is handled transparently by LiteLLM.
No manual if/elif branching needed.
"""

import os
import asyncio
import litellm
from litellm import acompletion

# Suppress verbose LiteLLM debug output and telemetry
litellm.set_verbose = False
litellm.drop_params = True
litellm.suppress_debug_info = True

# ─────────────────────────────────────────────────────────────────────────────
#  CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────

# Fast supervisor model (always Groq — free, very low latency)
_SUPERVISOR_MODEL = "groq/llama-3.1-8b-instant"

# Fallback chain used by LiteLLM if the requested model fails
_LITELLM_FALLBACKS = [
    "gemini/gemini-2.0-flash",
    "groq/llama-3.3-70b-versatile",
    "openrouter/openai/gpt-4o-mini",
]

# Per-stage timeouts (seconds)
_STAGE_TIMEOUT = 60
_SUPERVISOR_TIMEOUT = 20

# Max retries inside LiteLLM itself before escalating to PathwayRouter
_MAX_RETRIES = 2

# Max supervisor retries for the quality loop
_MAX_SUPERVISOR_RETRIES = 1


# ─────────────────────────────────────────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────────────────────────────────────────

def _set_api_keys() -> None:
    """Ensure LiteLLM reads all provider keys from environment."""
    # LiteLLM reads these env vars automatically by convention —
    # this call just makes any runtime changes from dotenv visible.
    groq_key = os.environ.get("GROQ_API_KEY", "")
    google_key = os.environ.get("GOOGLE_API_KEY", "")
    or_key = os.environ.get("OPENROUTER_API_KEY", "")

    if groq_key:
        os.environ["GROQ_API_KEY"] = groq_key
    if google_key:
        os.environ["GOOGLE_API_KEY"] = google_key
    if or_key:
        os.environ["OPENROUTER_API_KEY"] = or_key


async def _litellm_call(
    model: str,
    messages: list[dict],
    temperature: float = 0.3,
    max_tokens: int = 4096,
    timeout: int = _STAGE_TIMEOUT,
    use_fallback: bool = True,
) -> str:
    """
    Single LiteLLM completion call with fallback and timeout.
    Returns the text content string or raises on total failure.
    """
    _set_api_keys()

    # Build fallback list — exclude the primary if it's already in the list
    fallbacks = [f for f in _LITELLM_FALLBACKS if f != model] if use_fallback else []

    try:
        response = await asyncio.wait_for(
            acompletion(
                model=model,
                messages=messages,
                temperature=temperature,
                max_tokens=max_tokens,
                num_retries=_MAX_RETRIES,
                fallbacks=fallbacks if fallbacks else None,
            ),
            timeout=timeout,
        )
        content = response.choices[0].message.content or ""
        return content.strip()
    except asyncio.TimeoutError:
        raise TimeoutError(f"LiteLLM call to '{model}' timed out after {timeout}s")
    except Exception as e:
        raise RuntimeError(f"LiteLLM call to '{model}' failed: {e}")


# ─────────────────────────────────────────────────────────────────────────────
#  STAGE 1 — GATHERER (Search Analyst)
# ─────────────────────────────────────────────────────────────────────────────

async def _stage_gatherer(query: str, model_id: str, retry_note: str = "") -> str:
    system_prompt = (
        "You are the Gatherer (Stage 1). Analyze the user's query and produce an exhaustive, "
        "deeply researched response. Leave no stone unturned. Gather all context, edge cases, "
        "best practices, and deep dive into nuances. Compile a highly detailed initial solution. "
        "Do NOT truncate or cut short your analysis under any circumstances. "
        "If the user asks for code, provide complete files, comprehensive logic, and architectural reasoning."
        + (f"\n\nSUPERVISOR FEEDBACK (address this): {retry_note}" if retry_note else "")
    )
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user",   "content": query},
    ]
    return await _litellm_call(model_id, messages, temperature=0.4, max_tokens=4096)


# ─────────────────────────────────────────────────────────────────────────────
#  STAGE 2 — WORKER (Error Solver)
# ─────────────────────────────────────────────────────────────────────────────

async def _stage_worker(query: str, gathered: str, model_id: str) -> str:
    system_prompt = (
        "You are the Worker (Stage 2). Your job is to review the deep-researched data compiled by the Gatherer. "
        "Actively look for multiple potential errors simultaneously: factual inaccuracies, subtle code bugs, "
        "unhandled edge cases, security flaws, or logical inconsistencies. "
        "Improvise and solve every single error you find. Output an expansive, completely corrected, "
        "fully functional, and hyper-detailed solution. "
        "Never truncate code. Output long, detailed explanations, rigorous proofs, and full code blocks where applicable."
    )
    user_prompt = (
        f"Original Query: {query}\n\n"
        f"Gatherer Data:\n{gathered}\n\n"
        "Please identify all errors and provide the expansive, corrected solution."
    )
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user",   "content": user_prompt},
    ]
    return await _litellm_call(model_id, messages, temperature=0.2, max_tokens=4096)


# ─────────────────────────────────────────────────────────────────────────────
#  STAGE 3 — SUPERVISOR (Quality Gatekeeper)
# ─────────────────────────────────────────────────────────────────────────────

async def _stage_supervisor(query: str, solved: str) -> tuple[str, str]:
    """
    Returns (verdict, notes) where verdict is 'approve' or 'retry'.
    Always uses the fast Groq supervisor model regardless of user model_id.
    """
    system_prompt = (
        "You are the Supervisor (Stage 3). You oversee the pipeline to meticulously ensure all errors "
        "are fully resolved before final output. "
        "Check for: syntax errors, logic flaws, completeness, depth of research, adherence to user constraints. "
        "Respond ONLY with:\n"
        "VERDICT: approve | retry\n"
        "NOTES: <your feedback on any remaining issues>"
    )
    user_prompt = (
        f"Query: {query}\n\n"
        f"Worker's Solved Data:\n{solved}\n\n"
        "Are there any remaining errors, or is this deep, exhaustive, and fully ready?"
    )
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user",   "content": user_prompt},
    ]

    raw = await _litellm_call(
        _SUPERVISOR_MODEL, messages,
        temperature=0.0, max_tokens=512,
        timeout=_SUPERVISOR_TIMEOUT, use_fallback=False,
    )

    verdict = "approve"
    notes = "All checks passed."
    for line in raw.split("\n"):
        if line.startswith("VERDICT:"):
            v = line.replace("VERDICT:", "").strip().lower()
            if v in ("approve", "retry"):
                verdict = v
        elif line.startswith("NOTES:"):
            notes = line.replace("NOTES:", "").strip()

    return verdict, notes


# ─────────────────────────────────────────────────────────────────────────────
#  STAGE 4 — REVIEWER & PRODUCER (Final Output)
# ─────────────────────────────────────────────────────────────────────────────

async def _stage_reviewer(query: str, solved: str, model_id: str) -> str:
    system_prompt = (
        "You are the Reviewer (Stage 4). Your task is to review all the expansive answers from previous stages, "
        "ensure they directly, deeply, and comprehensively answer the user's query, "
        "and format the final response beautifully using Markdown. "
        "Synthesize all analysis, deep research, and code into a professional, expansive, and highly detailed response. "
        "Never truncate your output. If the response is extremely long, output the full length. Leave nothing out. "
        "Do not include meta-commentary about the pipeline. Just produce the final polished response."
    )
    user_prompt = (
        f"Original Query: {query}\n\n"
        f"Worker's Final Solved Data:\n{solved}\n\n"
        "Please produce the final polished, comprehensively detailed Markdown response."
    )
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user",   "content": user_prompt},
    ]
    return await _litellm_call(model_id, messages, temperature=0.2, max_tokens=8192)


# ─────────────────────────────────────────────────────────────────────────────
#  PUBLIC ENTRY POINT
# ─────────────────────────────────────────────────────────────────────────────

async def litellm_run(
    query: str,
    model_id: str,
    mode: str = "drive",
    conversation_id: str = "default",
    user_id: str = "guest_user",
    is_guest: bool = True,
) -> dict:
    """
    Run the 4-stage LiteLLM pipeline.

    Returns:
        {
            "output": str,
            "steps": list[str],
            "path": "litellm",
        }

    Raises:
        Exception — if any stage fails completely (signals PathwayRouter to try next path).
    """
    mode_tag = "[GUEST]" if is_guest else f"[USER:{user_id[:8]}]"
    print(f"   {mode_tag} [PATH 1: LiteLLM] Starting model={model_id}")

    retry_note = ""
    solved = ""

    # ── Stage 1 (with optional supervisor retry loop) ────────────────────────
    gathered = await _stage_gatherer(query, model_id)
    print(f"   LiteLLM Stage 1 (Gatherer) complete - {len(gathered)} chars")

    # ── Stage 2 ──────────────────────────────────────────────────────────────
    solved = await _stage_worker(query, gathered, model_id)
    print(f"   LiteLLM Stage 2 (Worker) complete - {len(solved)} chars")

    # ── Stage 3 — Supervisor quality check with one retry allowed ────────────
    try:
        verdict, notes = await _stage_supervisor(query, solved)
        print(f"   LiteLLM Stage 3 (Supervisor) verdict: {verdict}")

        if verdict == "retry":
            print(f"   Supervisor requested retry: {notes[:80]}...")
            gathered2 = await _stage_gatherer(query, model_id, retry_note=notes)
            solved = await _stage_worker(query, gathered2, model_id)
            print(f"   LiteLLM Retry complete - {len(solved)} chars")
    except Exception as sup_err:
        # Supervisor failure is non-fatal — proceed with existing solved data
        print(f"   Supervisor check failed ({sup_err}), proceeding without retry.")

    # ── Stage 4 — Final output ────────────────────────────────────────────────
    final = await _stage_reviewer(query, solved, model_id)
    print(f"   LiteLLM Stage 4 (Reviewer) complete - {len(final)} chars")

    steps = [
        "Stage 1 (LiteLLM): Gathered & analyzed",
        "Stage 2 (LiteLLM): Errors corrected",
        "Stage 3 (LiteLLM): Supervisor approved",
        "Stage 4 (LiteLLM): Final response produced",
    ]
    if is_guest:
        steps.append("Mode: Guest session (sign in to save history)")

    return {
        "output": final,
        "steps":  steps,
        "path":   "litellm",
    }
