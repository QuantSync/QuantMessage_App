import requests
import json

URL = "http://127.0.0.1:8000/api/v1/chat"

def test_chat(message: str):
    print(f"\n--- Sending Query ---")
    print(message)
    try:
        response = requests.post(URL, json={
            "message": message,
            "model_id": "groq/llama3-8b-8192",  # Using a fast default model
            "conversation_id": "test_session",
            "user_id": "test_user"
        })
        if response.status_code == 200:
            data = response.json()
            print("\n--- Response ---")
            print(data["response"])
            print("\n--- Steps ---")
            print(data["agent_steps"])
        else:
            print(f"Error: {response.status_code}")
            print(response.text)
    except Exception as e:
        print(f"Connection Error: {e}")

if __name__ == "__main__":
    queries = [
        "I'm feeling really anxious about my exams tomorrow. I can't focus.",
        "Can you generate an image of a futuristic city in the clouds?",
        "Please write a quick python script to sort an array and save it as sorted.md",
        "Calculate the square root of 144 and multiply it by 15"
    ]
    
    for q in queries:
        test_chat(q)
