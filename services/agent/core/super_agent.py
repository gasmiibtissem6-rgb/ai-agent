import re

from core.ai_contract_agent import run_ai_contract_agent
from core.extractor import extract_information

from agent.session_store import get_session
from agent.conversation_agent import ConversationAgent

from database.search import search_contracts
from database.contracts import (
    list_saved_contracts,
    get_contract_by_id,
    update_contract_by_id,
    delete_contract_by_id,
)

from tools.analyze_contract import analyze_contract
from tools.summarize_contract import summarize_contract
from tools.legal_analysis import analyze_legal_risks
from tools.compare_saved_contracts import compare_saved_contracts


def detect_intent(message: str) -> str:
    text = message.lower()

    if any(w in text for w in ["supprime", "supprimer", "delete"]):
        return "delete"

    if any(w in text for w in ["modifie", "modifier", "changer", "update"]):
        return "update"

    if any(w in text for w in ["résume", "resume", "résumé", "summary"]):
        return "summary"

    if any(w in text for w in ["compare", "comparer", "comparaison"]):
        return "compare"

    if any(w in text for w in ["détail", "detail", "voir contrat", "contrat id", "affiche le contrat"]):
        return "detail"

    if any(w in text for w in ["cherche", "recherche", "trouve", "montre-moi", "montre moi", "contrats de", "contrats à"]):
        return "search"

    if any(w in text for w in ["liste", "tous les contrats", "historique"]):
        return "list"

    if any(w in text for w in ["analyse", "analyser", "risque", "clause"]):
        return "analyze"

    if any(w in text for w in ["créer", "creer", "générer", "generer", "contrat"]):
        return "create"

    return "help"


def extract_id(message: str):
    match = re.search(r"\b\d+\b", message)
    return int(match.group()) if match else None


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


def run_super_agent(session_id: str, message: str) -> dict:
    agent = ConversationAgent()
    session = get_session(session_id)

    if session and not agent.is_complete(session):
        return run_ai_contract_agent(session_id, message)

    intent = detect_intent(message)

    if intent == "create":
        return run_ai_contract_agent(session_id, message)

    if intent == "search":
        filters = extract_search_filters(message)
        results = search_contracts(filters)

        return {
            "intent": "search",
            "filters": filters,
            "count": len(results),
            "contracts": [contract_to_dict(c) for c in results],
        }

    if intent == "list":
        contracts = list_saved_contracts()

        return {
            "intent": "list",
            "count": len(contracts),
            "contracts": [contract_to_dict(c) for c in contracts],
        }

    if intent == "detail":
        contract_id = extract_id(message)

        if not contract_id:
            return {"error": "Veuillez préciser l'id du contrat."}

        contract = get_contract_by_id(contract_id)

        if not contract:
            return {"error": "Contrat introuvable"}

        return {
            "intent": "detail",
            "contract": contract_to_dict(contract),
        }

    if intent == "summary":
        contract_id = extract_id(message)

        if not contract_id:
            return {"error": "Veuillez préciser l'id du contrat à résumer."}

        contract = get_contract_by_id(contract_id)

        if not contract:
            return {"error": "Contrat introuvable"}

        return {
            "intent": "summary",
            "contract_id": contract_id,
            "result": summarize_contract(contract),
        }

    if intent == "analyze":
        contract_id = extract_id(message)

        if not contract_id:
            return {"error": "Veuillez préciser l'id du contrat à analyser."}

        contract = get_contract_by_id(contract_id)

        if not contract:
            return {"error": "Contrat introuvable"}

        return {
            "intent": "analyze",
            "contract_id": contract_id,
            "analysis": analyze_legal_risks(contract),
        }

    if intent == "compare":
        ids = extract_ids(message)

        if len(ids) < 2:
            return {"error": "Veuillez préciser deux ids de contrats à comparer."}

        contract_a = get_contract_by_id(ids[0])
        contract_b = get_contract_by_id(ids[1])

        if not contract_a or not contract_b:
            return {"error": "Un des contrats est introuvable"}

        return {
            "intent": "compare",
            "result": compare_saved_contracts(contract_a, contract_b),
        }

    if intent == "delete":
        contract_id = extract_id(message)

        if not contract_id:
            return {"error": "Veuillez préciser l'id du contrat à supprimer."}

        deleted = delete_contract_by_id(contract_id)

        if not deleted:
            return {"error": "Contrat introuvable"}

        return {
            "intent": "delete",
            "status": "deleted",
            "id": contract_id,
        }

    if intent == "update":
        contract_id = extract_id(message)

        if not contract_id:
            return {"error": "Veuillez préciser l'id du contrat à modifier."}

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

        return {
            "intent": "update",
            "status": "updated",
            "contract": contract_to_dict(updated),
        }

    return {
        "intent": "help",
        "message": "Je peux créer, lister, consulter, rechercher, résumer, comparer, modifier, supprimer ou analyser des contrats.",
        "examples": [
            "Crée un contrat de coaching sportif entre Ideal Coaching et Ahmed Ben Ali pour 5 jours à 300 dinars à Djerba",
            "Liste tous les contrats",
            "Affiche le contrat 1",
            "Montre-moi les contrats de coaching à Djerba",
            "Trouve les contrats avec Ahmed Ben Ali",
            "Résume le contrat 1",
            "Analyse le contrat 1",
            "Compare le contrat 1 et le contrat 2",
            "Modifie le contrat 1 prix 500 dinars durée 10 jours",
            "Supprime le contrat 1",
        ],
    }