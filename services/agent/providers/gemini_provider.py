import os
from dotenv import load_dotenv
from google import genai

load_dotenv()

client = genai.Client(api_key=os.getenv("GOOGLE_API_KEY"))

def ask_gemini(message: str) -> str:
    """Envoie un message texte à Gemini et retourne sa réponse."""
    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=message,
    )
    return response.text

def ask_gemini_image(image_path: str, prompt: str = "Décris cette image et extrais tout le texte visible.") -> str:
    """Envoie une image à Gemini (vision) et retourne son analyse."""
    uploaded_file = client.files.upload(file=image_path)
    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=[uploaded_file, prompt],
    )
    return response.text
