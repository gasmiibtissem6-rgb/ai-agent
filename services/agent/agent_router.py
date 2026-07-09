from providers.openai_provider import OpenAIProvider
from providers.claude_provider import ClaudeProvider
from providers.gemini_provider import GeminiProvider
from providers.mistral_provider import MistralProvider


class AgentRouter:
    """Route une demande vers le bon modèle selon la tâche demandée."""

    def __init__(self):
        self.providers = {
            "openai": OpenAIProvider(),
            "claude": ClaudeProvider(),
            "gemini": GeminiProvider(),
            "mistral": MistralProvider(),
        }

    def available_providers(self) -> list[str]:
        """Liste les providers dont la clé API est configurée."""
        return [name for name, p in self.providers.items() if p.is_configured()]

    def pick_provider(self, task: str) -> str:
        """
        Décide quel provider utiliser selon le type de tâche.
        Règles simples pour commencer, à affiner plus tard.
        """
        task_to_provider = {
            "agent": "openai",       # décisions/actions générales
            "contract": "claude",    # rédaction/relecture juridique
            "faq": "gemini",         # questions simples / OCR
            "fallback": "mistral",   # secours, cas simples
        }
        chosen = task_to_provider.get(task, "openai")

        # Si le provider choisi n'est pas configuré, on retombe sur le premier disponible
        if not self.providers[chosen].is_configured():
            available = self.available_providers()
            if not available:
                raise RuntimeError("Aucun provider n'est configuré (aucune clé API valide).")
            chosen = available[0]

        return chosen

    async def run(self, task: str, prompt: str, system: str | None = None) -> dict:
        provider_name = self.pick_provider(task)
        provider = self.providers[provider_name]
        result = await provider.generate(prompt, system=system)
        return {"provider": provider_name, "response": result}
