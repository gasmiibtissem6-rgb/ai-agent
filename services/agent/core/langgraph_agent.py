import json
import re
import time
from typing import Any, Dict, List, TypedDict

from langgraph.graph import END, START, StateGraph

from models.router import route_to_model
from agent.session_store import get_session
from agent.conversation_agent import ConversationAgent

from core.ai_contract_agent import run_ai_contract_agent
from core.logger import logger
from core.model_router import choose_model
from core.tool_registry import TOOLS
from core.agent_memory import (
    set_last_contract_id,
    get_last_contract_id,
)


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
    """
    Extrait et valide le plan JSON retourné par le modèle.
    """

    if not isinstance(text, str):
        logger.error(
            "Réponse du Planner invalide : type=%s",
            type(text).__name__,
        )

        return {
            "steps": [
                {
                    "tool": "help",
                    "arguments": {},
                }
            ]
        }

    match = re.search(
        r"\{.*\}",
        text.strip(),
        re.DOTALL,
    )

    if not match:
        logger.error(
            "Aucun JSON trouvé dans la réponse du Planner : %s",
            text,
        )

        return {
            "steps": [
                {
                    "tool": "help",
                    "arguments": {},
                }
            ]
        }

    try:
        data = json.loads(match.group())

        if "steps" not in data:
            data = {
                "steps": [data]
            }

        if not isinstance(data["steps"], list):
            raise ValueError(
                "Le champ steps doit être une liste."
            )

        return data

    except Exception:
        logger.exception(
            "Erreur parsing JSON LangGraph Planner"
        )

        return {
            "steps": [
                {
                    "tool": "help",
                    "arguments": {},
                }
            ]
        }


def planner_node(
    state: ContractAgentState,
) -> ContractAgentState:
    """
    Analyse la demande utilisateur et produit un plan d'outils.
    """

    message = state["message"]

    prompt = f"""
Tu es un AI Contract Agent avancé utilisant LangGraph.

Tu dois choisir un ou plusieurs outils à exécuter selon la demande utilisateur.

Outils disponibles :

1. create_contract
   - Créer un nouveau contrat.

2. list_contracts
   - Lister les contrats enregistrés.

3. get_contract
   - Récupérer les informations générales d'un contrat.

4. search_contracts
   - Rechercher des contrats selon des critères :
     type, client, prestataire, lieu, etc.

5. update_contract
   - Modifier un contrat enregistré.

6. delete_contract
   - Supprimer un contrat.

7. summarize_contract
   - Résumer globalement un contrat.

8. analyze_contract
   - Analyser les risques juridiques, les informations manquantes
     et produire des recommandations.

9. compare_contracts
   - Comparer deux contrats enregistrés.

10. index_contract_rag
    - Indexer un contrat dans la base vectorielle.

11. search_contract_rag
    - Rechercher une information précise dans le contenu réel
      d'un contrat grâce au RAG, à ChromaDB et au re-ranking.

RÈGLES IMPORTANTES :

- Si l'utilisateur pose une question précise sur le contenu d'un contrat,
  utilise TOUJOURS search_contract_rag.

Exemples de questions qui nécessitent search_contract_rag :

- Que dit le contrat sur la confidentialité ?
- Quelle est la clause de résiliation ?
- Comment le paiement est-il prévu ?
- Quelles sont les obligations du client ?
- Quelle est la durée du contrat ?
- Que prévoit le contrat en cas de litige ?
- Le contrat parle-t-il de responsabilité ?

- Utilise analyze_contract uniquement si l'utilisateur demande :
  une analyse juridique, les risques, les faiblesses,
  les informations manquantes ou des recommandations.

- N'ajoute pas d'argument inconnu comme "focus"
  dans analyze_contract.

- Pour search_contract_rag, utilise par défaut :
  n_results = 8
  max_distance = 0.70
  top_k = 3

- Ne sélectionne que des outils présents dans la liste.

- Réponds uniquement avec un JSON valide.
- Ne mets aucun texte avant ou après le JSON.
- Ne mets pas de bloc Markdown.

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

Utilisateur : Liste les contrats

Réponse :
{{
  "steps": [
    {{
      "tool": "list_contracts",
      "arguments": {{}}
    }}
  ]
}}

Utilisateur : Résume le contrat 1

Réponse :
{{
  "steps": [
    {{
      "tool": "summarize_contract",
      "arguments": {{
        "contract_id": 1
      }}
    }}
  ]
}}

Utilisateur : Analyse les risques juridiques du contrat 1

Réponse :
{{
  "steps": [
    {{
      "tool": "analyze_contract",
      "arguments": {{
        "contract_id": 1
      }}
    }}
  ]
}}

Utilisateur : Que dit le contrat 1 sur la confidentialité ?

Réponse :
{{
  "steps": [
    {{
      "tool": "search_contract_rag",
      "arguments": {{
        "query": "confidentialité",
        "contract_id": 1,
        "n_results": 8,
        "max_distance": 0.70,
        "top_k": 3
      }}
    }}
  ]
}}

Utilisateur : Quelle est la clause de résiliation du contrat 2 ?

Réponse :
{{
  "steps": [
    {{
      "tool": "search_contract_rag",
      "arguments": {{
        "query": "clause de résiliation",
        "contract_id": 2,
        "n_results": 8,
        "max_distance": 0.70,
        "top_k": 3
      }}
    }}
  ]
}}

Utilisateur : Compare le contrat 1 et le contrat 2

Réponse :
{{
  "steps": [
    {{
      "tool": "compare_contracts",
      "arguments": {{
        "contract_id_1": 1,
        "contract_id_2": 2
      }}
    }}
  ]
}}

Demande actuelle de l'utilisateur :

{message}
"""

    model = choose_model("planning")

    logger.info(
        "LANGGRAPH MODEL SELECTED FOR PLANNING: %s",
        model,
    )

    try:
        response = route_to_model(
            model,
            prompt,
        )

        plan = clean_json(response)

    except Exception:
        logger.exception(
            "Erreur pendant la planification LangGraph"
        )

        state["success"] = False

        plan = {
            "steps": [
                {
                    "tool": "help",
                    "arguments": {},
                }
            ]
        }

    logger.info(
        "LANGGRAPH PLAN: %s",
        plan,
    )

    state["plan"] = plan

    return state


def tool_executor_node(
    state: ContractAgentState,
) -> ContractAgentState:
    """
    Exécute les outils sélectionnés par le Planner.
    """

    session_id = state["session_id"]
    message = state["message"]

    observations: List[Dict[str, Any]] = []
    success = state.get("success", True)

    steps = state["plan"].get(
        "steps",
        [],
    )

    if not isinstance(steps, list):
        steps = []

    for step in steps:
        if not isinstance(step, dict):
            success = False

            observations.append({
                "tool": None,
                "arguments": {},
                "result": {
                    "error": "Étape du plan invalide."
                },
            })

            continue

        tool_name = step.get("tool")
        args = step.get("arguments", {}) or {}

        if not isinstance(args, dict):
            args = {}

        if (
            tool_name
            not in {
                "compare_contracts",
                "search_contracts",
                "list_contracts",
                "create_contract",
            }
            and args.get("contract_id") is None
        ):
            last_id = get_last_contract_id(
                session_id
            )

            if last_id is not None:
                args["contract_id"] = last_id

        logger.info(
            "LANGGRAPH TOOL EXECUTED: tool=%s args=%s",
            tool_name,
            args,
        )

        try:
            if tool_name == "create_contract":
                result = run_ai_contract_agent(
                    session_id=session_id,
                    message=message,
                )

            else:
                tool = TOOLS.get(tool_name)

                if tool is None:
                    result = {
                        "error": (
                            f"Outil inconnu : {tool_name}"
                        )
                    }

                else:
                    result = tool(**args)

            if isinstance(result, dict):
                result_contract_id = (
                    result.get("id")
                    or result.get("contract_id")
                )

                if isinstance(
                    result_contract_id,
                    int,
                ):
                    set_last_contract_id(
                        session_id,
                        result_contract_id,
                    )

                if result.get("error"):
                    success = False

            logger.info(
                "LANGGRAPH TOOL RESULT: %s",
                result,
            )

        except Exception as error:
            success = False

            logger.exception(
                "Erreur outil LangGraph : %s",
                tool_name,
            )

            result = {
                "error": str(error),
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


def final_answer_node(
    state: ContractAgentState,
) -> ContractAgentState:
    """
    Produit une réponse finale à partir des résultats des outils.
    """

    message = state["message"]
    plan = state["plan"]
    observations = state["observations"]

    prompt = f"""
Tu es un assistant professionnel spécialisé dans la gestion
et l'analyse de contrats.

Question utilisateur :

{message}

Plan exécuté :

{json.dumps(
    plan,
    ensure_ascii=False,
    default=str,
)}

Résultats des outils :

{json.dumps(
    observations,
    ensure_ascii=False,
    default=str,
)}

Instructions :

- Réponds uniquement en français.
- Utilise uniquement les informations réellement présentes
  dans les résultats des outils.
- Ne crée aucune information absente des résultats.
- Ne montre pas le JSON brut.
- Donne une réponse claire, précise et structurée.
- Si aucun passage pertinent n'a été trouvé, indique-le clairement.
- Si un outil a échoué, explique brièvement le problème.
- Ne présente pas une recommandation comme une clause déjà présente.
"""

    model = choose_model(
        "final_answer"
    )

    logger.info(
        "LANGGRAPH MODEL SELECTED FOR FINAL ANSWER: %s",
        model,
    )

    try:
        final_answer = route_to_model(
            model,
            prompt,
        )

    except Exception as error:
        state["success"] = False

        logger.exception(
            "Erreur réponse finale LangGraph"
        )

        final_answer = (
            "Erreur lors de la génération de la réponse "
            f"finale : {error}"
        )

    state["final_answer"] = final_answer

    state["metrics"] = {
        "execution_time_seconds": round(
            time.time() - state["start_time"],
            2,
        ),
        "tools_used": len(observations),
        "success": state["success"],
    }

    logger.info(
        "LANGGRAPH FINAL ANSWER: %s",
        final_answer,
    )

    logger.info(
        "LANGGRAPH METRICS: %s",
        state["metrics"],
    )

    return state


def build_langgraph_agent():
    """
    Construit et compile le workflow LangGraph.
    """

    graph = StateGraph(
        ContractAgentState
    )

    graph.add_node(
        "planner",
        planner_node,
    )

    graph.add_node(
        "tools",
        tool_executor_node,
    )

    graph.add_node(
        "final_answer",
        final_answer_node,
    )

    graph.add_edge(
        START,
        "planner",
    )

    graph.add_edge(
        "planner",
        "tools",
    )

    graph.add_edge(
        "tools",
        "final_answer",
    )

    graph.add_edge(
        "final_answer",
        END,
    )

    return graph.compile()


LANGGRAPH_AGENT = build_langgraph_agent()


def run_langgraph_agent(
    session_id: str,
    message: str,
) -> dict:
    """
    Lance l'AI Contract Agent LangGraph.
    """

    if not session_id or not session_id.strip():
        return {
            "agent": "LangGraph Contract Agent",
            "error": "session_id est obligatoire.",
        }

    if not message or not message.strip():
        return {
            "agent": "LangGraph Contract Agent",
            "error": "Le message utilisateur est vide.",
        }

    conversation_agent = ConversationAgent()

    session = get_session(
        session_id
    )

    if (
        session
        and not conversation_agent.is_complete(
            session
        )
    ):
        result = run_ai_contract_agent(
            session_id=session_id,
            message=message,
        )

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

    try:
        final_state = LANGGRAPH_AGENT.invoke(
            initial_state
        )

    except Exception as error:
        logger.exception(
            "Erreur générale LangGraph"
        )

        return {
            "agent": "LangGraph Contract Agent",
            "error": str(error),
            "metrics": {
                "execution_time_seconds": round(
                    time.time()
                    - initial_state["start_time"],
                    2,
                ),
                "tools_used": 0,
                "success": False,
            },
        }

    return {
        "agent": "LangGraph Contract Agent",
        "plan": final_state.get(
            "plan",
            {},
        ),
        "observations": final_state.get(
            "observations",
            [],
        ),
        "final_answer": final_state.get(
            "final_answer",
            "",
        ),
        "metrics": final_state.get(
            "metrics",
            {},
        ),
    }