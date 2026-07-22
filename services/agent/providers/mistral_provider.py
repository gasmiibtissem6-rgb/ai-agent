import os
from typing import Optional
from dotenv import load_dotenv
from mistralai.client import Mistral
from providers.base import BaseProvider

load_dotenv()


class MistralProvider(BaseProvider):
    name = "mistral"

    def __init__(self):
        self.api_key = os.getenv("MISTRAL_API_KEY")
        self.client = Mistral(api_key=self.api_key) if self.api_key else None

    def is_configured(self) -> bool:
        return bool(self.api_key)

    async def generate(self, prompt: str, system: Optional[str] = None) -> str:
        if not self.client:
            raise RuntimeError("Mistral provider non configuré (clé manquante).")

        messages = []

        if system:
            messages.append({"role": "system", "content": system})

        messages.append({"role": "user", "content": prompt})

        response = await self.client.chat.complete_async(
            model="mistral-small-latest",
            messages=messages,
        )

        return response.choices[0].message.content
