from database.db import SessionLocal, engine
from database.models import Base, Contract

Base.metadata.create_all(bind=engine)


def save_contract(data: dict, contract: dict, pdf_result: str):
    print(">>> save_contract appelé")

    db = SessionLocal()

    try:
        pdf_path = pdf_result.replace("PDF généré avec succès : ", "")

        new_contract = Contract(
            reference=data.get("reference"),
            contract_type=data.get("contract_type"),
            provider_name=data.get("provider_name"),
            client_name=data.get("client_name"),
            provider_email=data.get("provider_email"),
            client_email=data.get("client_email"),
            provider_phone=data.get("provider_phone"),
            client_phone=data.get("client_phone"),
            provider_address=data.get("provider_address"),
            client_address=data.get("client_address"),
            duration=data.get("duration"),
            price=data.get("price"),
            payment_method=data.get("payment_method"),
            place=data.get("place"),
            pdf_path=pdf_path,
        )

        db.add(new_contract)
        db.commit()
        db.refresh(new_contract)

        print(f">>> Contrat sauvegardé avec l'id : {new_contract.id}")

        return new_contract

    except Exception as e:
        db.rollback()
        print(f">>> Erreur lors de la sauvegarde : {e}")
        raise

    finally:
        db.close()
def list_saved_contracts():
    db = SessionLocal()

    try:
        contracts = (
            db.query(Contract)
            .order_by(Contract.id.desc())
            .all()
        )

        return contracts

    finally:
        db.close()


def get_contract_by_id(contract_id: int):
    db = SessionLocal()

    try:
        return (
            db.query(Contract)
            .filter(Contract.id == contract_id)
            .first()
        )

    finally:
        db.close()
def delete_contract_by_id(contract_id: int):
    db = SessionLocal()

    try:
        contract = (
            db.query(Contract)
            .filter(Contract.id == contract_id)
            .first()
        )

        if not contract:
            return None

        db.delete(contract)
        db.commit()

        return contract

    finally:
        db.close()
def update_contract_by_id(contract_id: int, data: dict):
    db = SessionLocal()

    try:
        contract = (
            db.query(Contract)
            .filter(Contract.id == contract_id)
            .first()
        )

        if not contract:
            return None

        for key, value in data.items():
            if value is not None and hasattr(contract, key):
                setattr(contract, key, value)

        db.commit()
        db.refresh(contract)

        return contract

    finally:
        db.close()                        