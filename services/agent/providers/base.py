from abc import ABC, abstractmethod
from typing import Optional


class BaseProvider(ABC):
    """Interface commune que chaque provider (OpenAI, Claude, Gemini, Mistral) doit respecter."""

    name: str = "base"

    @abstractmethod
    def is_configured(self) -> bool:
        """Retourne True si la clé API est présente."""
        raise NotImplementedError

    @abstractmethod
    async def generate(self, prompt: str, system: Optional[str] = None) -> str:
        """Envoie le prompt au modèle et retourne la réponse texte."""
        raise NotImplementedError
