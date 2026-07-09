import os
from typing import Optional
from dotenv import load_dotenv
from openai import AsyncOpenAI
from providers.base import BaseProvider

load_dotenv()


class OpenAIProvider(BaseProvider):
    name = "openai"

    def __init__(self):
        self.api_key = os.getenv("OPENAI_API_KEY")
        self.client = AsyncOpenAI(api_key=self.api_key) if self.api_key else None

    def is_configured(self) -> bool:
        return bool(self.api_key)

    async def generate(self, prompt: str, system: Optional[str] = None) -> str:
        if not self.client:
            raise RuntimeError("OpenAI provider non configuré (clé manquante).")

        messages = []
        if system:
            messages.append({"role": "system", "content": system})
        messages.append({"role": "user", "content": prompt})

        response = await self.client.chat.completions.create(
            model="gpt-4o-mini",
            messages=messages,
        )

        return response.choices[0].message.content
