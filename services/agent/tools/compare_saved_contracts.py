def compare_saved_contracts(contract_a, contract_b) -> dict:
    fields = [
        "contract_type",
        "provider_name",
        "client_name",
        "duration",
        "price",
        "payment_method",
        "place",
    ]

    differences = {}

    for field in fields:
        value_a = getattr(contract_a, field)
        value_b = getattr(contract_b, field)

        if value_a != value_b:
            differences[field] = {
                "contract_1": value_a,
                "contract_2": value_b,
            }

    return {
        "contract_1_id": contract_a.id,
        "contract_2_id": contract_b.id,
        "same_contract_type": contract_a.contract_type == contract_b.contract_type,
        "differences_count": len(differences),
        "differences": differences,
    }