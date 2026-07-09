def summarize_contract(contract) -> dict:
    return {
        "summary": (
            f"Contrat de type {contract.contract_type} entre "
            f"{contract.provider_name} et {contract.client_name}. "
            f"Le contrat est prévu à {contract.place}, pour une durée de "
            f"{contract.duration}, avec un prix de {contract.price}. "
            f"Le paiement est prévu par {contract.payment_method}."
        ),
        "key_points": {
            "type": contract.contract_type,
            "prestataire": contract.provider_name,
            "client": contract.client_name,
            "durée": contract.duration,
            "prix": contract.price,
            "paiement": contract.payment_method,
            "lieu": contract.place,
        },
    }