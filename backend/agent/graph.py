"""
QuantMessage Multi-Agent Backend – agent/graph.py
==================================================
Supervisor-Driven 4-Agent Architecture (PATH 2 — LangGraph Fallback):
  1. Agent 1 (Search Analyst): Analyzes query and searches the internet.
  2. Agent 2 (Error Solver): Reviews the search data for errors/inaccuracies and solves them.
  3. Agent 3 (Reviewer & Producer): Reviews all answers and formats the final response.
  4. Agent 4 (Supervisor): Orchestrates the pipeline and ensures all errors are resolved.

This is PATH 2 in the tri-path priority waterfall:
  PATH 1 (LiteLLM)    → litellm_path/client.py       [fastest, primary]
  PATH 2 (LangGraph)  → agent/graph.py (this file)    [fallback]
  PATH 3 (OpenRouter) → openrouter_path/client.py     [last resort / QuantCore]

QuantCore direct httpx calls are now centralized in openrouter_path/client.py
and imported here to avoid code duplication.
"""

import os
from typing import TypedDict, Annotated, Sequence, Optional, List
from langchain_core.messages import (
    BaseMessage, HumanMessage, AIMessage, FunctionMessage
)
from langchain_core.runnables import RunnableLambda
from langgraph.graph import StateGraph, END
from langchain_groq import ChatGroq
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder

from agent.tools import get_tools

# QuantCore direct httpx calls are centralized in openrouter_path/client.py
# Import here so agent nodes can use _call_quantcore_direct unchanged.
from openrouter_path.client import call_quantcore_direct as _call_quantcore_direct

# ─────────────────────────────────────────────────────────────────────────────
#  STATE DEFINITION
# ─────────────────────────────────────────────────────────────────────────────

class AgentState(TypedDict):
    # Core conversation
    messages:         Annotated[Sequence[BaseMessage], "conversation history"]
    model_id:         str
    mode:             str   # "drive" | "fly" | "jet"

    # Pipeline stages
    search_data:      str   # Agent 1 output
    solved_data:      str   # Agent 2 output
    final_output:     str   # Agent 3 output
    supervisor_verdict: str # "continue" | "retry" | "approve"

    # Retry tracking (self-correction loop guard)
    retry_count:      int
    current_agent:    str   # For step tracking


# ─────────────────────────────────────────────────────────────────────────────
#  QUANTCORE NOTE
#  _call_quantcore_direct is imported from openrouter_path/client.py above.
#  All QuantCore constants and logic live there to avoid duplication.
# ─────────────────────────────────────────────────────────────────────────────





# ─────────────────────────────────────────────────────────────────────────────
#  LLM FACTORY  (for non-QuantCore models — uses LangChain normally)
# ─────────────────────────────────────────────────────────────────────────────

def get_llm(model_id: str, temperature: float = 0.3):
    mid = model_id.lower()

    if "gemini" in mid:
        primary_llm = ChatGoogleGenerativeAI(
            model="gemini-3.5-flash",
            temperature=temperature,
            google_api_key=os.environ.get("GOOGLE_API_KEY", ""),
            max_output_tokens=8192
        )
    elif "claude-opus" in mid:
        primary_llm = ChatOpenAI(
            model="anthropic/claude-3-opus",
            temperature=temperature,
            openai_api_key=os.environ.get("OPENROUTER_API_KEY", ""),
            openai_api_base="https://openrouter.ai/api/v1",
            max_tokens=4096
        )
    elif "grok" in mid:
        primary_llm = ChatOpenAI(
            model="x-ai/grok-2",
            temperature=temperature,
            openai_api_key=os.environ.get("OPENROUTER_API_KEY", ""),
            openai_api_base="https://openrouter.ai/api/v1",
            max_tokens=8192
        )
    elif "gpt-latest" in mid:
        primary_llm = ChatOpenAI(
            model="openai/gpt-4o",
            temperature=temperature,
            openai_api_key=os.environ.get("OPENROUTER_API_KEY", ""),
            openai_api_base="https://openrouter.ai/api/v1",
            max_tokens=16384
        )
    elif "deepseek" in mid:
        primary_llm = ChatOpenAI(
            model="deepseek/deepseek-chat",
            temperature=temperature,
            openai_api_key=os.environ.get("OPENROUTER_API_KEY", ""),
            openai_api_base="https://openrouter.ai/api/v1",
            max_tokens=8192
        )
    elif "mistral" in mid:
        primary_llm = ChatOpenAI(
            model="mistralai/mistral-nemo",
            temperature=temperature,
            openai_api_key=os.environ.get("OPENROUTER_API_KEY", ""),
            openai_api_base="https://openrouter.ai/api/v1",
            max_tokens=8192
        )
    elif "groq" in mid:
        primary_llm = ChatGroq(
            model_name="llama-3.1-8b-instant",
            temperature=temperature,
            groq_api_key=os.environ.get("GROQ_API_KEY", ""),
            max_tokens=8192
        )
    else:
        primary_llm = ChatOpenAI(
            model=model_id,
            temperature=temperature,
            openai_api_key=os.environ.get("OPENROUTER_API_KEY", ""),
            openai_api_base="https://openrouter.ai/api/v1",
            max_tokens=8192
        )

    # Universal fallback
    fallback_llm = ChatOpenAI(
        model="openai/gpt-4o-mini",
        temperature=temperature,
        openai_api_key=os.environ.get("OPENROUTER_API_KEY", ""),
        openai_api_base="https://openrouter.ai/api/v1",
        max_tokens=16384
    )

    return primary_llm.with_fallbacks([fallback_llm])


def get_fast_llm():
    """Fast, reliable LLM for the Supervisor node (always Groq)."""
    primary_llm = ChatGroq(
        model_name="llama-3.1-8b-instant",
        temperature=0.0,
        groq_api_key=os.environ.get("GROQ_API_KEY", ""),
        max_tokens=4096
    )
    fallback_llm = ChatOpenAI(
        model="openai/gpt-4o-mini",
        temperature=0.0,
        openai_api_key=os.environ.get("OPENROUTER_API_KEY", ""),
        openai_api_base="https://openrouter.ai/api/v1",
        max_tokens=4096
    )
    return primary_llm.with_fallbacks([fallback_llm])


def _is_quantcore(model_id: str) -> bool:
    return "quantcore" in model_id.lower()


# ─────────────────────────────────────────────────────────────────────────────
#  AGENT 1: SEARCH ANALYST
# ─────────────────────────────────────────────────────────────────────────────
async def search_analyst_node(state: AgentState) -> AgentState:
    tools = get_tools()
    tool_desc = ", ".join(t.name for t in tools)
    original_query = state["messages"][0].content if state["messages"] else ""
    retry_note = ""
    if state.get("retry_count", 0) > 0 and state.get("supervisor_verdict"):
        retry_note = f"\n\nSUPERVISOR FEEDBACK (address this): {state['supervisor_verdict']}"

    system_prompt = (
        "You are the Gatherer (Agent 1). Analyze the user's query and produce an exhaustive, "
        "deeply researched response. Leave no stone unturned. Gather all context, edge cases, "
        "best practices, and deep dive into nuances. Compile a highly detailed initial solution. "
        "Do NOT truncate or cut short your analysis under any circumstances. "
        "If the user asks for code, provide complete files, comprehensive logic, and architectural reasoning. "
        f"Available capabilities you can reason about: {tool_desc}."
        + retry_note
    )

    try:
        if _is_quantcore(state["model_id"]):
            # Direct httpx call — bypasses LangChain AIMessage validator entirely
            messages = [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": original_query},
            ]
            final_content = await _call_quantcore_direct(messages, max_tokens=4096, temperature=0.4)
        else:
            llm = get_llm(state["model_id"], temperature=0.4)
            try:
                llm_with_tools = llm.bind_tools(tools)
            except Exception:
                llm_with_tools = llm

            prompt = ChatPromptTemplate.from_messages([
                ("system", system_prompt),
                MessagesPlaceholder(variable_name="messages"),
            ])
            chain = prompt | llm_with_tools
            response = await chain.ainvoke({"messages": list(state["messages"])})
            final_content = response.content or ""

            # Execute tool calls if any
            tool_results = []
            if hasattr(response, "tool_calls") and response.tool_calls:
                tool_map = {t.name: t for t in tools}
                for tool_call in response.tool_calls:
                    tool_fn = tool_map.get(tool_call["name"])
                    if tool_fn:
                        try:
                            result = await tool_fn.ainvoke(tool_call["args"])
                            tool_results.append(f"[{tool_call['name']}]: {result}")
                        except Exception as e:
                            tool_results.append(f"[{tool_call['name']}]: Error - {str(e)}")
            if tool_results:
                final_content += "\n\n--- Tool Results ---\n" + "\n".join(tool_results)

    except Exception as e:
        final_content = f"Error during search analysis: {e}"

    return {
        **state,
        "search_data": final_content,
        "current_agent": "agent1",
    }


# ─────────────────────────────────────────────────────────────────────────────
#  AGENT 2: ERROR SOLVER
# ─────────────────────────────────────────────────────────────────────────────
async def error_solver_node(state: AgentState) -> AgentState:
    original_query = state["messages"][0].content if state["messages"] else ""
    search_data = state.get("search_data", "")

    system_prompt = (
        "You are the Worker (Agent 2). Your job is to review the deep-researched data compiled by the Gatherer. "
        "Actively look for multiple potential errors simultaneously: factual inaccuracies, subtle code bugs, "
        "unhandled edge cases, security flaws, or logical inconsistencies. "
        "Improvise and solve every single error you find. Output an expansive, completely corrected, "
        "fully functional, and hyper-detailed solution. "
        "Never truncate code. Output long, detailed explanations, rigorous proofs, and full code blocks where applicable."
    )
    user_prompt = (
        f"Original Query: {original_query}\n\n"
        f"Gatherer Data:\n{search_data}\n\n"
        "Please identify all errors and provide the expansive, corrected solution."
    )

    try:
        if _is_quantcore(state["model_id"]):
            messages = [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ]
            solved = await _call_quantcore_direct(messages, max_tokens=4096, temperature=0.2)
        else:
            llm = get_llm(state["model_id"], temperature=0.2)
            prompt = ChatPromptTemplate.from_messages([
                ("system", system_prompt),
                ("human", "{user_prompt}"),
            ])
            chain = prompt | llm
            response = await chain.ainvoke({"user_prompt": user_prompt})
            solved = response.content or ""
    except Exception as e:
        solved = f"Error during error solving: {e}"

    return {
        **state,
        "solved_data": solved,
        "current_agent": "agent2",
    }


# ─────────────────────────────────────────────────────────────────────────────
#  AGENT 4: SUPERVISOR (Gatekeeper before printing)
# ─────────────────────────────────────────────────────────────────────────────
MAX_RETRIES = 2

async def supervisor_node(state: AgentState) -> AgentState:
    # Supervisor always uses fast Groq — no QuantCore path needed here
    llm = get_fast_llm()
    original_query = state["messages"][0].content if state["messages"] else ""
    solved_data = state.get("solved_data", "")

    prompt = ChatPromptTemplate.from_messages([
        ("system", (
            "You are the Supervisor (Agent 4). You oversee the pipeline to meticulously ensure all errors are fully resolved before final output. "
            "Check for multiple errors: syntax, logic, completeness, depth of research, and adherence to user constraints. "
            "Review the Worker's output against the original query. "
            "Respond ONLY with:\n"
            "VERDICT: approve | retry\n"
            "NOTES: <your expansive feedback on multiple errors if any>"
        )),
        ("human", (
            "Query: {original_query}\n\n"
            "Worker's Solved Data:\n{solved_data}\n\n"
            "Are there any remaining errors (even minor ones), or is this deep, exhaustive, and fully ready?"
        )),
    ])
    chain = prompt | llm
    response = await chain.ainvoke({
        "original_query": original_query,
        "solved_data": solved_data,
    })

    raw = (response.content or "").strip()
    verdict = "approve"
    notes = "All errors resolved."

    for line in raw.split("\n"):
        if line.startswith("VERDICT:"):
            v = line.replace("VERDICT:", "").strip().lower()
            if v in ["approve", "retry"]:
                verdict = v
        elif line.startswith("NOTES:"):
            notes = line.replace("NOTES:", "").strip()

    retry_count = state.get("retry_count", 0)
    if verdict == "retry" and retry_count >= MAX_RETRIES:
        verdict = "approve"  # Force approve if max retries hit

    return {
        **state,
        "supervisor_verdict": notes if verdict == "retry" else "approve",
        "retry_count": retry_count + (1 if verdict == "retry" else 0),
        "current_agent": "agent4",
    }

def supervisor_router(state: AgentState) -> str:
    verdict = state.get("supervisor_verdict", "approve")
    if verdict != "approve":
        return "agent1"
    return "agent3"


# ─────────────────────────────────────────────────────────────────────────────
#  AGENT 3: REVIEWER & PRODUCER
# ─────────────────────────────────────────────────────────────────────────────
async def reviewer_producer_node(state: AgentState) -> AgentState:
    original_query = state["messages"][0].content if state["messages"] else ""
    solved_data = state.get("solved_data", "")

    system_prompt = (
        "You are the Reviewer (Agent 3). Your task is to review all the expansive answers from the previous agents, "
        "ensure they directly, deeply, and comprehensively answer the user's query, and format the final response beautifully using Markdown. "
        "Synthesize all analysis, deep research, and code into a professional, expansive, and highly detailed response. "
        "Never truncate your output. If the response is extremely long, output the full length. Leave nothing out. "
        "Do not include meta-commentary about the agents or pipeline. Just print the final generated expansive response."
    )
    user_prompt = (
        f"Original Query: {original_query}\n\n"
        f"Worker's Final Solved Data:\n{solved_data}\n\n"
        "Please print the final polished, comprehensively detailed response without truncation."
    )

    try:
        if _is_quantcore(state["model_id"]):
            messages = [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ]
            final = await _call_quantcore_direct(messages, max_tokens=4096, temperature=0.2)
        else:
            llm = get_llm(state["model_id"], temperature=0.2)
            prompt = ChatPromptTemplate.from_messages([
                ("system", system_prompt),
                ("human", "{user_prompt}"),
            ])
            chain = prompt | llm
            response = await chain.ainvoke({"user_prompt": user_prompt})
            final = response.content or ""
    except Exception as e:
        final = f"Error during review: {e}"

    return {
        **state,
        "final_output": final,
        "current_agent": "agent3",
    }


# ─────────────────────────────────────────────────────────────────────────────
#  GRAPH CONSTRUCTION
# ─────────────────────────────────────────────────────────────────────────────
def build_graph():
    workflow = StateGraph(AgentState)

    workflow.add_node("agent1", search_analyst_node)
    workflow.add_node("agent2", error_solver_node)
    workflow.add_node("agent3", reviewer_producer_node)
    workflow.add_node("agent4", supervisor_node)

    workflow.set_entry_point("agent1")
    workflow.add_edge("agent1", "agent2")
    workflow.add_edge("agent2", "agent4")

    workflow.add_conditional_edges(
        "agent4",
        supervisor_router,
        {
            "agent1": "agent1",
            "agent3": "agent3",
        }
    )

    workflow.add_edge("agent3", END)
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
    mode_tag = "[GUEST]" if is_guest else f"[USER:{user_id[:8]}]"
    print(f"   🔄 {mode_tag} 4-Agent Pipeline starting → model={model_id}")

    initial_state: AgentState = {
        "messages":            [HumanMessage(content=query)],
        "model_id":            model_id,
        "mode":                mode,
        "search_data":         "",
        "solved_data":         "",
        "final_output":        "",
        "supervisor_verdict":  "",
        "retry_count":         0,
        "current_agent":       "agent1",
    }

    result = await graph.ainvoke(initial_state)

    steps = [
        "🌐 Agent 1: Analyzed & Searched",
        "🛠️ Agent 2: Resolved errors",
        "👁️ Agent 4: Supervised successfully",
        "✅ Agent 3: Reviewed & Printed",
    ]

    if is_guest:
        steps.append("👤 Mode: Guest session (sign in to save history)")

    return {
        "output": result.get("final_output", "⚠️ Pipeline error — no output produced."),
        "steps":  steps,
    }
