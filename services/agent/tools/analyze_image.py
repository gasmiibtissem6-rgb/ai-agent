import os
from models.gemini_provider import ask_gemini_image

def analyze_image(image_path: str) -> str:
    """
    Analyse une image (scan de document, photo, etc.) et en extrait le contenu.
    Utilise Gemini (vision) via Google AI Studio.
    """
    prompt = """Tu es un assistant d'extraction de documents (OCR). Analyse cette image et :
1. Transcris tout le texte visible, aussi fidèlement que possible
2. Indique le type de document si identifiable (contrat, facture, carte d'identité, etc.)
3. Signale si l'image est floue, mal cadrée ou illisible

Réponds en français."""

    result = ask_gemini_image(image_path, prompt)

    if os.path.exists(image_path):
        os.remove(image_path)

    return result
