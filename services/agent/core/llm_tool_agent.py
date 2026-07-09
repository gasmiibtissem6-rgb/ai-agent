import json
import re
import time

from agent.core import run_agent
from agent.session_store import get_session
from agent.conversation_agent import ConversationAgent

from core.ai_contract_agent import run_ai_contract_agent
from core.logger import logger
from core.tool_registry import TOOLS
from core.agent_memory import set_last_contract_id, get_last_contract_id
from core.model_router import choose_model


def clean_json(text: str) -> dict:
    match = re.search(r"\{.*\}", text.strip(), re.DOTALL)

    if not match:
        return {"steps": [{"tool": "help", "arguments": {}}]}

    try:
        data = json.loads(match.group())

        if "steps" not in data:
            return {"steps": [data]}

        return data

    except Exception:
        logger.exception("Erreur parsing JSON du planner")
        return {"steps": [{"tool": "help", "arguments": {}}]}


def llm_plan(message: str) -> dict:
    prompt = f"""
Tu es un AI Contract Agent avancé.

Tu dois choisir un ou plusieurs outils à exécuter.

Outils disponibles :
1. create_contract
2. list_contracts
3. get_contract
4. search_contracts
5. update_contract
6. delete_contract
7. summarize_contract
8. analyze_contract
9. compare_contracts
10. help

Réponds uniquement en JSON valide.

Format obligatoire :
{{
  "steps": [
    {{
      "tool": "nom_outil",
      "arguments": {{}}
    }}
  ]
}}

Exemples :
Utilisateur: Liste les contrats
Réponse:
{{"steps":[{{"tool":"list_contracts","arguments":{{}}}}]}}

Utilisateur: Résume le contrat 1
Réponse:
{{"steps":[{{"tool":"summarize_contract","arguments":{{"contract_id":1}}}}]}}

Utilisateur: Analyse le contrat 1
Réponse:
{{"steps":[{{"tool":"analyze_contract","arguments":{{"contract_id":1}}}}]}}

Utilisateur: Liste les contrats puis résume le contrat 1 et analyse-le
Réponse:
{{"steps":[
  {{"tool":"list_contracts","arguments":{{}}}},
  {{"tool":"summarize_contract","arguments":{{"contract_id":1}}}},
  {{"tool":"analyze_contract","arguments":{{"contract_id":1}}}}
]}}

Utilisateur: Montre-moi les contrats de coaching à Djerba
Réponse:
{{"steps":[{{"tool":"search_contracts","arguments":{{"contract_type":"coaching","place":"Djerba"}}}}]}}

Utilisateur: Modifie le contrat 1 prix 500 dinars durée 10 jours
Réponse:
{{"steps":[{{"tool":"update_contract","arguments":{{"contract_id":1,"price":"500 dinars","duration":"10 jours"}}}}]}}

Utilisateur: Compare le contrat 1 et le contrat 2
Réponse:
{{"steps":[{{"tool":"compare_contracts","arguments":{{"contract_id_1":1,"contract_id_2":2}}}}]}}

Utilisateur:
{message}
"""

    model = choose_model("planning")
    logger.info("MODEL SELECTED FOR PLANNING: %s", model)

    response = run_agent(model, prompt)
    return clean_json(response)


def execute_step(session_id: str, message: str, step: dict):
    tool_name = step.get("tool")
    args = step.get("arguments", {}) or {}

    if not isinstance(args, dict):
        args = {}

    if args.get("contract_id") is None:
        last_id = get_last_contract_id(session_id)
        if last_id:
            args["contract_id"] = last_id

    if tool_name == "create_contract":
        return run_ai_contract_agent(session_id, message)

    tool = TOOLS.get(tool_name)

    if tool is None:
        return {"error": f"Outil inconnu : {tool_name}"}

    result = tool(**args)

    if isinstance(result, dict):
        if result.get("id"):
            set_last_contract_id(session_id, result["id"])

        if result.get("contract") and isinstance(result["contract"], dict):
            contract_id = result["contract"].get("id")
            if contract_id:
                set_last_contract_id(session_id, contract_id)

    return result


def generate_final_answer(message: str, plan: dict, observations: list) -> str:
    prompt = f"""
Tu es un assistant professionnel de gestion de contrats.

Question utilisateur :
{message}

Plan exécuté :
{json.dumps(plan, ensure_ascii=False)}

Résultats des outils :
{json.dumps(observations, ensure_ascii=False)}

Rédige une réponse finale claire, courte et utile en français.
Ne montre pas de JSON brut.
"""

    model = choose_model("final_answer")
    logger.info("MODEL SELECTED FOR FINAL ANSWER: %s", model)

    return run_agent(model, prompt)


def run_llm_tool_agent(session_id: str, message: str) -> dict:
    start_time = time.time()
    success = True

    conversation_agent = ConversationAgent()
    session = get_session(session_id)

    if session and not conversation_agent.is_complete(session):
        logger.info("CONTINUATION CONVERSATION")
        logger.info("session_id=%s", session_id)
        logger.info("message=%s", message)

        result = run_ai_contract_agent(session_id, message)

        metrics = {
            "execution_time_seconds": round(time.time() - start_time, 2),
            "tools_used": 1,
            "success": True,
        }

        return {
            "agent": "Advanced LLM Tool Calling Contract Agent",
            "mode": "conversation_continuation",
            "result": result,
            "metrics": metrics,
        }

    logger.info("=" * 60)
    logger.info("USER MESSAGE: %s", message)

    try:
        plan = llm_plan(message)
        logger.info("LLM PLAN: %s", plan)

    except Exception as e:
        logger.exception("Erreur lors de la génération du plan")

        return {
            "agent": "Advanced LLM Tool Calling Contract Agent",
            "error": str(e),
            "metrics": {
                "execution_time_seconds": round(time.time() - start_time, 2),
                "tools_used": 0,
                "success": False,
            },
        }

    observations = []

    for step in plan.get("steps", []):
        try:
            logger.info("TOOL EXECUTED: %s", step)

            result = execute_step(session_id, message, step)

            logger.info("TOOL RESULT: %s", result)

            if isinstance(result, dict) and result.get("error"):
                success = False

        except Exception as e:
            success = False
            logger.exception("Erreur pendant l'exécution d'un outil")

            result = {
                "error": str(e),
                "tool": step.get("tool"),
            }

        observations.append({
            "tool": step.get("tool"),
            "arguments": step.get("arguments", {}),
            "result": result,
        })

    try:
        final_answer = generate_final_answer(
            message=message,
            plan=plan,
            observations=observations,
        )

        logger.info("FINAL ANSWER: %s", final_answer)

    except Exception as e:
        success = False
        logger.exception("Erreur lors de la génération de la réponse finale")

        final_answer = (
            "Le traitement est terminé, mais la réponse finale "
            "n'a pas pu être générée."
        )

        observations.append({
            "tool": "final_answer",
            "arguments": {},
            "result": {"error": str(e)},
        })

    metrics = {
        "execution_time_seconds": round(time.time() - start_time, 2),
        "tools_used": len(observations),
        "success": success,
    }

    logger.info("METRICS: %s", metrics)
    logger.info("=" * 60)

    return {
        "agent": "Advanced LLM Tool Calling Contract Agent",
        "plan": plan,
        "observations": observations,
        "final_answer": final_answer,
        "metrics": metrics,
    }