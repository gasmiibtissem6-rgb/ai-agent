import os
import asyncio
from typing import Optional
from dotenv import load_dotenv
from groq import AsyncGroq

from providers.base import BaseProvider

load_dotenv()


class GroqProvider(BaseProvider):
    name = "groq"

    def __init__(self):
        self.api_key = os.getenv("GROQ_API_KEY")
        self.client = AsyncGroq(api_key=self.api_key) if self.api_key else None

    def is_configured(self) -> bool:
        return bool(self.api_key)

    async def generate(self, prompt: str, system: Optional[str] = None) -> str:
        if not self.client:
            raise RuntimeError("Groq provider non configuré (clé manquante).")

        messages = []

        if system:
            messages.append(
                {
                    "role": "system",
                    "content": system,
                }
            )

        messages.append(
            {
                "role": "user",
                "content": prompt,
            }
        )

        response = await self.client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=messages,
            temperature=0.2,
        )

        return response.choices[0].message.content
