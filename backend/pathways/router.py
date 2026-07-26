"""
QuantMessage — pathways/router.py
===================================
CENTRAL PATHWAY ROUTER

Implements the tri-path priority waterfall:

  PATH 1 (Primary):   LiteLLM unified gateway     → litellm_path/client.py
  PATH 2 (Fallback):  LangChain + LangGraph        → agent/graph.py
  PATH 3 (Last Resort): OpenRouter / QuantCore     → openrouter_path/client.py

The router tries each path in order, catching all exceptions.
On success, it returns immediately without trying the next path.
The "path" key in the returned dict tells the caller (and Flutter app)
which path actually served the response.

Special case: if model_id starts with "quantcore/", Path 3 is tried first,
then Path 1 as fallback (QuantCore users want the direct httpx behavior).
"""

import asyncio
from litellm_path.models_catalogue import is_quantcore
from litellm_path.client import litellm_run
from agent.graph import run_agent_graph
from openrouter_path.client import quantcore_run


# ─────────────────────────────────────────────────────────────────────────────
#  TIMEOUT GUARDS (seconds) — per full-path attempt
# ─────────────────────────────────────────────────────────────────────────────
_LITELLM_PATH_TIMEOUT = 180    # 3 min for full 4-stage pipeline
_LANGGRAPH_PATH_TIMEOUT = 240  # 4 min for LangGraph (heavier pipeline)
_OPENROUTER_PATH_TIMEOUT = 120  # 2 min for direct httpx calls


# ─────────────────────────────────────────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────────────────────────────────────────

async def _run_with_timeout(coro, timeout: int, path_name: str) -> dict:
    """Wrap a coroutine with a timeout and return its result dict."""
    try:
        return await asyncio.wait_for(coro, timeout=timeout)
    except asyncio.TimeoutError:
        raise TimeoutError(f"[PathwayRouter] {path_name} timed out after {timeout}s")


# ─────────────────────────────────────────────────────────────────────────────
#  MAIN ROUTER
# ─────────────────────────────────────────────────────────────────────────────

async def route_chat(
    query: str,
    model_id: str,
    mode: str = "drive",
    conversation_id: str = "default",
    user_id: str = "guest_user",
    is_guest: bool = True,
) -> dict:
    """
    Central routing function called by main.py for every chat request.

    Args:
        query:           The user's message (may include extracted PDF content).
        model_id:        The model ID string chosen in the Flutter selector.
        mode:            "drive" | "fly" | "jet" (pipeline depth).
        conversation_id: UUID of the conversation.
        user_id:         Supabase user ID or "guest_user".
        is_guest:        True if user is not authenticated.

    Returns:
        {
            "output":    str,        ← final response text
            "steps":     list[str],  ← agent step labels for UI
            "path":      str,        ← "litellm" | "langgraph" | "openrouter"
            "path_used": str,        ← human-readable label for logging/UI
        }
    """
    kwargs = dict(
        query=query,
        model_id=model_id,
        mode=mode,
        conversation_id=conversation_id,
        user_id=user_id,
        is_guest=is_guest,
    )

    # ── Special case: QuantCore model → try Path 3 first ───────────────────
    if is_quantcore(model_id):
        print("[PathwayRouter] model_id=quantcore/* -> trying Path 3 (OpenRouter) first")
        try:
            result = await _run_with_timeout(
                quantcore_run(**kwargs),
                _OPENROUTER_PATH_TIMEOUT,
                "Path 3 (OpenRouter/QuantCore)",
            )
            result["path_used"] = "QuantCore Direct"
            return result
        except Exception as e:
            print(f"[PathwayRouter] Path 3 (QuantCore primary) failed: {e}")
            print("[PathwayRouter] Falling through to Path 1 (LiteLLM) as backup...")

    # ── PATH 1: LiteLLM (primary) ────────────────────────────────────────────
    print(f"[PathwayRouter] Trying PATH 1 (LiteLLM) -> model={model_id}")
    try:
        result = await _run_with_timeout(
            litellm_run(**kwargs),
            _LITELLM_PATH_TIMEOUT,
            "Path 1 (LiteLLM)",
        )
        if result.get("output", "").strip():
            result["path_used"] = "LiteLLM (Primary)"
            print("[PathwayRouter] SUCCESS: PATH 1 (LiteLLM) succeeded.")
            return result
        raise ValueError("LiteLLM returned empty output")
    except Exception as e:
        print(f"[PathwayRouter] ERROR: PATH 1 (LiteLLM) failed: {e}")
        print("[PathwayRouter] WARNING: Falling to PATH 2 (LangGraph)...")

    # ── PATH 2: LangChain + LangGraph (fallback) ─────────────────────────────
    print(f"[PathwayRouter] Trying PATH 2 (LangGraph) -> model={model_id}")
    try:
        # run_agent_graph has a different signature — map our kwargs
        result = await _run_with_timeout(
            run_agent_graph(
                query=query,
                model_id=model_id,
                mode=mode,
                conversation_id=conversation_id,
                user_id=user_id,
                is_guest=is_guest,
            ),
            _LANGGRAPH_PATH_TIMEOUT,
            "Path 2 (LangGraph)",
        )
        if result.get("output", "").strip():
            result["path"] = "langgraph"
            result["path_used"] = "LangChain + LangGraph (Fallback)"
            print("[PathwayRouter] SUCCESS: PATH 2 (LangGraph) succeeded.")
            return result
        raise ValueError("LangGraph returned empty output")
    except Exception as e:
        print(f"[PathwayRouter] ERROR: PATH 2 (LangGraph) failed: {e}")
        print("[PathwayRouter] WARNING: Falling to PATH 3 (OpenRouter/QuantCore) as last resort...")

    # ── PATH 3: OpenRouter / QuantCore (last resort) ─────────────────────────
    print(f"[PathwayRouter] Trying PATH 3 (OpenRouter) -> model={model_id}")
    try:
        result = await _run_with_timeout(
            quantcore_run(**kwargs),
            _OPENROUTER_PATH_TIMEOUT,
            "Path 3 (OpenRouter)",
        )
        result["path_used"] = "OpenRouter/QuantCore (Last Resort)"
        print("[PathwayRouter] SUCCESS: PATH 3 (OpenRouter) succeeded.")
        return result
    except Exception as e:
        print(f"[PathwayRouter] ERROR: PATH 3 (OpenRouter) failed: {e}")

    # ── All paths failed ─────────────────────────────────────────────────────
    error_msg = (
        "All AI pathways are currently unavailable.\n\n"
        "Please try:\n"
        "- Selecting a different model\n"
        "- Checking your internet connection\n"
        "- Waiting a moment and retrying\n\n"
        "If this persists, the backend may need to be restarted."
    )
    return {
        "output":    error_msg,
        "steps":     ["All paths failed"],
        "path":      "error",
        "path_used": "None (all paths failed)",
    }
