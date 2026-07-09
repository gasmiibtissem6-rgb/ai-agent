def choose_model(task_type: str) -> str:
    model_map = {
        "planning": "groq",
        "final_answer": "groq",
        "contract_generation": "openai",
        "legal_analysis": "mistral",
        "summary": "groq",
        "comparison": "mistral",
        "image_analysis": "gemini",
        "ocr": "gemini",
        "fast_chat": "groq",
        "default": "groq",
    }

    return model_map.get(task_type, model_map["default"])
