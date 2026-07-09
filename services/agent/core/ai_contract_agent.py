from agent.conversation_agent import ConversationAgent
from agent.session_store import (
    get_session,
    update_session,
    clear_session,
)

from core.extractor import extract_information
from core.validator import validate_contract_data

from tools.generate_contract_content import generate_contract_content
from tools.generate_pdf import generate_pdf

from database.contracts import save_contract


def run_ai_contract_agent(session_id: str, message: str) -> dict:

    agent = ConversationAgent()
    session = get_session(session_id)

    extracted = extract_information(message)

    current_field = agent.next_field(session)

    if extracted:

        for key, value in extracted.items():

            if key == "email" and current_field in [
                "provider_email",
                "client_email",
            ]:
                update_session(session_id, current_field, value)

            elif key == "phone" and current_field in [
                "provider_phone",
                "client_phone",
            ]:
                update_session(session_id, current_field, value)

            elif key in agent.required_fields:
                update_session(session_id, key, value)

    else:

        session = agent.save_answer(session, message)

        for key, value in session.items():
            update_session(session_id, key, value)

    session = get_session(session_id)

    if not agent.is_complete(session):
        return {
            "status": "collecting",
            "data": session,
            "next_question": agent.next_question(session),
        }

    validation = validate_contract_data(session)

    if not validation["valid"]:
        return {
            "status": "validation_error",
            "data": session,
            "errors": validation["errors"],
            "warnings": validation["warnings"],
            "next_question": agent.next_question(session),
        }

    # Génération du contrat
    prompt = agent.build_prompt(session)

    contract = generate_contract_content(prompt)

    # Génération du PDF
    pdf = generate_pdf(
        title=contract["title"],
        content=contract["content"],
    )

    # Sauvegarde dans la base de données
    saved = save_contract(
        data=session,
        contract=contract,
        pdf_result=pdf,
    )

    # Nettoyage de la session
    clear_session(session_id)

    return {
        "status": "completed",
        "database_id": saved.id,
        "data": session,
        "contract": contract,
        "pdf": pdf,
    }