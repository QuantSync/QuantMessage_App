"""
QuantMessage Multi-Agent Backend – tools.py
============================================
Tools used by the Tool Executor agent in the pipeline.
  • search_web        – DuckDuckGo + Tavily fallback
  • calculate_math    – Safe AST-based math evaluator
  • review_python_code – AST syntax + lint check
  • generate_image    – OpenRouter → OpenAI DALL-E via OpenRouter
  • create_pdf        – fpdf2 PDF generator
  • create_md_file    – Markdown file writer
"""

import os
import ast
import math
import requests
from fpdf import FPDF
from langchain_core.tools import tool
from duckduckgo_search import DDGS


# ─────────────────────────────────────────────────────────────────────────────
#  WEB SEARCH  (DuckDuckGo first, Tavily fallback)
# ─────────────────────────────────────────────────────────────────────────────

@tool
def search_web(query: str) -> str:
    """Search the web for real-time information, news, or research."""
    # Try DuckDuckGo first (no API key needed)
    try:
        with DDGS() as ddgs:
            results = list(ddgs.text(query, max_results=5))
        if results:
            return "\n\n".join(
                f"**{r['title']}**\n{r['body']}\n🔗 {r['href']}"
                for r in results
            )
    except Exception as ddg_err:
        pass  # Fall through to Tavily

    # Tavily fallback (richer, AI-optimised search)
    tavily_key = os.environ.get("TAVILY_API_KEY", "")
    if tavily_key:
        try:
            resp = requests.post(
                "https://api.tavily.com/search",
                json={"api_key": tavily_key, "query": query, "max_results": 5},
                timeout=15,
            )
            if resp.status_code == 200:
                data = resp.json()
                results = data.get("results", [])
                return "\n\n".join(
                    f"**{r.get('title', '')}**\n{r.get('content', '')}\n🔗 {r.get('url', '')}"
                    for r in results
                )
        except Exception as tav_err:
            return f"Both DuckDuckGo and Tavily failed. Tavily error: {tav_err}"

    return "No search results found and no Tavily key configured."


# ─────────────────────────────────────────────────────────────────────────────
#  MATH CALCULATOR (safe AST eval)
# ─────────────────────────────────────────────────────────────────────────────

@tool
def calculate_math(expression: str) -> str:
    """
    Safely evaluate a mathematical expression.
    Supports all standard math functions (sqrt, sin, cos, log, pi, e, etc.).
    Example: 'math.sqrt(144) * 3 + math.pi'
    """
    allowed_names = {
        k: v for k, v in math.__dict__.items() if not k.startswith("__")
    }
    allowed_names.update({
        "abs": abs, "round": round, "min": min, "max": max, "pow": pow
    })
    try:
        code = compile(expression, "<math_eval>", "eval")
        for name in code.co_names:
            if name not in allowed_names:
                raise NameError(f"'{name}' is not allowed in math expressions.")
        result = eval(code, {"__builtins__": {}}, allowed_names)
        return f"Result: {result}"
    except Exception as e:
        return f"Math evaluation error: {str(e)}"


# ─────────────────────────────────────────────────────────────────────────────
#  CODE REVIEWER (AST-based)
# ─────────────────────────────────────────────────────────────────────────────

@tool
def review_python_code(code: str) -> str:
    """
    Statically analyse a Python code snippet for syntax errors and common issues.
    Pass the complete code as a string.
    """
    try:
        tree = ast.parse(code)
        # Check for common bad patterns
        issues = []
        for node in ast.walk(tree):
            if isinstance(node, ast.Call):
                if isinstance(node.func, ast.Name) and node.func.id == "eval":
                    issues.append("⚠️  Unsafe use of eval() detected.")
            if isinstance(node, ast.Import):
                for alias in node.names:
                    if alias.name == "os" and any(
                        isinstance(n, ast.Attribute) and n.attr == "system"
                        for n in ast.walk(tree)
                    ):
                        issues.append("⚠️  Potentially unsafe os.system() call detected.")

        if issues:
            return "Code parsed OK but has warnings:\n" + "\n".join(issues)
        return "✅ Code is syntactically valid with no obvious issues detected."
    except SyntaxError as e:
        return f"❌ Syntax Error at line {e.lineno}: {e.msg}"
    except Exception as e:
        return f"Unexpected review error: {str(e)}"


# ─────────────────────────────────────────────────────────────────────────────
#  IMAGE GENERATION  (via OpenRouter → dall-e-3)
# ─────────────────────────────────────────────────────────────────────────────

@tool
def generate_image(prompt: str) -> str:
    """
    Generate an AI image for the given text description.
    Uses OpenRouter API to access image generation models.
    """
    api_key = os.environ.get("OPENROUTER_API_KEY", "")
    if not api_key:
        return f"🖼️ [Image placeholder for: '{prompt}'] — Add OPENROUTER_API_KEY to .env to enable real image generation."

    try:
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        }
        # Use OpenRouter's image generation endpoint
        payload = {
            "model": "openai/dall-e-3",
            "prompt": prompt,
            "n": 1,
            "size": "1024x1024",
        }
        resp = requests.post(
            "https://openrouter.ai/api/v1/images/generations",
            headers=headers,
            json=payload,
            timeout=60,
        )
        if resp.status_code == 200:
            url = resp.json()["data"][0]["url"]
            return f"✅ Image generated!\n![Generated Image]({url})"
        else:
            return f"Image generation failed ({resp.status_code}): {resp.text[:300]}"
    except Exception as e:
        return f"Image generation error: {str(e)}"


# ─────────────────────────────────────────────────────────────────────────────
#  PDF GENERATOR (fpdf2)
# ─────────────────────────────────────────────────────────────────────────────

@tool
def create_pdf(text: str, filename: str) -> str:
    """
    Create a PDF document from text content.
    The filename must end with .pdf (e.g., 'research_report.pdf').
    Returns the path to the created file.
    """
    if not filename.endswith(".pdf"):
        filename += ".pdf"
    try:
        os.makedirs("outputs", exist_ok=True)
        filepath = os.path.join("outputs", filename)

        pdf = FPDF()
        pdf.set_auto_page_break(auto=True, margin=15)
        pdf.add_page()
        pdf.set_font("Arial", "B", 16)
        pdf.cell(0, 10, "QuantCore AI — Generated Document", ln=True, align="C")
        pdf.ln(4)
        pdf.set_font("Arial", size=11)

        for line in text.split("\n"):
            safe_line = line.encode("latin-1", "replace").decode("latin-1")
            pdf.multi_cell(0, 8, safe_line)

        pdf.output(filepath)
        return f"✅ PDF created at: `{os.path.abspath(filepath)}`"
    except Exception as e:
        return f"PDF creation failed: {str(e)}"


# ─────────────────────────────────────────────────────────────────────────────
#  MARKDOWN FILE WRITER
# ─────────────────────────────────────────────────────────────────────────────

@tool
def create_md_file(text: str, filename: str) -> str:
    """
    Write a Markdown (.md) file with the given content.
    The filename must end with .md (e.g., 'documentation.md').
    Returns the path to the created file.
    """
    if not filename.endswith(".md"):
        filename += ".md"
    try:
        os.makedirs("outputs", exist_ok=True)
        filepath = os.path.join("outputs", filename)
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(text)
        return f"✅ Markdown file created at: `{os.path.abspath(filepath)}`"
    except Exception as e:
        return f"Markdown file creation failed: {str(e)}"


# ─────────────────────────────────────────────────────────────────────────────
#  TOOL REGISTRY
# ─────────────────────────────────────────────────────────────────────────────

def get_tools():
    """Return all tools available to the multi-agent pipeline."""
    return [
        search_web,
        calculate_math,
        review_python_code,
        generate_image,
        create_pdf,
        create_md_file,
    ]
