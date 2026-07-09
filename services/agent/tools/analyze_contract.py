import asyncio
from providers.groq_provider import GroqProvider


def analyze_contract(content: str) -> str:
    prompt = f"""
Tu es un assistant spécialisé dans l'analyse de contrats de services du quotidien.

Analyse cette demande ou ce contrat :

---
{content}
---

Réponds avec cette structure :

1. Type de contrat détecté
2. Informations importantes
3. Clauses manquantes
4. Risques possibles
5. Conseils pour l'utilisateur

Réponds en français clair et simple.
"""

    provider = GroqProvider()
    return asyncio.run(provider.generate(prompt))