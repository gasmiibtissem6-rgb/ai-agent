def analyze_legal_risks(contract) -> dict:
    risks = []
    missing = []
    recommendations = []

    if not contract.provider_name:
        missing.append("Nom du prestataire manquant")

    if not contract.client_name:
        missing.append("Nom du client manquant")

    if not contract.provider_email:
        missing.append("Email du prestataire manquant")

    if not contract.client_email:
        missing.append("Email du client manquant")

    if not contract.price:
        missing.append("Prix du contrat manquant")

    if not contract.duration:
        missing.append("Durée du contrat manquante")

    if not contract.payment_method:
        missing.append("Mode de paiement manquant")

    if not contract.place:
        missing.append("Lieu du contrat manquant")

    if contract.price and "0" == contract.price.strip():
        risks.append("Prix invalide ou nul")

    if contract.duration and "0" in contract.duration:
        risks.append("Durée potentiellement invalide")

    if not contract.pdf_path:
        risks.append("Aucun PDF associé au contrat")

    if missing:
        recommendations.append("Compléter toutes les informations manquantes avant signature.")

    recommendations.append("Ajouter une clause de résiliation claire.")
    recommendations.append("Ajouter une clause de confidentialité.")
    recommendations.append("Ajouter une clause de responsabilité.")
    recommendations.append("Prévoir les signatures des deux parties.")

    return {
        "contract_id": contract.id,
        "risk_level": "high" if risks or len(missing) >= 3 else "medium" if missing else "low",
        "missing_information": missing,
        "risks": risks,
        "recommendations": recommendations,
    }