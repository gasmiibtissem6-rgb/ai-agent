from typing import TypedDict, Optional, List, Dict, Any


class AgentState(TypedDict, total=False):
    user_message: str
    task_type: str
    selected_model: str
    selected_tool: Optional[str]
    steps: List[Dict[str, Any]]
    result: Optional[str]