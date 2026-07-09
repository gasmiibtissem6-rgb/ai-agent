from models.groq_provider import ask_model
from models.deepseek_provider import ask_deepseek
from models.gemini_provider import ask_gemini

def route_to_model(role: str, message: str) -> str:
    """Route la demande vers le bon modèle selon le rôle."""
    if role == "deepseek":
        return ask_deepseek(message)
    if role == "gemini":
        return ask_gemini(message)
    return ask_model(role, message)
