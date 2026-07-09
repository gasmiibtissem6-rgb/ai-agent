def validate_contract_data(data: dict) -> dict:
    errors = []
    warnings = []

    required_fields = {
        "contract_type": "Type de contrat manquant",
        "provider_name": "Nom du prestataire manquant",
        "client_name": "Nom du client manquant",
        "provider_email": "Email du prestataire manquant",
        "client_email": "Email du client manquant",
        "duration": "Durée du contrat manquante",
        "price": "Prix du contrat manquant",
        "payment_method": "Mode de paiement manquant",
        "place": "Lieu de signature manquant",
    }

    for field, message in required_fields.items():
        if not data.get(field):
            errors.append(message)

    if not data.get("provider_address"):
        warnings.append("Adresse du prestataire non renseignée")

    if not data.get("client_address"):
        warnings.append("Adresse du client non renseignée")

    if not data.get("provider_phone"):
        warnings.append("Téléphone du prestataire non renseigné")

    if not data.get("client_phone"):
        warnings.append("Téléphone du client non renseigné")

    return {
        "valid": len(errors) == 0,
        "errors": errors,
        "warnings": warnings,
    }