import re

from core.ai_contract_agent import run_ai_contract_agent
from core.extractor import extract_information

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


def contract_to_dict(contract):
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


def extract_ids(message: str):
    return [int(x) for x in re.findall(r"\b\d+\b", message)]


def extract_search_filters(message: str) -> dict:
    text = message.lower()
    filters = {}

    if "coaching" in text:
        filters["contract_type"] = "coaching"

    if "location" in text:
        filters["contract_type"] = "location"

    if "travail" in text:
        filters["contract_type"] = "travail"

    if "vente" in text:
        filters["contract_type"] = "vente"

    if "djerba" in text:
        filters["place"] = "Djerba"

    if "tunis" in text:
        filters["place"] = "Tunis"

    if "virement" in text:
        filters["payment_method"] = "Virement bancaire"

    if "chèque" in text or "cheque" in text:
        filters["payment_method"] = "Chèque"

    if "espèce" in text or "espece" in text or "cash" in text:
        filters["payment_method"] = "Espèces"

    name_match = re.search(
        r"(?:avec|concernant|client)\s+([A-Za-zÀ-ÿ\s-]+?)(?:,|\.|$)",
        message,
        re.IGNORECASE,
    )

    if name_match:
        filters["client_name"] = name_match.group(1).strip()

    return filters


# =====================================================
# TOOLS
# =====================================================

def tool_create_contract(session_id: str, message: str):
    return run_ai_contract_agent(session_id, message)


def tool_list_contracts():
    contracts = list_saved_contracts()

    return {
        "count": len(contracts),
        "contracts": [contract_to_dict(c) for c in contracts],
    }


def tool_get_contract(contract_id: int):
    contract = get_contract_by_id(contract_id)

    if not contract:
        return {"error": "Contrat introuvable"}

    return contract_to_dict(contract)


def tool_search_contracts(message: str):
    filters = extract_search_filters(message)
    results = search_contracts(filters)

    return {
        "filters": filters,
        "count": len(results),
        "contracts": [contract_to_dict(c) for c in results],
    }


def tool_update_contract(contract_id: int, message: str):
    data = extract_information(message)

    price_match = re.search(
        r"prix\s+(\d+\s*(?:dt|dinar|dinars|€|eur|euro|euros))",
        message.lower(),
    )
    if price_match:
        data["price"] = price_match.group(1)

    duration_match = re.search(
        r"durée\s+(\d+\s*(?:jour|jours|semaine|semaines|mois|an|ans|année|années))",
        message.lower(),
    )
    if duration_match:
        data["duration"] = duration_match.group(1)

    updated = update_contract_by_id(contract_id, data)

    if not updated:
        return {"error": "Contrat introuvable"}

    return contract_to_dict(updated)


def tool_delete_contract(contract_id: int):
    deleted = delete_contract_by_id(contract_id)

    if not deleted:
        return {"error": "Contrat introuvable"}

    return {
        "status": "deleted",
        "id": contract_id,
    }


def tool_summarize_contract(contract_id: int):
    contract = get_contract_by_id(contract_id)

    if not contract:
        return {"error": "Contrat introuvable"}

    return summarize_contract(contract)


def tool_analyze_contract(contract_id: int):
    contract = get_contract_by_id(contract_id)

    if not contract:
        return {"error": "Contrat introuvable"}

    return analyze_legal_risks(contract)


def tool_compare_contracts(contract_id_1: int, contract_id_2: int):
    contract_1 = get_contract_by_id(contract_id_1)
    contract_2 = get_contract_by_id(contract_id_2)

    if not contract_1 or not contract_2:
        return {"error": "Un des contrats est introuvable"}

    return compare_saved_contracts(contract_1, contract_2)


TOOLS = {
    "create_contract": tool_create_contract,
    "list_contracts": tool_list_contracts,
    "get_contract": tool_get_contract,
    "search_contracts": tool_search_contracts,
    "update_contract": tool_update_contract,
    "delete_contract": tool_delete_contract,
    "summarize_contract": tool_summarize_contract,
    "analyze_contract": tool_analyze_contract,
    "compare_contracts": tool_compare_contracts,
}


# =====================================================
# TOOL SELECTION
# =====================================================

def choose_tool(message: str) -> dict:
    text = message.lower()
    ids = extract_ids(message)

    if any(w in text for w in ["crée", "creer", "créer", "génère", "generer", "générer"]):
        return {
            "tool": "create_contract",
            "arguments": {},
        }

    if any(w in text for w in ["liste", "tous les contrats", "historique"]):
        return {
            "tool": "list_contracts",
            "arguments": {},
        }

    if any(w in text for w in ["montre-moi", "montre moi", "cherche", "recherche", "trouve", "contrats de", "contrats à"]):
        return {
            "tool": "search_contracts",
            "arguments": {},
        }

    if any(w in text for w in ["affiche", "voir", "détail", "detail"]):
        return {
            "tool": "get_contract",
            "arguments": {
                "contract_id": ids[0] if ids else None,
            },
        }

    if any(w in text for w in ["modifie", "modifier", "change", "changer"]):
        return {
            "tool": "update_contract",
            "arguments": {
                "contract_id": ids[0] if ids else None,
            },
        }

    if any(w in text for w in ["supprime", "supprimer", "delete"]):
        return {
            "tool": "delete_contract",
            "arguments": {
                "contract_id": ids[0] if ids else None,
            },
        }

    if any(w in text for w in ["résume", "resume", "résumé", "summary"]):
        return {
            "tool": "summarize_contract",
            "arguments": {
                "contract_id": ids[0] if ids else None,
            },
        }

    if any(w in text for w in ["analyse", "analyser", "risque", "clause"]):
        return {
            "tool": "analyze_contract",
            "arguments": {
                "contract_id": ids[0] if ids else None,
            },
        }

    if any(w in text for w in ["compare", "comparer", "comparaison"]):
        return {
            "tool": "compare_contracts",
            "arguments": {
                "contract_id_1": ids[0] if len(ids) > 0 else None,
                "contract_id_2": ids[1] if len(ids) > 1 else None,
            },
        }

    return {
        "tool": "help",
        "arguments": {},
    }


# =====================================================
# AGENT
# =====================================================

def run_tool_calling_agent(session_id: str, message: str) -> dict:
    tool_call = choose_tool(message)

    tool_name = tool_call["tool"]
    arguments = tool_call["arguments"]

    if tool_name == "help":
        return {
            "agent": "Tool Calling Contract Agent",
            "message": "Je peux créer, lister, rechercher, afficher, modifier, supprimer, résumer, analyser ou comparer des contrats.",
            "available_tools": list(TOOLS.keys()),
        }

    if tool_name not in TOOLS:
        return {
            "error": "Outil introuvable",
            "tool": tool_name,
        }

    if tool_name == "create_contract":
        result = TOOLS[tool_name](session_id, message)

    elif tool_name == "search_contracts":
        result = TOOLS[tool_name](message)

    elif tool_name == "update_contract":
        contract_id = arguments.get("contract_id")

        if not contract_id:
            return {"error": "Veuillez préciser l'id du contrat à modifier."}

        result = TOOLS[tool_name](contract_id, message)

    elif tool_name == "compare_contracts":
        contract_id_1 = arguments.get("contract_id_1")
        contract_id_2 = arguments.get("contract_id_2")

        if not contract_id_1 or not contract_id_2:
            return {"error": "Veuillez préciser deux ids de contrats à comparer."}

        result = TOOLS[tool_name](contract_id_1, contract_id_2)

    else:
        contract_id = arguments.get("contract_id")

        if tool_name in [
            "get_contract",
            "delete_contract",
            "summarize_contract",
            "analyze_contract",
        ] and not contract_id:
            return {"error": "Veuillez préciser l'id du contrat."}

        result = TOOLS[tool_name](**arguments)

    return {
        "agent": "Tool Calling Contract Agent",
        "selected_tool": tool_name,
        "arguments": arguments,
        "result": result,
    }