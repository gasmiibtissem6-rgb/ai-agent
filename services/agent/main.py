import os
import shutil
import uuid

from fastapi import FastAPI, UploadFile, File
from fastapi.responses import FileResponse
from pydantic import BaseModel

from agent.core import run_agent
from agent.conversation_agent import ConversationAgent
from agent.session_store import get_session, update_session, clear_session

from core.agent_core import run_smart_contract_agent
from core.ai_contract_agent import run_ai_contract_agent
from core.super_agent import run_super_agent
from core.tool_calling_agent import run_tool_calling_agent
from core.llm_tool_agent import run_llm_tool_agent
from core.extractor import extract_information
from core.validator import validate_contract_data

from database.contracts import (
    list_saved_contracts,
    get_contract_by_id,
    delete_contract_by_id,
    update_contract_by_id,
)

from tools.analyze_image import analyze_image
from tools.generate_contract_content import generate_contract_content
from tools.generate_pdf import generate_pdf
from core.langgraph_agent import run_langgraph_agent

app = FastAPI()

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)


class ChatRequest(BaseModel):
    role: str
    message: str


class ConversationRequest(BaseModel):
    session_id: str
    message: str


class ContractUpdateRequest(BaseModel):
    contract_type: str | None = None
    provider_name: str | None = None
    client_name: str | None = None
    provider_email: str | None = None
    client_email: str | None = None
    provider_phone: str | None = None
    client_phone: str | None = None
    provider_address: str | None = None
    client_address: str | None = None
    duration: str | None = None
    price: str | None = None
    payment_method: str | None = None
    place: str | None = None


@app.post("/smart-agent")
def smart_agent(request: ChatRequest):
    return run_smart_contract_agent(request.message)


@app.post("/ai-contract-agent")
def ai_contract_agent(request: ConversationRequest):
    return run_ai_contract_agent(
        session_id=request.session_id,
        message=request.message,
    )


@app.post("/contract-conversation")
def contract_conversation(request: ConversationRequest):
    conversation_agent = ConversationAgent()
    session = get_session(request.session_id)

    extracted = extract_information(request.message)
    current_field = conversation_agent.next_field(session)

    if extracted:
        for key, value in extracted.items():
            if key == "email" and current_field in ["provider_email", "client_email"]:
                update_session(request.session_id, current_field, value)
            elif key == "phone" and current_field in ["provider_phone", "client_phone"]:
                update_session(request.session_id, current_field, value)
            elif key in conversation_agent.required_fields:
                update_session(request.session_id, key, value)
    else:
        session = conversation_agent.save_answer(session, request.message)
        for key, value in session.items():
            update_session(request.session_id, key, value)

    session = get_session(request.session_id)

    if not conversation_agent.is_complete(session):
        return {
            "status": "collecting",
            "data": session,
            "next_question": conversation_agent.next_question(session),
        }

    validation = validate_contract_data(session)

    if not validation["valid"]:
        return {
            "status": "validation_error",
            "data": session,
            "errors": validation["errors"],
            "warnings": validation["warnings"],
            "next_question": conversation_agent.next_question(session),
        }

    prompt = conversation_agent.build_prompt(session)
    contract = generate_contract_content(prompt)

    pdf = generate_pdf(
        title=contract["title"],
        content=contract["content"],
    )

    clear_session(request.session_id)

    return {
        "status": "completed",
        "contract": contract,
        "pdf": pdf,
    }


@app.post("/chat")
def chat(request: ChatRequest):
    reply = run_agent(request.role, request.message)
    return {"reply": reply}


@app.post("/analyze-image")
def analyze_image_endpoint(file: UploadFile = File(...)):
    extension = os.path.splitext(file.filename)[1]
    temp_path = os.path.join(UPLOAD_DIR, f"{uuid.uuid4()}{extension}")

    with open(temp_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    result = analyze_image(temp_path)
    return {"reply": result}


@app.get("/contracts")
def list_contracts():
    contracts = list_saved_contracts()

    return {
        "count": len(contracts),
        "contracts": [
            {
                "id": c.id,
                "reference": c.reference,
                "contract_type": c.contract_type,
                "provider_name": c.provider_name,
                "client_name": c.client_name,
                "price": c.price,
                "duration": c.duration,
                "payment_method": c.payment_method,
                "place": c.place,
                "pdf_path": c.pdf_path,
                "created_at": str(c.created_at),
            }
            for c in contracts
        ],
    }


@app.get("/contracts/id/{contract_id}")
def get_contract(contract_id: int):
    contract = get_contract_by_id(contract_id)

    if contract is None:
        return {"error": "Contrat introuvable"}

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


@app.get("/contracts/{filename}")
def download_contract(filename: str):
    filepath = os.path.join("generated_pdfs", filename)

    if not os.path.exists(filepath):
        return {"error": "Fichier PDF introuvable"}

    return FileResponse(
        filepath,
        media_type="application/pdf",
        filename=filename,
    )


@app.delete("/contracts/id/{contract_id}")
def delete_contract(contract_id: int):
    deleted = delete_contract_by_id(contract_id)

    if deleted is None:
        return {"error": "Contrat introuvable"}

    return {
        "status": "deleted",
        "id": contract_id,
    }


@app.put("/contracts/id/{contract_id}")
def update_contract(contract_id: int, request: ContractUpdateRequest):
    updated = update_contract_by_id(
        contract_id=contract_id,
        data=request.model_dump(),
    )

    if updated is None:
        return {"error": "Contrat introuvable"}

    return {
        "status": "updated",
        "contract": {
            "id": updated.id,
            "reference": updated.reference,
            "contract_type": updated.contract_type,
            "provider_name": updated.provider_name,
            "client_name": updated.client_name,
            "provider_email": updated.provider_email,
            "client_email": updated.client_email,
            "provider_phone": updated.provider_phone,
            "client_phone": updated.client_phone,
            "provider_address": updated.provider_address,
            "client_address": updated.client_address,
            "duration": updated.duration,
            "price": updated.price,
            "payment_method": updated.payment_method,
            "place": updated.place,
            "pdf_path": updated.pdf_path,
            "created_at": str(updated.created_at),
        },
    }


@app.post("/agent")
def agent(request: ConversationRequest):
    return run_super_agent(
        session_id=request.session_id,
        message=request.message,
    )


@app.post("/tool-agent")
def tool_agent(request: ConversationRequest):
    return run_tool_calling_agent(
        session_id=request.session_id,
        message=request.message,
    )


@app.post("/llm-agent")
def llm_agent(request: ConversationRequest):
    return run_llm_tool_agent(
        session_id=request.session_id,
        message=request.message,
    )
@app.post("/langgraph-agent")
def langgraph_agent(request: ConversationRequest):
    return run_langgraph_agent(
        session_id=request.session_id,
        message=request.message,
    )