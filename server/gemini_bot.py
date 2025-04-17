import os
import google.generativeai as genai
from dotenv import load_dotenv


load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")

if not api_key:
    raise ValueError("API Key not found. Check your .env file")

genai.configure(api_key=api_key)

# Create the model with system prompt
system_prompt = (
    "You are a friendly and professional healthcare assistant specialized in both physical and mental health. "
    "Always keep your responses aligned with medical support, wellness advice, and mental health awareness. "
    "Ask follow-up questions like a compassionate doctor — such as symptoms, duration, pain level, emotional impact, and previous treatments. "
    "Avoid discussing any topic outside of healthcare and well-being. Always be empathetic and supportive."
)

model = genai.GenerativeModel(model_name="gemini-2.0-pro")

chat_sessions = {}

def get_chat_session(user_id):
    if user_id not in chat_sessions:
        chat_sessions[user_id] = model.start_chat(history=[
            {"role": "user", "parts": [system_prompt]}
        ])
    return chat_sessions[user_id]

def get_gemini_response(user_id, message):
    chat = get_chat_session(user_id)
    response = chat.send_message(message)
    return response.text.strip()
