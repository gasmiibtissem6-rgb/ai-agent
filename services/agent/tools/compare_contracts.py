from models.deepseek_provider import ask_deepseek

def compare_contracts(contract_a: str, contract_b: str) -> str:
    """
    Compare deux contrats et met en évidence leurs différences importantes.
    Utilise DeepSeek pour le raisonnement comparatif.
    """
    prompt = f"""Tu es un assistant juridique expert. Réponds impérativement en français.

Compare les deux contrats suivants et identifie :
1. Les différences importantes entre les deux versions
2. Les clauses ajoutées ou supprimées
3. Les changements de conditions (montants, durées, obligations)
4. Lequel des deux semble le plus favorable, et pour qui

Contrat A :
---
{contract_a}
---

Contrat B :
---
{contract_b}
---

Réponds de façon structurée et concise, uniquement en français."""

    return ask_deepseek(prompt)
