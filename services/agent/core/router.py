def route_step(step: dict) -> dict:
    """
    Le planner a déjà choisi le bon outil.
    Le router se contente de transmettre cette décision.
    """

    return {
        "selected_tool": step.get("tool"),
        "selected_model": step.get("model", "openai"),
    }