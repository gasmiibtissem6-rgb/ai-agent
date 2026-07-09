import json
import re

from providers.groq_provider import GroqProvider


def _extract_json(text: str):
    """
    Extrait le premier objet JSON d'une réponse LLM.
    """

    match = re.search(r"\{.*\}", text, re.DOTALL)

    if not match:
        raise ValueError("Aucun JSON trouvé dans la réponse du modèle.")

    return json.loads(match.group(0))


def generate_contract_content(user_request: str) -> dict:

    provider = GroqProvider()

    prompt = f"""
Tu es un juriste professionnel spécialisé dans la rédaction de contrats.

Le client demande :

{user_request}

Rédige un contrat COMPLET, professionnel et juridiquement structuré.

Le contrat doit contenir :

- Un titre
- ENTRE LES SOUSSIGNÉS
- Identification du Client
- Identification du Prestataire

Article 1 - Objet

Article 2 - Durée

Article 3 - Prix

Article 4 - Modalités de paiement

Article 5 - Obligations du Prestataire

Article 6 - Obligations du Client

Article 7 - Résiliation

Article 8 - Responsabilité

Article 9 - Confidentialité

Article 10 - Litiges

Fait à :

Date :

Signature du Client

Signature du Prestataire

Réponds UNIQUEMENT avec un JSON valide.

Le format attendu est :

{{
    "title": "...",
    "contract_type": "...",
    "content": "..."
}}

Règles importantes :

- Aucun Markdown
- Pas de ```json
- Pas d'explication
- Le champ "content" doit contenir tout le contrat.
- Le contrat doit être très détaillé.
"""

    response = provider.generate(prompt)

    if hasattr(response, "__await__"):
        import asyncio

        response = asyncio.run(response)

    return _extract_json(response)