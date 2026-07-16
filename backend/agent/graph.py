"""
QuantMessage Multi-Agent Backend – graph.py
============================================
4-Agent Pipeline with Self-Error-Correction:
  1. THINKER  – Deep reasoning & initial answer generation
  2. REVIEWER – Quality-checks the Thinker's draft, flags errors
  3. SUPERVISOR – Decides: approve / send back for correction / use tools
  4. PRODUCER  – Polishes & formats the final response for the user

All agents use the API keys from .env and auto-select based on model_id
from the Flutter app.
"""

import os
from typing import TypedDict, Annotated, Sequence, Optional, List
from langchain_core.messages import (
    BaseMessage, HumanMessage, AIMessage, FunctionMessage
)
from langgraph.graph import StateGraph, END
from langchain_groq import ChatGroq
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder

from agent.tools import get_tools

# ─────────────────────────────────────────────────────────────────────────────
#  STATE DEFINITION
# ─────────────────────────────────────────────────────────────────────────────

class AgentState(TypedDict):
    # Core conversation
    messages:         Annotated[Sequence[BaseMessage], "conversation history"]
    model_id:         str
    mode:             str   # "drive" | "fly" | "jet"

    # Pipeline stages
    thinker_draft:    str   # Thinker's raw answer
    reviewer_verdict: str   # "approve" | "revise" | "use_tools"
    reviewer_notes:   str   # Reviewer feedback
    supervisor_decision: str  # "approve" | "retry_thinker" | "use_tools"
    final_output:     str   # Producer's polished answer

    # Retry tracking (self-correction loop guard)
    retry_count:      int
    current_agent:    str   # For step tracking

    # Tool loop
    next_action:      str   # "execute_tool" | "producer" | ""


# ─────────────────────────────────────────────────────────────────────────────
#  LLM FACTORY
# ─────────────────────────────────────────────────────────────────────────────

def get_llm(model_id: str, temperature: float = 0.3):
    """Select the LLM based on model_id from the Flutter dropdown."""
    mid = model_id.lower()

    if "groq" in mid:
        model_name = model_id.split("/")[-1]
        return ChatGroq(
            model_name=model_name,
            temperature=temperature,
            groq_api_key=os.environ.get("GROQ_API_KEY", "")
        )

    elif "gemini" in mid:
        return ChatGoogleGenerativeAI(
            model=model_id,
            temperature=temperature,
            google_api_key=os.environ.get("GOOGLE_API_KEY", "")
        )

    elif "openai" in mid or "anthropic" in mid or "deepseek" in mid:
        return ChatOpenAI(
            model=model_id,
            temperature=temperature,
            openai_api_key=os.environ.get("OPENROUTER_API_KEY", ""),
            openai_api_base="https://openrouter.ai/api/v1",
        )

    else:
        # Fallback: fast Groq model
        return ChatGroq(
            model_name="llama-3.1-8b-instant",
            temperature=temperature,
            groq_api_key=os.environ.get("GROQ_API_KEY", "")
        )

def get_fast_llm():
    """A fast, lightweight LLM used for Supervisor/Reviewer decisions."""
    return ChatGroq(
        model_name="llama-3.1-8b-instant",
        temperature=0.0,
        groq_api_key=os.environ.get("GROQ_API_KEY", "")
    )

# ─────────────────────────────────────────────────────────────────────────────
#  NODE 1: THINKER
#  Role: Deep reasoning, problem solving, initial draft generation
# ─────────────────────────────────────────────────────────────────────────────

THINKER_SYSTEM = """You are the QuantCore THINKER — the deep reasoning engine.
Your job is to analyze the user's request thoroughly and produce an initial comprehensive draft answer.

Guidelines:
- Think step-by-step for complex problems (math, code, research, personal issues).
- Be exhaustive in your reasoning — do NOT cut corners.
- Do not produce a final polished answer; this is a DRAFT for review.
- For code: generate complete, working code with comments.
- For personal/emotional queries: be empathetic, thoughtful, and suggest practical steps.
- For math: show full working and verify your calculation.
- For research: summarize findings clearly with key points.
- If reviewer feedback is included below, use it to correct your previous draft.
"""

async def thinker_node(state: AgentState) -> AgentState:
    llm = get_llm(state["model_id"], temperature=0.4)

    # Build messages including any reviewer feedback for self-correction
    context_messages = list(state["messages"])
    if state.get("reviewer_notes") and state.get("retry_count", 0) > 0:
        context_messages.append(
            HumanMessage(content=(
                f"REVIEWER FEEDBACK (your previous draft had issues):\n"
                f"{state['reviewer_notes']}\n\n"
                f"Previous draft:\n{state.get('thinker_draft', '')}\n\n"
                f"Please revise your answer based on this feedback."
            ))
        )

    mode = state.get("mode", "drive").lower()
    mode_instructions = {
        "drive": "MODE: DRIVE. Provide a very short, concise, and direct answer. Be brief. Skip elaborate explanations unless explicitly asked.",
        "fly": "MODE: FLY. Provide a detailed, well-structured answer. Balance depth with readability.",
        "jet": "MODE: JET. Provide an extremely comprehensive, deeply researched, and highly technical answer. Explore edge cases and advanced concepts."
    }
    system_prompt = f"{THINKER_SYSTEM}\n\n{mode_instructions.get(mode, mode_instructions['drive'])}"

    prompt = ChatPromptTemplate.from_messages([
        ("system", system_prompt),
        MessagesPlaceholder(variable_name="messages"),
    ])
    chain = prompt | llm
    response = await chain.ainvoke({"messages": context_messages})

    return {
        **state,
        "thinker_draft": response.content,
        "current_agent": "thinker",
    }

# ─────────────────────────────────────────────────────────────────────────────
#  NODE 2: REVIEWER
#  Role: Quality control — checks for errors, accuracy, completeness
# ─────────────────────────────────────────────────────────────────────────────

REVIEWER_SYSTEM = """You are the QuantCore REVIEWER — the quality control agent.
Your job is to critically evaluate the Thinker's draft and identify any issues.

Evaluate for:
1. Factual accuracy and logical correctness
2. Code correctness (syntax errors, logical bugs, edge cases)
3. Mathematical accuracy (verify calculations)
4. Completeness (did it fully address the user's request?)
5. Clarity and helpfulness

Respond in this EXACT format:
VERDICT: approve | revise | use_tools
NOTES: <your specific feedback, or "All good." if approving>

- Use "approve" if the draft is accurate and complete.
- Use "revise" if there are factual errors, logical issues, or significant gaps.
- Use "use_tools" if the query needs live web data, math calculation, or file creation.
"""

async def reviewer_node(state: AgentState) -> AgentState:
    llm = get_fast_llm()

    original_query = state["messages"][0].content if state["messages"] else ""

    prompt = ChatPromptTemplate.from_messages([
        ("system", REVIEWER_SYSTEM),
        ("human", (
            f"ORIGINAL USER QUERY:\n{original_query}\n\n"
            f"THINKER'S DRAFT:\n{state.get('thinker_draft', '')}\n\n"
            f"Please evaluate this draft."
        )),
    ])
    chain = prompt | llm
    response = await chain.ainvoke({})

    raw = response.content.strip()
    verdict = "approve"
    notes = "All good."

    for line in raw.split("\n"):
        if line.startswith("VERDICT:"):
            v = line.replace("VERDICT:", "").strip().lower()
            if v in ["approve", "revise", "use_tools"]:
                verdict = v
        elif line.startswith("NOTES:"):
            notes = line.replace("NOTES:", "").strip()

    return {
        **state,
        "reviewer_verdict": verdict,
        "reviewer_notes": notes,
        "current_agent": "reviewer",
    }

# ─────────────────────────────────────────────────────────────────────────────
#  NODE 3: SUPERVISOR
#  Role: Final gatekeeper — approves, retries, or dispatches tools
# ─────────────────────────────────────────────────────────────────────────────

MAX_RETRIES = 2

async def supervisor_node(state: AgentState) -> AgentState:
    """
    Reads the Reviewer's verdict and decides:
    - approve    → pass to Producer
    - revise     → send back to Thinker (up to MAX_RETRIES)
    - use_tools  → execute tools, then pass to Producer
    """
    verdict = state.get("reviewer_verdict", "approve")
    retry_count = state.get("retry_count", 0)

    if verdict == "use_tools":
        decision = "use_tools"
    elif verdict == "revise" and retry_count < MAX_RETRIES:
        decision = "retry_thinker"
    else:
        # If max retries reached or approved, move forward
        decision = "approve"

    return {
        **state,
        "supervisor_decision": decision,
        "retry_count": retry_count + (1 if decision == "retry_thinker" else 0),
        "current_agent": "supervisor",
    }

# ─────────────────────────────────────────────────────────────────────────────
#  NODE: TOOL EXECUTOR
#  Role: Runs tools requested by the pipeline (search, math, file creation)
# ─────────────────────────────────────────────────────────────────────────────

async def tool_executor_node(state: AgentState) -> AgentState:
    """
    Uses the selected model to bind tools and execute them based on the query.
    After execution, result is passed to Producer.
    """
    llm = get_llm(state["model_id"], temperature=0.1)
    tools = get_tools()

    try:
        llm_with_tools = llm.bind_tools(tools)
    except Exception:
        # Some models don't support tool binding — fallback gracefully
        return {
            **state,
            "thinker_draft": state.get("thinker_draft", "") + "\n\n[Tools unavailable for this model.]",
            "next_action": "producer",
            "current_agent": "tool_executor",
        }

    original_query = state["messages"][0].content if state["messages"] else ""
    prompt = ChatPromptTemplate.from_messages([
        ("system", (
            "You are a tool-use agent. The user needs live data, math calculations, or file creation. "
            "Use the appropriate tools to gather the necessary information. "
            "After using tools, summarize what you found."
        )),
        ("human", original_query),
    ])

    chain = prompt | llm_with_tools

    try:
        response = await chain.ainvoke({})

        # Execute tool calls if any
        tool_map = {t.name: t for t in tools}
        tool_results = []

        if hasattr(response, "tool_calls") and response.tool_calls:
            for tool_call in response.tool_calls:
                tool_fn = tool_map.get(tool_call["name"])
                if tool_fn:
                    try:
                        result = await tool_fn.ainvoke(tool_call["args"])
                        tool_results.append(f"[{tool_call['name']}]: {result}")
                    except Exception as e:
                        tool_results.append(f"[{tool_call['name']}]: Error - {str(e)}")

        tool_summary = "\n".join(tool_results) if tool_results else response.content

        # Merge tool result into the thinker draft
        updated_draft = (
            state.get("thinker_draft", "") +
            f"\n\n--- Tool Results ---\n{tool_summary}"
        )
    except Exception as e:
        updated_draft = state.get("thinker_draft", "") + f"\n\n[Tool execution error: {e}]"

    return {
        **state,
        "thinker_draft": updated_draft,
        "next_action": "producer",
        "current_agent": "tool_executor",
    }

# ─────────────────────────────────────────────────────────────────────────────
#  NODE 4: PRODUCER
#  Role: Polish and format the final answer for display in the Flutter app
# ─────────────────────────────────────────────────────────────────────────────

PRODUCER_SYSTEM = """You are the QuantCore PRODUCER — the final output formatter.
Your job is to transform the verified draft into a beautifully formatted, user-ready response.

Guidelines:
- Format the response clearly using Markdown where appropriate.
- Use headers (##), bullet points, code blocks (```), and bold text for clarity.
- Be concise but complete — remove redundant reasoning, keep only the answer.
- For code: wrap in ```language``` blocks.
- For math: present the result clearly with steps.
- For personal/emotional responses: be warm, empathetic, and end with encouragement.
- Always respond in a helpful, professional, and friendly tone.
- Do NOT add meta-commentary like "Here is my revised answer" — just give the answer directly.
"""

async def producer_node(state: AgentState) -> AgentState:
    llm = get_llm(state["model_id"], temperature=0.2)

    original_query = state["messages"][0].content if state["messages"] else ""

    prompt = ChatPromptTemplate.from_messages([
        ("system", PRODUCER_SYSTEM),
        ("human", (
            f"ORIGINAL USER REQUEST:\n{original_query}\n\n"
            f"VERIFIED DRAFT (from Thinker + Tools):\n{state.get('thinker_draft', '')}\n\n"
            f"Please produce the final, polished response for the user."
        )),
    ])

    chain = prompt | llm
    response = await chain.ainvoke({})

    return {
        **state,
        "final_output": response.content,
        "current_agent": "producer",
    }

# ─────────────────────────────────────────────────────────────────────────────
#  ROUTING LOGIC
# ─────────────────────────────────────────────────────────────────────────────

def supervisor_router(state: AgentState) -> str:
    decision = state.get("supervisor_decision", "approve")
    if decision == "retry_thinker":
        return "thinker"
    elif decision == "use_tools":
        return "tool_executor"
    else:
        return "producer"

# ─────────────────────────────────────────────────────────────────────────────
#  GRAPH CONSTRUCTION
# ─────────────────────────────────────────────────────────────────────────────

def build_graph():
    workflow = StateGraph(AgentState)

    workflow.add_node("thinker",       thinker_node)
    workflow.add_node("reviewer",      reviewer_node)
    workflow.add_node("supervisor",    supervisor_node)
    workflow.add_node("tool_executor", tool_executor_node)
    workflow.add_node("producer",      producer_node)

    workflow.set_entry_point("thinker")

    # Thinker → Reviewer → Supervisor
    workflow.add_edge("thinker", "reviewer")
    workflow.add_edge("reviewer", "supervisor")

    # Supervisor routes: retry to Thinker, use tools, or approve to Producer
    workflow.add_conditional_edges(
        "supervisor",
        supervisor_router,
        {
            "thinker":       "thinker",
            "tool_executor": "tool_executor",
            "producer":      "producer",
        }
    )

    # Tool executor always → Producer
    workflow.add_edge("tool_executor", "producer")

    # Producer is the terminal node
    workflow.add_edge("producer", END)

    return workflow.compile()


graph = build_graph()


# ─────────────────────────────────────────────────────────────────────────────
#  PUBLIC ENTRY POINT (called from main.py)
# ─────────────────────────────────────────────────────────────────────────────

async def run_agent_graph(
    query: str,
    model_id: str,
    mode: str = "drive",
    conversation_id: str = "default",
    user_id: str = "guest_user",
    is_guest: bool = True,
) -> dict:
    """
    Run the 4-agent pipeline for the given query.
    Returns the final polished output and a list of pipeline steps for the UI.
    Guest users are fully supported — the pipeline runs identically;
    only the caller (main.py) decides whether to persist to a database.
    """
    mode_tag = "[GUEST]" if is_guest else f"[USER:{user_id[:8]}]"
    print(f"   🔄 {mode_tag} Pipeline starting → model={model_id}")

    initial_state: AgentState = {
        "messages":            [HumanMessage(content=query)],
        "model_id":            model_id,
        "mode":                mode,
        "thinker_draft":       "",
        "reviewer_verdict":    "",
        "reviewer_notes":      "",
        "supervisor_decision": "",
        "final_output":        "",
        "retry_count":         0,
        "current_agent":       "thinker",
        "next_action":         "",
    }

    result = await graph.ainvoke(initial_state)

    retry_count = result.get("retry_count", 0)
    steps = [
        "🧠 Thinker: Reasoning complete",
        "🔍 Reviewer: Quality check done",
        f"🎯 Supervisor: {'Self-corrected' if retry_count > 0 else 'Approved on first pass'}",
        "✨ Producer: Final answer ready",
    ]
    if result.get("current_agent") == "tool_executor" or "Tool Results" in result.get("thinker_draft", ""):
        steps.insert(2, "🔧 Tools: Executed successfully")

    if is_guest:
        steps.append("👤 Mode: Guest session (sign in to save history)")

    return {
        "output": result.get("final_output", "⚠️ Pipeline error — no output produced."),
        "steps":  steps,
    }
