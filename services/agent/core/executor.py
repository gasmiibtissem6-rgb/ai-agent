from tools.create_contract import create_contract
from tools.analyze_contract import analyze_contract
from tools.compare_contracts import compare_contracts
from tools.analyze_image import analyze_image
from tools.generate_contract_content import generate_contract_content
from tools.generate_pdf import generate_pdf


LAST_GENERATED_CONTRACT = {
    "title": None,
    "content": None,
    "contract_type": None,
}


def execute_step(message: str, step: dict):
    tool = step.get("selected_tool")
    model = step.get("selected_model")

    if tool == "create_contract":
        generated = generate_contract_content(message)

        LAST_GENERATED_CONTRACT["title"] = generated.get("title", "Contrat")
        LAST_GENERATED_CONTRACT["content"] = generated.get("content", message)
        LAST_GENERATED_CONTRACT["contract_type"] = generated.get("contract_type", "Service")

        result = create_contract(
            title=LAST_GENERATED_CONTRACT["title"],
            content=LAST_GENERATED_CONTRACT["content"],
            contract_type=LAST_GENERATED_CONTRACT["contract_type"],
        )

        return result

    if tool == "analyze_contract":
        content = LAST_GENERATED_CONTRACT["content"] or message
        return analyze_contract(content)

    if tool == "generate_pdf":
        title = LAST_GENERATED_CONTRACT["title"] or "Contrat"
        content = LAST_GENERATED_CONTRACT["content"] or message
        return generate_pdf(title, content)

    if tool == "compare_contracts":
        return compare_contracts(message)

    if tool == "analyze_image":
        return analyze_image(message)

    return "Aucune action exécutée."