import os
import re
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

client = OpenAI(
    api_key=os.getenv("GROQ_API_KEY"),
    base_url="https://api.groq.com/openai/v1",
)

MODELS = {
    "reasoning": "qwen/qwen3.6-27b",
    "contract": "qwen/qwen3-32b",
    "chat": "llama-3.3-70b-versatile",
}

def ask_model(role: str, message: str) -> str:
    """Envoie un message à un modèle Groq et retourne sa réponse (sans le raisonnement interne)."""
    model = MODELS.get(role, MODELS["chat"])
    response = client.chat.completions.create(
        model=model,
        messages=[{"role": "user", "content": message}],
    )
    raw_reply = response.choices[0].message.content
    clean_reply = re.sub(r"<think>.*?</think>", "", raw_reply, flags=re.DOTALL).strip()
    return clean_reply
