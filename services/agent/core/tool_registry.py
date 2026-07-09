from database.contracts import (
    list_saved_contracts,
    get_contract_by_id,
    update_contract_by_id,
    delete_contract_by_id,
)

from database.search import search_contracts

from tools.summarize_contract import summarize_contract
from tools.legal_analysis import analyze_legal_risks
from tools.compare_saved_contracts import compare_saved_contracts


TOOLS = {}


def register_tool(name):
    def decorator(func):
        TOOLS[name] = func
        return func

    return decorator


def contract_to_dict(contract):
    if contract is None:
        return None

    return {
        "id": contract.id,
        "reference": contract.reference,
        "contract_type": contract.contract_type,
        "provider_name": contract.provider_name,
        "client_name": contract.client_name,
        "provider_email": contract.provider_email,
        "client_email": contract.client_email,
        "provider_phone": contract.provider_phone,
        "client_phone": contract.client_phone,
        "provider_address": contract.provider_address,
        "client_address": contract.client_address,
        "duration": contract.duration,
        "price": contract.price,
        "payment_method": contract.payment_method,
        "place": contract.place,
        "pdf_path": contract.pdf_path,
        "created_at": str(contract.created_at),
    }


@register_tool("list_contracts")
def tool_list_contracts(**kwargs):
    contracts = list_saved_contracts()

    return {
        "count": len(contracts),
        "contracts": [contract_to_dict(c) for c in contracts],
    }


@register_tool("get_contract")
def tool_get_contract(contract_id: int, **kwargs):
    contract = get_contract_by_id(contract_id)

    if not contract:
        return {"error": "Contrat introuvable"}

    return contract_to_dict(contract)


@register_tool("search_contracts")
def tool_search_contracts(**kwargs):
    results = search_contracts(kwargs)

    return {
        "filters": kwargs,
        "count": len(results),
        "contracts": [contract_to_dict(c) for c in results],
    }


@register_tool("update_contract")
def tool_update_contract(contract_id: int, **kwargs):
    updated = update_contract_by_id(
        contract_id=contract_id,
        data=kwargs,
    )

    if not updated:
        return {"error": "Contrat introuvable"}

    return contract_to_dict(updated)


@register_tool("delete_contract")
def tool_delete_contract(contract_id: int, **kwargs):
    deleted = delete_contract_by_id(contract_id)

    if not deleted:
        return {"error": "Contrat introuvable"}

    return {
        "status": "deleted",
        "id": contract_id,
    }


@register_tool("summarize_contract")
def tool_summarize_contract(contract_id: int, **kwargs):
    contract = get_contract_by_id(contract_id)

    if not contract:
        return {"error": "Contrat introuvable"}

    return summarize_contract(contract)


@register_tool("analyze_contract")
def tool_analyze_contract(contract_id: int, **kwargs):
    contract = get_contract_by_id(contract_id)

    if not contract:
        return {"error": "Contrat introuvable"}

    return analyze_legal_risks(contract)


@register_tool("compare_contracts")
def tool_compare_contracts(
    contract_id_1: int,
    contract_id_2: int,
    **kwargs,
):
    contract_1 = get_contract_by_id(contract_id_1)
    contract_2 = get_contract_by_id(contract_id_2)

    if not contract_1 or not contract_2:
        return {"error": "Un des contrats est introuvable"}

    return compare_saved_contracts(contract_1, contract_2)

