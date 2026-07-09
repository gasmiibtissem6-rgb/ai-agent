from database.db import SessionLocal
from database.models import Contract


def search_contracts(filters: dict):
    db = SessionLocal()

    try:
        query = db.query(Contract)

        if filters.get("client_name"):
            query = query.filter(
                Contract.client_name.ilike(f"%{filters['client_name']}%")
            )

        if filters.get("provider_name"):
            query = query.filter(
                Contract.provider_name.ilike(f"%{filters['provider_name']}%")
            )

        if filters.get("contract_type"):
            query = query.filter(
                Contract.contract_type.ilike(f"%{filters['contract_type']}%")
            )

        if filters.get("place"):
            query = query.filter(
                Contract.place.ilike(f"%{filters['place']}%")
            )

        if filters.get("payment_method"):
            query = query.filter(
                Contract.payment_method.ilike(f"%{filters['payment_method']}%")
            )

        return query.order_by(Contract.id.desc()).all()

    finally:
        db.close()