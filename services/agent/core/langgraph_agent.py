import json
import re
import time
from typing import TypedDict, List, Dict, Any

from langgraph.graph import StateGraph, START, END

from agent.core import run_agent
from agent.session_store import get_session
from agent.conversation_agent import ConversationAgent

from core.ai_contract_agent import run_ai_contract_agent
from core.logger import logger
from core.model_router import choose_model
from core.tool_registry import TOOLS
from core.agent_memory import set_last_contract_id, get_last_contract_id


class ContractAgentState(TypedDict):
    session_id: str
    message: str
    plan: Dict[str, Any]
    observations: List[Dict[str, Any]]
    final_answer: str
    metrics: Dict[str, Any]
    success: bool
    start_time: float


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
        logger.exception("Erreur parsing JSON LangGraph planner")
        return {"steps": [{"tool": "help", "arguments": {}}]}


def planner_node(state: ContractAgentState) -> ContractAgentState:
    message = state["message"]

    prompt = f"""
Tu es un AI Contract Agent avancé utilisant LangGraph.

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

Utilisateur: Compare le contrat 1 et le contrat 2
Réponse:
{{"steps":[{{"tool":"compare_contracts","arguments":{{"contract_id_1":1,"contract_id_2":2}}}}]}}

Utilisateur:
{message}
"""

    model = choose_model("planning")
    logger.info("LANGGRAPH MODEL SELECTED FOR PLANNING: %s", model)

    response = run_agent(model, prompt)
    plan = clean_json(response)

    logger.info("LANGGRAPH PLAN: %s", plan)

    state["plan"] = plan
    return state


def tool_executor_node(state: ContractAgentState) -> ContractAgentState:
    session_id = state["session_id"]
    message = state["message"]
    observations = []
    success = True

    for step in state["plan"].get("steps", []):
        tool_name = step.get("tool")
        args = step.get("arguments", {}) or {}

        if not isinstance(args, dict):
            args = {}

        if args.get("contract_id") is None:
            last_id = get_last_contract_id(session_id)
            if last_id:
                args["contract_id"] = last_id

        logger.info("LANGGRAPH TOOL EXECUTED: %s", step)

        try:
            if tool_name == "create_contract":
                result = run_ai_contract_agent(session_id, message)
            else:
                tool = TOOLS.get(tool_name)

                if tool is None:
                    result = {"error": f"Outil inconnu : {tool_name}"}
                else:
                    result = tool(**args)

            if isinstance(result, dict):
                if result.get("id"):
                    set_last_contract_id(session_id, result["id"])

                if result.get("error"):
                    success = False

            logger.info("LANGGRAPH TOOL RESULT: %s", result)

        except Exception as e:
            success = False
            logger.exception("Erreur outil LangGraph")
            result = {
                "error": str(e),
                "tool": tool_name,
            }

        observations.append({
            "tool": tool_name,
            "arguments": args,
            "result": result,
        })

    state["observations"] = observations
    state["success"] = success
    return state


def final_answer_node(state: ContractAgentState) -> ContractAgentState:
    message = state["message"]
    plan = state["plan"]
    observations = state["observations"]

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
    logger.info("LANGGRAPH MODEL SELECTED FOR FINAL ANSWER: %s", model)

    try:
        final_answer = run_agent(model, prompt)
    except Exception as e:
        state["success"] = False
        logger.exception("Erreur réponse finale LangGraph")
        final_answer = f"Erreur lors de la génération de la réponse finale : {e}"

    state["final_answer"] = final_answer

    state["metrics"] = {
        "execution_time_seconds": round(time.time() - state["start_time"], 2),
        "tools_used": len(observations),
        "success": state["success"],
    }

    logger.info("LANGGRAPH FINAL ANSWER: %s", final_answer)
    logger.info("LANGGRAPH METRICS: %s", state["metrics"])

    return state


def build_langgraph_agent():
    graph = StateGraph(ContractAgentState)

    graph.add_node("planner", planner_node)
    graph.add_node("tools", tool_executor_node)
    graph.add_node("final_answer", final_answer_node)

    graph.add_edge(START, "planner")
    graph.add_edge("planner", "tools")
    graph.add_edge("tools", "final_answer")
    graph.add_edge("final_answer", END)

    return graph.compile()


LANGGRAPH_AGENT = build_langgraph_agent()


def run_langgraph_agent(session_id: str, message: str) -> dict:
    conversation_agent = ConversationAgent()
    session = get_session(session_id)

    if session and not conversation_agent.is_complete(session):
        result = run_ai_contract_agent(session_id, message)

        return {
            "agent": "LangGraph Contract Agent",
            "mode": "conversation_continuation",
            "result": result,
        }

    initial_state: ContractAgentState = {
        "session_id": session_id,
        "message": message,
        "plan": {},
        "observations": [],
        "final_answer": "",
        "metrics": {},
        "success": True,
        "start_time": time.time(),
    }

    final_state = LANGGRAPH_AGENT.invoke(initial_state)

    return {
        "agent": "LangGraph Contract Agent",
        "plan": final_state["plan"],
        "observations": final_state["observations"],
        "final_answer": final_state["final_answer"],
        "metrics": final_state["metrics"],
    }