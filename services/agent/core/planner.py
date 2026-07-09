def plan_task(message: str) -> dict:
    text = message.lower()

    # 1. Extraction depuis image / PDF
    if any(w in text for w in [
        "photo", "image", "scan", "pdf"
    ]):
        return {
            "task_type": "document_extraction",
            "steps": [
                {"tool": "analyze_image", "model": "gemini"},
                {"tool": "analyze_contract", "model": "groq"},
            ],
        }

    # 2. Comparaison
    if any(w in text for w in [
        "comparer", "comparaison", "différence", "difference",
        "meilleur contrat"
    ]):
        return {
            "task_type": "contract_comparison",
            "steps": [
                {"tool": "compare_contracts", "model": "groq"},
            ],
        }

    # 3. Analyse
    if any(w in text for w in [
        "analyser", "analyse", "risque", "signer",
        "clause", "garantie", "juridique", "vérifier", "verifier"
    ]):
        return {
            "task_type": "contract_risk_analysis",
            "steps": [
                {"tool": "analyze_contract", "model": "groq"},
            ],
        }

    # 4. Création de contrat
    if any(w in text for w in [
        "créer", "cree", "faire un contrat", "rédiger", "rediger",
        "générer", "generer", "contrat", "coaching", "location",
        "vente", "travail", "prestation", "plombier", "électricien",
        "electricien"
    ]):
        return {
            "task_type": "contract_creation",
            "steps": [
                {"tool": "create_contract", "model": "database"},
                {"tool": "analyze_contract", "model": "groq"},
                {"tool": "generate_pdf", "model": "local"},
            ],
        }

    # 5. Chat général
    return {
        "task_type": "orientation",
        "steps": [
            {"tool": "chat", "model": "groq"},
        ],
    }