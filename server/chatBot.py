import os
import google.generativeai as genai
from dotenv import load_dotenv

# Load API key from .env file
load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")

if not api_key:
    raise ValueError("API Key not found. Make sure .env file contains GEMINI_API_KEY")

# Configure Gemini with your API key
genai.configure(api_key=api_key)

# Define a custom system prompt to stay focused on healthcare/mental health
system_prompt = (
    "You are a friendly and professional healthcare assistant specialized in both physical and mental health. "
    "Always keep your responses aligned with medical support, wellness advice, and mental health awareness. "
    "Ask follow-up questions like a compassionate doctor — such as symptoms, duration, pain level, emotional impact, and previous treatments. "
    "Avoid discussing any topic outside of healthcare and well-being. Always be empathetic and supportive."
)

# Load the correct chat-compatible model
model = genai.GenerativeModel(model_name="gemini-2.0-flash")

# Start a chat session with the system instruction
chat = model.start_chat(history=[
    {
        "role": "user",
        "parts": [system_prompt]
    }
])

print("🩺 Mental Health Assistant Started (type 'exit' to quit)\n")

# Simple loop for chatting
while True:
    user_input = input("You: ")
    if user_input.lower() in ["exit", "quit"]:
        print("👋 Session ended. Take care!")
        break

    try:
        response = chat.send_message(user_input)
        print("\nGemini:", response.text.strip(), "\n")
    except Exception as e:
        print("❌ Error:", e)
