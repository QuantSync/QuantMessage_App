"""
QuantMessage Multi-Agent Backend – main.py
==========================================
FastAPI server — receives requests from the Flutter app,
pre-processes attachments/PDFs, then runs the 4-agent pipeline.

Backend location:  QuantMessage_App/backend/main.py
Run with:          python main.py
                   OR  uvicorn main:app --host 0.0.0.0 --port 8000 --reload
"""

import os
import re
import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

from agent.graph import run_agent_graph
from utils.parsers import parse_pdf_from_url

# ── Load .env keys ─────────────────────────────────────────────────────────
load_dotenv()

# Constant for identifying guest/anonymous users
GUEST_USER_ID = "guest_user"

app = FastAPI(
    title="QuantMessage Multi-Agent Backend",
    description=(
        "4-Agent LangGraph pipeline: Thinker → Reviewer → Supervisor → Producer.\n"
        "Supports Groq, Gemini, OpenRouter models.\n"
        "Features: web search, math, code review, image gen, PDF/MD creation.\n"
        "Guest users are fully supported — their messages are not persisted."
    ),
    version="2.1.0",
)

# Allow the Flutter app (any origin on dev) to call this API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ─────────────────────────────────────────────────────────────────────────────
#  REQUEST / RESPONSE MODELS
# ─────────────────────────────────────────────────────────────────────────────

class ChatRequest(BaseModel):
    message:         str
    model_id:        str   = "groq/llama-3.1-8b-instant"
    conversation_id: str   = "default"
    user_id:         str   = GUEST_USER_ID   # "guest_user" for non-authenticated
    mode:            str   = "drive"         # "drive" | "fly" | "jet"

class ChatResponse(BaseModel):
    response:    str
    agent_steps: list[str] = []
    is_guest:    bool = False   # Frontend can use this to show "Sign in to save history"


# ─────────────────────────────────────────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────────────────────────────────────────

def _is_guest(user_id: str) -> bool:
    """Returns True if the user is not authenticated."""
    return not user_id or user_id.lower() in (GUEST_USER_ID, "anonymous", "")


# ─────────────────────────────────────────────────────────────────────────────
#  ENDPOINTS
# ─────────────────────────────────────────────────────────────────────────────

@app.get("/")
def health():
    return {
        "status":  "🟢 Online",
        "version": "2.1.0",
        "agents":  ["Thinker", "Reviewer", "Supervisor", "Producer"],
        "models":  ["Groq", "Gemini", "OpenRouter"],
        "guest_support": True,
    }


@app.post("/api/v1/chat", response_model=ChatResponse)
async def chat_endpoint(req: ChatRequest):
    try:
        query = req.message.strip()
        if not query:
            raise HTTPException(status_code=400, detail="Message cannot be empty.")

        guest = _is_guest(req.user_id)
        mode  = "GUEST" if guest else f"USER:{req.user_id[:8]}..."
        print(f"\n📩 [{mode}] model={req.model_id} conv={req.conversation_id[:8]}...")
        print(f"   Query: {query[:80]}{'...' if len(query) > 80 else ''}")

        # ── Pre-process PDF/Supabase file URLs embedded in the message ──────
        pdf_pattern = r"(https?://\S+\.pdf\b|https?://\S+supabase\.co\S*\.pdf\S*)"
        pdf_urls = re.findall(pdf_pattern, query, re.IGNORECASE)

        parsed_parts = []
        for url in pdf_urls:
            parsed = parse_pdf_from_url(url)
            parsed_parts.append(
                f"\n\n--- Extracted Document Content ({url}) ---\n{parsed}"
            )

        if parsed_parts:
            query += "".join(parsed_parts)

        # ── Run the 4-agent pipeline ─────────────────────────────────────────
        result = await run_agent_graph(
            query=query,
            model_id=req.model_id,
            mode=req.mode,
            conversation_id=req.conversation_id,
            user_id=req.user_id,
            is_guest=guest,
        )

        print(f"   ✅ Pipeline complete. Steps: {len(result.get('steps', []))}")

        return ChatResponse(
            response=result["output"],
            agent_steps=result.get("steps", []),
            is_guest=guest,
        )

    except HTTPException:
        raise
    except Exception as e:
        print(f"   ❌ Pipeline error: {e}")
        raise HTTPException(status_code=500, detail=f"Pipeline error: {str(e)}")


# ─────────────────────────────────────────────────────────────────────────────
#  ENTRYPOINT
# ─────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    print("\n🚀 QuantMessage Multi-Agent Backend starting...")
    print("   📁 Location: QuantMessage_App/backend/main.py")
    print("   🌐 URL:      http://0.0.0.0:8000")
    print("   📖 Docs:     http://127.0.0.1:8000/docs")
    print("   👤 Guest support: ENABLED\n")
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
