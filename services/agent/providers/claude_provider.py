import os
from typing import Optional
from dotenv import load_dotenv
from anthropic import AsyncAnthropic
from providers.base import BaseProvider

load_dotenv()


class ClaudeProvider(BaseProvider):
    name = "claude"

    def __init__(self):
        self.api_key = os.getenv("ANTHROPIC_API_KEY")
        self.client = AsyncAnthropic(api_key=self.api_key) if self.api_key else None

    def is_configured(self) -> bool:
        return bool(self.api_key)

    async def generate(self, prompt: str, system: Optional[str] = None) -> str:
        if not self.client:
            raise RuntimeError("Claude provider non configuré (clé manquante).")

        response = await self.client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=2000,
            system=system or "",
            messages=[{"role": "user", "content": prompt}],
        )
        return response.content[0].text
