import os
import asyncio
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage
load_dotenv()

async def test():
    key = os.environ.get("OPENROUTER_API_KEY", "")
    llm = ChatOpenAI(
        model="cohere/north-mini-code:free",
        temperature=0.3,
        openai_api_key=key,
        openai_api_base="https://openrouter.ai/api/v1",
        max_tokens=200
    )
    print("Sending message...")
    try:
        response = await llm.ainvoke([HumanMessage(content="hi")])
        print("Response received:")
        print(" - Content:", repr(response.content))
        print(" - Additional kwargs:", response.additional_kwargs)
    except Exception as e:
        print("Exception:", e)

asyncio.run(test())
