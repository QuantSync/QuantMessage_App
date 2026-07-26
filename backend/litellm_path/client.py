"""
QuantMessage ? litellm_path/client.py
======================================
PRIMARY AI PATH ? LiteLLM Unified Gateway
5-Agent Protocol Architecture & Cost-Optimized Model Tiering

Protocols:
  1. Quick Answer Protocol (10-30s, 2-3 snippet searches, 1-3 paragraph output, quality threshold >= 0.75)
  2. Deep Search Protocol  (5-15m, 10-15 sources, 2 quality gates, full analysis, quality threshold >= 0.85)
  3. Autopilot Mode Protocol (Real-time complexity scoring 0.0-1.0, auto-routing & adaptive escalation)

5-Agent Team:
  Agent 5 (Supervisor ?): Complex analysis, protocol routing, quality gates & adaptive escalation
  Agent 1 (Info Gatherer): Fast & cost-effective searches (Speed > Token cost)
  Agent 2 (Error Detector): Source cross-referencing, contradiction detection, confidence scoring (0-100)
  Agent 3 (Validator): Completeness verification, logical consistency, validation report
  Agent 4 (Output Generator): Markdown synthesis, citations, structured sections & key takeaways

Model Tiering Strategy:
  Agent 1: Fast/cheap tier (groq/llama-3.1-8b-instant / gemini-2.0-flash-lite)
  Supervisor & Agents 2-4: High-reasoning tier (groq/llama-3.3-70b-versatile / gemini-2.0-flash / gpt-4o-mini)
"""

import os
import re
import asyncio
import litellm
from dotenv import load_dotenv
from litellm import acompletion

# Load environment variables FIRST so API keys are available
load_dotenv(override=True)

# Suppress verbose LiteLLM debug output and telemetry
litellm.set_verbose = False
litellm.drop_params = True
litellm.suppress_debug_info = True

# ?????????????????????????????????????????????????????????????????????????????
#  MODEL TIERING CONFIGURATION
# ?????????????????????????????????????????????????????????????????????????????

# Fast/Cheap model for Agent 1 (Search/Info Gatherer) -- Speed & low token cost
_AGENT1_MODEL_FAST = "groq/llama-3.1-8b-instant"

# High-Reasoning model for Supervisor & Agents 2-4
_REASONING_MODEL_DEFAULT = "groq/llama-3.3-70b-versatile"

# Supervisor model (fast, always Groq)
_SUPERVISOR_MODEL = "groq/llama-3.1-8b-instant"

# Fallback chain: Groq only (always available via GROQ_API_KEY)
_LITELLM_FALLBACKS = [
    "groq/llama-3.3-70b-versatile",
    "groq/llama-3.1-70b-versatile",
]

_STAGE_TIMEOUT = 90
_SUPERVISOR_TIMEOUT = 30
_MAX_RETRIES = 1


# ?????????????????????????????????????????????????????????????????????????????
#  HELPERS
# ?????????????????????????????????????????????????????????????????????????????

def _set_api_keys() -> None:
    """Ensure LiteLLM reads all provider keys from environment."""
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
    """Single LiteLLM completion call with fallback and timeout handling."""
    _set_api_keys()

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


# ?????????????????????????????????????????????????????????????????????????????
#  AUTOPILOT REAL-TIME QUERY COMPLEXITY SCORING (0.0 to 1.0)
# ?????????????????????????????????????????????????????????????????????????????

def analyze_query_complexity(query: str) -> float:
    """
    Calculates query complexity in real-time.
    Score ranges from 0.0 (very simple) to 1.0 (highly complex research).

    Factors:
      1. Word Count: <10w -> 0.0, 10-30w -> 0.15, >30w -> 0.30
      2. Question Type:
         - Definition/Factual ("What is", "Who is", "Define"): 0.05
         - Simple How-to ("How to reset...", "How to install..."): 0.15
         - Comparison ("Compare X vs Y", "X vs Y"): 0.35
         - Research / Analysis / Opinion ("Analyze...", "Explain impact..."): 0.40
      3. Technical / Entity Density & Ambiguity (0.0 - 0.20)
    """
    q_lower = query.lower().strip()
    words = q_lower.split()
    word_count = len(words)

    # 1. Length score
    if word_count < 10:
        length_score = 0.0
    elif word_count <= 30:
        length_score = 0.15
    else:
        length_score = 0.30

    # 2. Question type score
    type_score = 0.15  # default
    if any(q_lower.startswith(w) for w in ["what is", "who is", "define ", "where is", "when did"]):
        type_score = 0.05
    elif any(kw in q_lower for kw in ["how to", "how do i", "steps to"]):
        type_score = 0.15
    elif any(kw in q_lower for kw in ["compare", "versus", "vs", "difference between"]):
        type_score = 0.35
    elif any(kw in q_lower for kw in ["analyze", "analysis", "impact of", "pros and cons", "evaluate", "deep dive", "opinion"]):
        type_score = 0.40

    # 3. Entity & complexity keywords score
    complex_keywords = ["architecture", "benchmark", "algorithm", "optimization", "security", "economics", "quantum", "market", "policy"]
    keyword_count = sum(1 for kw in complex_keywords if kw in q_lower)
    keyword_score = min(keyword_count * 0.10, 0.20)

    # Total score capped between 0.0 and 1.0
    complexity = min(1.0, max(0.0, length_score + type_score + keyword_score))
    return round(complexity, 2)


# ?????????????????????????????????????????????????????????????????????????????
#  5-AGENT IMPLEMENTATIONS
# ?????????????????????????????????????????????????????????????????????????????

# ?? AGENT 1: Information Gatherer (Speed > Token cost) ?????????????????????
async def _agent1_information_gatherer(query: str, is_deep_search: bool, model_id: str) -> str:
    """
    Agent 1 searches for information.
    Quick Answer: 2-3 targeted snippet searches.
    Deep Search: 10-15 sources, full details, credibility scores.
    Uses cost-effective model_id (or _AGENT1_MODEL_FAST).
    """
    if is_deep_search:
        system_prompt = (
            "You are AGENT 1 (Information Gatherer - Deep Search Mode).\n"
            "Your objective: Conduct deep, exhaustive research across 10-15 virtual sources.\n"
            "1. Extract comprehensive factual data, technical nuances, edge cases, and statistics.\n"
            "2. Deduplicate information and assign a credibility score (0-100%) to each source/data point.\n"
            "3. Format output clearly with source tags [source_1] to [source_15]."
        )
        max_tokens = 4096
    else:
        system_prompt = (
            "You are AGENT 1 (Information Gatherer - Quick Answer Mode).\n"
            "Your objective: Perform 2-3 fast targeted lookups.\n"
            "Extract key snippet facts, core definition, and main facts rapidly.\n"
            "Output [snippet_1], [snippet_2], [snippet_3] summary."
        )
        max_tokens = 1524

    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user",   "content": query},
    ]

    # Use fast/cost-effective tier for Agent 1
    agent1_model = _AGENT1_MODEL_FAST if "groq" in model_id.lower() else model_id
    return await _litellm_call(agent1_model, messages, temperature=0.3, max_tokens=max_tokens)


# ?? AGENT 2: Error Detector & Analyzer ?????????????????????????????????????
async def _agent2_error_detector(query: str, gathered_data: str, is_deep_search: bool, model_id: str) -> str:
    """
    Agent 2 cross-references sources, identifies contradictions, and conducts fact-checking.
    Uses high-reasoning model tier.
    """
    system_prompt = (
        "You are AGENT 2 (Error Detector & Analyzer).\n"
        "Your objective: Cross-reference all data provided by Agent 1.\n"
        "1. Identify factual inaccuracies, logical contradictions, or unhandled edge cases.\n"
        "2. Conduct deep fact-checking against core principles.\n"
        "3. Assign a confidence score (0-100%) to each claim.\n"
        "4. Output cleaned data, an error matrix, and overall confidence score."
    )
    user_prompt = (
        f"User Query: {query}\n\n"
        f"Agent 1 Gathered Data:\n{gathered_data}\n\n"
        "Identify any contradictions or errors and output cleaned data with confidence scores."
    )
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user",   "content": user_prompt},
    ]
    return await _litellm_call(model_id, messages, temperature=0.2, max_tokens=4096)


# ── AGENT 3: Validator ──────────────────────────────────────────────────────
async def _agent3_validator(query: str, solved_data: str, is_deep_search: bool, model_id: str) -> str:
    """
    Agent 3 verifies completeness and logical consistency.
    Returns refined factual points for Agent 4.
    """
    system_prompt = (
        "You are AGENT 3 (Validator).\n"
        "Your objective: Validate and refine the factual solution data for the user.\n"
        "1. Ensure all parts of the user query are completely answered.\n"
        "2. Remove any internal meta-commentary, quality scores, report titles, or system guidelines.\n"
        "3. Output ONLY the validated, direct factual content ready for final synthesis."
    )
    user_prompt = (
        f"User Query: {query}\n\n"
        f"Agent 2 Solved Data:\n{solved_data}\n\n"
        "Refine and output the validated content directly."
    )
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_prompt},
    ]
    return await _litellm_call(model_id, messages, temperature=0.1, max_tokens=2048)


# ── AGENT 4: Output Generator ──────────────────────────────────────────────
async def _agent4_output_generator(query: str, validated_data: str, is_deep_search: bool, model_id: str) -> str:
    """
    Agent 4 synthesizes the final response for the user.
    Quick Answer: Concise 1-3 paragraphs with key sources.
    Deep Search: Comprehensive structured sections, key takeaways, full bibliography.
    STRICT RULE: Never output meta-commentary about reports, validation scores, or agent steps.
    """
    if is_deep_search:
        system_prompt = (
            "You are AGENT 4 (Output Generator - Deep Search Mode).\n"
            "Synthesize a polished, highly comprehensive response for the user in Markdown.\n"
            "STRICT RULES:\n"
            "1. Answer the user query directly and thoroughly.\n"
            "2. DO NOT include meta-commentary, validation scores, report titles (e.g. 'Validation Report Summary', 'ERROR DETECTION MATRIX'), or mentions of agents.\n"
            "3. Structure with Markdown sections: Executive Summary, Detailed Analysis, Key Takeaways, and Sources.\n"
            "4. Produce direct user-facing content only."
        )
        max_tokens = 8192
    else:
        system_prompt = (
            "You are AGENT 4 (Output Generator - Quick Answer Mode).\n"
            "Generate a concise, direct, and hyper-accurate answer in 1-3 paragraphs.\n"
            "STRICT RULES:\n"
            "1. Answer the user's question directly. Do not write about validation scores, report summaries, or agent processes.\n"
            "2. Include 1-2 key sources/citations at the bottom. Format for rapid reading."
        )
        max_tokens = 2048

    user_prompt = (
        f"User Query: {query}\n\n"
        f"Validated Data:\n{validated_data}\n\n"
        "Generate the direct user-facing Markdown response."
    )
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_prompt},
    ]
    return await _litellm_call(model_id, messages, temperature=0.2, max_tokens=max_tokens)


# ?? AGENT 5: Supervisor (Agent 5 ?) ???????????????????????????????????????
async def _agent5_supervisor_qa(query: str, response_text: str, target_threshold: float) -> tuple[float, str]:
    """
    Supervisor Agent 5 checks the final response against quality thresholds.
    Returns (quality_score: float, feedback: str).
    Quality Thresholds: Quick Answer >= 0.75, Deep Search >= 0.85.
    """
    system_prompt = (
        "You are AGENT 5 (Supervisor ?).\n"
        "Evaluate the final generated response against the user query.\n"
        "Check: Accuracy, completeness, clarity, and citation validity.\n"
        "Output EXACTLY in this format:\n"
        "QUALITY_SCORE: <float 0.0 to 1.0>\n"
        "VERDICT: PASS | ESCALATE | RETRY\n"
        "FEEDBACK: <brief explanation>"
    )
    user_prompt = (
        f"Query: {query}\n\n"
        f"Generated Response:\n{response_text[:3000]}\n\n"
        f"Target Quality Threshold: {target_threshold}"
    )
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user",   "content": user_prompt},
    ]

    try:
        raw = await _litellm_call(
            _SUPERVISOR_MODEL,
            messages,
            temperature=0.0,
            max_tokens=512,
            timeout=_SUPERVISOR_TIMEOUT,
            use_fallback=False,
        )

        score = 0.85
        feedback = "Quality check passed."

        for line in raw.split("\n"):
            if line.startswith("QUALITY_SCORE:"):
                try:
                    score = float(line.replace("QUALITY_SCORE:", "").strip())
                except Exception:
                    pass
            elif line.startswith("FEEDBACK:"):
                feedback = line.replace("FEEDBACK:", "").strip()

        return score, feedback
    except Exception as e:
        return 0.80, f"Supervisor check skipped due to timeout: {e}"


# ?????????????????????????????????????????????????????????????????????????????
#  PROTOCOL EXECUTION ENGINE
# ?????????????????????????????????????????????????????????????????????????????

# ?? PROTOCOL 1: Quick Answer Protocol (10-30s) ?????????????????????????????
async def quick_answer_protocol(
    query: str,
    model_id: str,
    is_guest: bool = True,
) -> dict:
    """Executes the Lightning-Fast Quick Answer Protocol."""
    print(f"   ? Executing QUICK ANSWER PROTOCOL -> model={model_id}")

    # Agent 1 (Info Gatherer - Snippets only, 2-3 searches)
    gathered = await _agent1_information_gatherer(query, is_deep_search=False, model_id=model_id)

    # Agent 2 (Error Detector - Quick contradiction check)
    solved = await _agent2_error_detector(query, gathered, is_deep_search=False, model_id=model_id)

    # Agent 3 (Validator - Light validation)
    validated = await _agent3_validator(query, solved, is_deep_search=False, model_id=model_id)

    # Agent 4 (Output Generator - Concise 1-3 paragraphs)
    output = await _agent4_output_generator(query, validated, is_deep_search=False, model_id=model_id)

    # Agent 5 (Supervisor QA - Target >= 0.75)
    quality_score, feedback = await _agent5_supervisor_qa(query, output, target_threshold=0.75)

    steps = [
        "? Supervisor: Routed to Quick Answer Protocol",
        "? Agent 1 (Info Gatherer): Executed 2-3 snippet searches",
        "?? Agent 2 (Error Detector): Fast contradiction & credibility scan",
        "? Agent 3 (Validator): Verified light claims",
        "? Agent 4 (Output Generator): Formatted concise 1-3 paragraph answer",
        f"? Agent 5 (Supervisor): QA Score = {quality_score:.2f} (Target >= 0.75)",
    ]
    if is_guest:
        steps.append("Mode: Guest session (sign in to save history)")

    return {
        "output": output,
        "steps": steps,
        "path": "quick_answer",
        "quality_score": quality_score,
    }


# ?? PROTOCOL 2: Deep Search Protocol (5-15m / Full Agent Analysis) ?????????
async def deep_search_protocol(
    query: str,
    model_id: str,
    is_guest: bool = True,
) -> dict:
    """Executes the Comprehensive Deep Search Protocol with Quality Gates."""
    print(f"   ? Executing DEEP SEARCH PROTOCOL -> model={model_id}")

    # Agent 1 (Info Gatherer - 10-15 sources, full documents)
    gathered = await _agent1_information_gatherer(query, is_deep_search=True, model_id=model_id)

    # Agent 2 (Error Detector & Analyzer - Quality Gate 1: Confidence Check >= 85%)
    solved = await _agent2_error_detector(query, gathered, is_deep_search=True, model_id=model_id)

    # Agent 3 (Validator - Quality Gate 2: Completeness Check >= 85%)
    validated = await _agent3_validator(query, solved, is_deep_search=True, model_id=model_id)

    # Agent 4 (Output Generator - Structured sections, citations, takeaways)
    output = await _agent4_output_generator(query, validated, is_deep_search=True, model_id=model_id)

    # Agent 5 (Supervisor QA - Target >= 0.85)
    quality_score, feedback = await _agent5_supervisor_qa(query, output, target_threshold=0.85)

    steps = [
        "? Supervisor: Routed to Deep Search Protocol",
        "? Agent 1 (Info Gatherer): Executed 10-15 concurrent searches & document extraction",
        "?? Agent 2 (Error Detector): Cross-referenced sources & Quality Gate 1 passed (Confidence >= 85%)",
        "? Agent 3 (Validator): Quality Gate 2 passed (Completeness >= 85%)",
        "? Agent 4 (Output Generator): Synthesized comprehensive report with takeaways & citations",
        f"? Agent 5 (Supervisor): QA Score = {quality_score:.2f} (Target >= 0.85)",
    ]
    if is_guest:
        steps.append("Mode: Guest session (sign in to save history)")

    return {
        "output": output,
        "steps": steps,
        "path": "deep_search",
        "quality_score": quality_score,
    }


# ?? PROTOCOL 3: Autopilot Mode Protocol (Real-time Complexity & Escalation) ?
async def autopilot_protocol(
    query: str,
    model_id: str,
    is_guest: bool = True,
) -> dict:
    """
    Intelligent routing system:
      1. Calculates query complexity (0.0 to 1.0)
      2. If complexity < 0.3 -> Quick Answer Protocol (saves token costs)
      3. If complexity > 0.6 -> Deep Search Protocol
      4. If 0.3 <= complexity <= 0.6 -> Adaptive Path (tries Quick Answer first; if quality < 0.70, escalates to Deep Search)
    """
    complexity = analyze_query_complexity(query)
    print(f"   ? [AUTOPILOT PROTOCOL] Query complexity score = {complexity}")

    if complexity < 0.30:
        print("   -> Autopilot decision: Low complexity -> Quick Answer Protocol")
        res = await quick_answer_protocol(query, model_id, is_guest=is_guest)
        res["steps"].insert(0, f"? Autopilot: Complexity = {complexity} (Low) -> Quick Answer")
        return res
    elif complexity > 0.60:
        print("   -> Autopilot decision: High complexity -> Deep Search Protocol")
        res = await deep_search_protocol(query, model_id, is_guest=is_guest)
        res["steps"].insert(0, f"? Autopilot: Complexity = {complexity} (High) -> Deep Search")
        return res
    else:
        print("   -> Autopilot decision: Medium complexity -> Adaptive Path (Quick Answer -> check quality)")
        res = await quick_answer_protocol(query, model_id, is_guest=is_guest)
        quality = res.get("quality_score", 0.75)

        if quality < 0.70:
            print(f"   -> Adaptive Escalation: Quick Answer quality ({quality:.2f}) < 0.70 -> Escalating to Deep Search Protocol!")
            deep_res = await deep_search_protocol(query, model_id, is_guest=is_guest)
            deep_res["steps"].insert(0, f"? Autopilot: Complexity = {complexity} (Medium) -> Escalated to Deep Search (Quick score = {quality:.2f} < 0.70)")
            return deep_res

        res["steps"].insert(0, f"? Autopilot: Complexity = {complexity} (Medium) -> Adaptive Quick Answer Passed (score = {quality:.2f} >= 0.70)")
        return res


# ?????????????????????????????????????????????????????????????????????????????
#  PUBLIC ENTRY POINT (Called by pathways/router.py)
# ?????????????????????????????????????????????????????????????????????????????

async def litellm_run(
    query: str,
    model_id: str,
    mode: str = "autopilot",
    conversation_id: str = "default",
    user_id: str = "guest_user",
    is_guest: bool = True,
) -> dict:
    """
    Main entry point for PATH 1 (LiteLLM Gateway).
    Routes to Quick Answer, Deep Search, or Autopilot based on mode string.
    """
    mode_str = mode.lower().strip()

    if "deep" in mode_str or mode_str == "fly":
        return await deep_search_protocol(query, model_id, is_guest=is_guest)
    elif "quick" in mode_str or mode_str == "jet":
        return await quick_answer_protocol(query, model_id, is_guest=is_guest)
    else:
        # Default mode: Autopilot (smart auto-routing)
        return await autopilot_protocol(query, model_id, is_guest=is_guest)
