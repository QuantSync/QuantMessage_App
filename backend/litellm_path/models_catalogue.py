"""
QuantMessage — litellm_path/models_catalogue.py
================================================
Complete curated catalogue of all LiteLLM-supported models available
in the QuantMessage backend.

Model ID format matches LiteLLM's routing convention:
  provider/model-name
  e.g. "groq/llama-3.1-8b-instant", "gemini/gemini-2.0-flash"

OpenRouter models use the prefix "openrouter/" followed by the
OpenRouter model slug: "openrouter/anthropic/claude-3.5-sonnet"

This catalogue is served via GET /api/v1/models so the Flutter
model selector card stays in sync automatically.
"""

# ─────────────────────────────────────────────────────────────────────────────
#  MODEL CATALOGUE
#  Each entry: {id, name, group, description, context_window, free}
# ─────────────────────────────────────────────────────────────────────────────

MODELS_CATALOGUE: list[dict] = [

    # ── QuantCore (special direct httpx path) ────────────────────────────────
    {
        "id":             "quantcore/auto",
        "name":           "QuantCore Auto",
        "group":          "QuantCore",
        "description":    "QuantMessage's proprietary multi-model auto-router. Free. Uses Groq → OpenRouter chain.",
        "context_window": 32768,
        "free":           True,
    },

    # ── Groq (fastest free inference) ───────────────────────────────────────
    {
        "id":             "groq/llama-3.1-8b-instant",
        "name":           "Llama 3.1 8B Instant",
        "group":          "Groq",
        "description":    "Meta's Llama 3.1 8B. Fastest Groq model. Free tier with generous quota.",
        "context_window": 131072,
        "free":           True,
    },
    {
        "id":             "groq/llama-3.3-70b-versatile",
        "name":           "Llama 3.3 70B Versatile",
        "group":          "Groq",
        "description":    "Meta's Llama 3.3 70B. Best quality on Groq. Free tier.",
        "context_window": 131072,
        "free":           True,
    },
    {
        "id":             "groq/llama-3.1-70b-versatile",
        "name":           "Llama 3.1 70B Versatile",
        "group":          "Groq",
        "description":    "Meta's Llama 3.1 70B. High quality, free tier.",
        "context_window": 131072,
        "free":           True,
    },
    {
        "id":             "groq/mixtral-8x7b-32768",
        "name":           "Mixtral 8x7B",
        "group":          "Groq",
        "description":    "Mistral's Mixtral MoE model. Great for reasoning. Free tier.",
        "context_window": 32768,
        "free":           True,
    },
    {
        "id":             "groq/gemma2-9b-it",
        "name":           "Gemma 2 9B IT",
        "group":          "Groq",
        "description":    "Google's Gemma 2 9B instruction-tuned. Compact and capable. Free tier.",
        "context_window": 8192,
        "free":           True,
    },

    # ── Gemini (Google) ──────────────────────────────────────────────────────
    {
        "id":             "gemini/gemini-2.0-flash",
        "name":           "Gemini 2.0 Flash",
        "group":          "Gemini",
        "description":    "Google's latest multimodal model. Fast, capable, generous free quota.",
        "context_window": 1048576,
        "free":           True,
    },
    {
        "id":             "gemini/gemini-2.0-flash-lite",
        "name":           "Gemini 2.0 Flash Lite",
        "group":          "Gemini",
        "description":    "Google's ultra-fast, lightweight Gemini 2.0 variant.",
        "context_window": 1048576,
        "free":           True,
    },
    {
        "id":             "gemini/gemini-1.5-pro",
        "name":           "Gemini 1.5 Pro",
        "group":          "Gemini",
        "description":    "Google's 1M-context pro model. Excellent for long documents.",
        "context_window": 2097152,
        "free":           False,
    },
    {
        "id":             "gemini/gemini-1.5-flash",
        "name":           "Gemini 1.5 Flash",
        "group":          "Gemini",
        "description":    "Google's fast 1M-context model. Free tier.",
        "context_window": 1048576,
        "free":           True,
    },

    # ── OpenRouter — Anthropic ───────────────────────────────────────────────
    {
        "id":             "openrouter/anthropic/claude-3.5-sonnet",
        "name":           "Claude 3.5 Sonnet",
        "group":          "Anthropic (OpenRouter)",
        "description":    "Anthropic's most capable model. Superior reasoning and coding.",
        "context_window": 200000,
        "free":           False,
    },
    {
        "id":             "openrouter/anthropic/claude-3-haiku",
        "name":           "Claude 3 Haiku",
        "group":          "Anthropic (OpenRouter)",
        "description":    "Anthropic's fastest, most compact Claude. Cost-effective.",
        "context_window": 200000,
        "free":           False,
    },

    # ── OpenRouter — OpenAI ──────────────────────────────────────────────────
    {
        "id":             "openrouter/openai/gpt-4o",
        "name":           "GPT-4o",
        "group":          "OpenAI (OpenRouter)",
        "description":    "OpenAI's flagship multimodal model. Best for complex tasks.",
        "context_window": 128000,
        "free":           False,
    },
    {
        "id":             "openrouter/openai/gpt-4o-mini",
        "name":           "GPT-4o Mini",
        "group":          "OpenAI (OpenRouter)",
        "description":    "OpenAI's cost-efficient model. Great balance of speed and quality.",
        "context_window": 128000,
        "free":           False,
    },

    # ── OpenRouter — DeepSeek ────────────────────────────────────────────────
    {
        "id":             "openrouter/deepseek/deepseek-chat",
        "name":           "DeepSeek Chat",
        "group":          "DeepSeek (OpenRouter)",
        "description":    "DeepSeek's latest chat model. Excellent code generation.",
        "context_window": 65536,
        "free":           False,
    },
    {
        "id":             "openrouter/deepseek/deepseek-r1",
        "name":           "DeepSeek R1",
        "group":          "DeepSeek (OpenRouter)",
        "description":    "DeepSeek's reasoning model. Rivals GPT-o1 on benchmarks.",
        "context_window": 65536,
        "free":           False,
    },

    # ── OpenRouter — xAI Grok ───────────────────────────────────────────────
    {
        "id":             "openrouter/x-ai/grok-2",
        "name":           "Grok 2",
        "group":          "xAI (OpenRouter)",
        "description":    "xAI's Grok 2 with real-time X/Twitter knowledge.",
        "context_window": 131072,
        "free":           False,
    },

    # ── OpenRouter — Mistral ─────────────────────────────────────────────────
    {
        "id":             "openrouter/mistralai/mistral-nemo",
        "name":           "Mistral Nemo",
        "group":          "Mistral (OpenRouter)",
        "description":    "Mistral's efficient 12B model. Good multilingual support.",
        "context_window": 131072,
        "free":           False,
    },
    {
        "id":             "openrouter/mistralai/mixtral-8x22b-instruct",
        "name":           "Mixtral 8x22B Instruct",
        "group":          "Mistral (OpenRouter)",
        "description":    "Mistral's large MoE model. Excellent for complex reasoning.",
        "context_window": 65536,
        "free":           False,
    },
]


def get_all_models() -> list[dict]:
    """Return the full model catalogue."""
    return MODELS_CATALOGUE


def get_models_by_group() -> dict[str, list[dict]]:
    """Return models grouped by provider."""
    grouped: dict[str, list[dict]] = {}
    for m in MODELS_CATALOGUE:
        grouped.setdefault(m["group"], []).append(m)
    return grouped


def get_model_ids() -> list[str]:
    """Return just the list of model ID strings."""
    return [m["id"] for m in MODELS_CATALOGUE]


def is_quantcore(model_id: str) -> bool:
    """Returns True if model_id should use the QuantCore/OpenRouter direct path."""
    return model_id.lower().startswith("quantcore/")
