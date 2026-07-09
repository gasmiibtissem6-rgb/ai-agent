AGENT_MEMORY = {}


def get_memory(session_id: str) -> dict:
    if session_id not in AGENT_MEMORY:
        AGENT_MEMORY[session_id] = {}

    return AGENT_MEMORY[session_id]


def set_last_contract_id(session_id: str, contract_id: int):
    memory = get_memory(session_id)
    memory["last_contract_id"] = contract_id


def get_last_contract_id(session_id: str):
    memory = get_memory(session_id)
    return memory.get("last_contract_id")