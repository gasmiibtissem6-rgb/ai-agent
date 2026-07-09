from models.router import route_to_model
from tools.send_notification import send_notification
from tools.create_contract import create_contract
from tools.analyze_contract import analyze_contract
from tools.generate_pdf import generate_pdf
from tools.send_email import send_email
from tools.compare_contracts import compare_contracts

def run_agent(role: str, message: str) -> str:
    lower = message.lower()

    if any(k in lower for k in ["relance", "notifie", "envoie une notification"]):
        return send_notification(recipient="ahmed@example.com", message=message)

    if any(k in lower for k in ["crée un contrat", "créer un contrat", "nouveau contrat", "rédige un contrat"]):
        return create_contract(title="Contrat généré par l'agent", content=message)

    if any(k in lower for k in ["analyse ce contrat", "analyser le contrat", "vérifie ce contrat", "clauses à risque"]):
        return analyze_contract(content=message)

    if any(k in lower for k in ["génère un pdf", "genere un pdf", "exporte en pdf", "crée un pdf"]):
        return generate_pdf(title="Document généré", content=message)

    if any(k in lower for k in ["envoie un email", "envoie un mail", "envoyer un email"]):
        return send_email(to="gasmiibtissem6@gmail.com", subject="Message de l'agent IDEAL", body=message)

    if any(k in lower for k in ["compare ces contrats", "compare les contrats", "différence entre les contrats"]):
        parts = message.split("---")
        if len(parts) >= 2:
            return compare_contracts(contract_a=parts[0], contract_b=parts[1])
        return "Merci de séparer les deux contrats par '---' pour que je puisse les comparer."

    return route_to_model(role, message)
