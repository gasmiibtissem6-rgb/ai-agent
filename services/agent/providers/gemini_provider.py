import asyncio
import os

from dotenv import load_dotenv
from google import genai

load_dotenv()


def get_client() -> genai.Client:
    """
    Crée le client Gemini uniquement lorsqu'une requête est envoyée.
    Cela évite les erreurs au démarrage si la clé API est absente.
    """
    api_key = os.getenv("GOOGLE_API_KEY") or os.getenv("GEMINI_API_KEY")

    if not api_key:
        raise RuntimeError(
            "La variable GOOGLE_API_KEY ou GEMINI_API_KEY "
            "n'est pas configurée."
        )

    return genai.Client(api_key=api_key)


def ask_gemini(message: str) -> str:
    """
    Envoie un message texte à Gemini et retourne sa réponse.
    """
    client = get_client()

    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=message,
    )

    return response.text or ""


def ask_gemini_image(
    image_path: str,
    prompt: str = (
        "Décris cette image et extrais tout le texte visible."
    ),
) -> str:
    """
    Envoie une image à Gemini et retourne son analyse.
    """
    client = get_client()

    uploaded_file = client.files.upload(
        file=image_path,
    )

    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=[
            uploaded_file,
            prompt,
        ],
    )

    return response.text or ""


class GeminiProvider:
    """
    Provider Gemini compatible avec AgentRouter.
    """

    def is_configured(self) -> bool:
        return bool(
            os.getenv("GOOGLE_API_KEY")
            or os.getenv("GEMINI_API_KEY")
        )

    async def generate(
        self,
        prompt: str,
        system: str | None = None,
    ) -> str:
        """
        Génère une réponse Gemini.

        ask_gemini est synchrone, donc asyncio.to_thread
        évite de bloquer FastAPI.
        """
        final_prompt = prompt

        if system:
            final_prompt = (
                f"Instructions système :\n{system}\n\n"
                f"Demande utilisateur :\n{prompt}"
            )

        return await asyncio.to_thread(
            ask_gemini,
            final_prompt,
        )
