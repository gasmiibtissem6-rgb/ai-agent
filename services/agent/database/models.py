from sqlalchemy import Column
from sqlalchemy import Integer
from sqlalchemy import String
from sqlalchemy import DateTime
from sqlalchemy.sql import func

from database.db import Base


class Contract(Base):
    __tablename__ = "contracts"

    id = Column(Integer, primary_key=True, index=True)

    reference = Column(String, unique=True)

    contract_type = Column(String)

    provider_name = Column(String)

    client_name = Column(String)

    provider_email = Column(String)

    client_email = Column(String)

    provider_phone = Column(String)

    client_phone = Column(String)

    provider_address = Column(String)

    client_address = Column(String)

    duration = Column(String)

    price = Column(String)

    payment_method = Column(String)

    place = Column(String)

    pdf_path = Column(String)

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )