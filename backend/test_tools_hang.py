import os
import asyncio
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage
from agent.tools import get_tools
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
    tools = get_tools()
    try:
        print("Binding tools...")
        llm_with_tools = llm.bind_tools(tools)
        print("Sending message with tools bound...")
        response = await llm_with_tools.ainvoke([HumanMessage(content="hi")])
        print("Response received!")
        print("Content bytes:", response.content.encode('ascii', 'backslashreplace'))
        print("Has tool calls:", hasattr(response, "tool_calls") and len(response.tool_calls) > 0)
    except Exception as e:
        print("Exception:", e)

asyncio.run(test())
