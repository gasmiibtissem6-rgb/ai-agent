from core.planner import plan_task
from core.router import route_step
from core.executor import execute_step


def run_smart_contract_agent(message: str) -> dict:
    plan = plan_task(message)

    executed_steps = []

    for raw_step in plan["steps"]:
        routed_step = route_step(raw_step)
        result = execute_step(message, routed_step)

        executed_steps.append({
            "tool": routed_step["selected_tool"],
            "model": routed_step["selected_model"],
            "result": result
        })

    return {
        "agent": "Smart Contract Agent Core",
        "task_type": plan["task_type"],
        "execution_plan": executed_steps,
        "final_answer": executed_steps[-1]["result"] if executed_steps else "Je peux vous aider à créer, analyser ou comparer un contrat."
    }