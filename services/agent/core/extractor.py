import re


EMAIL_REGEX = r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"
PHONE_REGEX = r"(?:\+?\d{1,3}\s?)?(?:\d[\s.-]?){8,15}"


def clean_value(value: str) -> str:
    value = value.strip()
    value = value.strip(".,;:")
    return value.strip()


def extract_email(text: str):
    match = re.search(EMAIL_REGEX, text)
    return match.group() if match else None


def extract_phone(text: str):
    match = re.search(PHONE_REGEX, text)
    return clean_value(match.group()) if match else None


def extract_contract_type(lower: str):
    if "coaching sportif" in lower:
        return "Contrat de coaching sportif"
    if "location" in lower:
        return "Contrat de location"
    if "travail" in lower:
        return "Contrat de travail"
    if "vente" in lower:
        return "Contrat de vente"
    if "plombier" in lower or "plomberie" in lower:
        return "Contrat de prestation de plomberie"
    if "électricien" in lower or "electricien" in lower:
        return "Contrat de prestation électrique"
    if "prestation" in lower:
        return "Contrat de prestation de services"
    return None


def extract_price(lower: str):
    match = re.search(r"\d+\s*(dt|dinar|dinars|€|eur|euro|euros)", lower)
    return match.group() if match else None


def extract_duration(lower: str):
    match = re.search(
        r"\d+\s*(jour|jours|semaine|semaines|mois|an|ans|année|années)",
        lower,
    )
    return match.group() if match else None


def extract_payment_method(lower: str):
    if "virement" in lower:
        return "Virement bancaire"
    if "chèque" in lower or "cheque" in lower:
        return "Chèque"
    if "espèce" in lower or "espece" in lower or "cash" in lower:
        return "Espèces"
    return None


def extract_place(text: str):
    patterns = [
        r"(?:à|a)\s+([A-Za-zÀ-ÿ\s-]+?)(?:,|\.|$)",
        r"ville\s*:?\s*([A-Za-zÀ-ÿ\s-]+?)(?:,|\.|$)",
        r"lieu\s*:?\s*([A-Za-zÀ-ÿ\s-]+?)(?:,|\.|$)",
    ]

    for pattern in patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            place = clean_value(match.group(1))
            if len(place.split()) <= 4:
                return place

    return None


def extract_between_parties(text: str):
    match = re.search(
        r"entre\s+(.+?)\s+et\s+(.+?)(?:\s+pour|\s+à|\s+a\s+|\s+avec|\s+paiement|,|\.|$)",
        text,
        re.IGNORECASE,
    )

    if not match:
        return {}

    return {
        "provider_name": clean_value(match.group(1)),
        "client_name": clean_value(match.group(2)),
    }


def extract_provider_info(text: str):
    data = {}
    lower = text.lower()

    if not any(word in lower for word in ["je suis", "prestataire", "mon entreprise", "nous sommes"]):
        return data

    name_patterns = [
        r"je suis\s+(.+?)(?:,|\.|$)",
        r"prestataire\s*:?\s*(.+?)(?:,|\.|$)",
        r"mon entreprise\s+(?:est|s'appelle)?\s*(.+?)(?:,|\.|$)",
        r"nous sommes\s+(.+?)(?:,|\.|$)",
    ]

    for pattern in name_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            data["provider_name"] = clean_value(match.group(1))
            break

    email = extract_email(text)
    if email:
        data["provider_email"] = email

    phone = extract_phone(text)
    if phone:
        data["provider_phone"] = phone

    address_patterns = [
        r"adresse\s*:?\s*(.+?)(?:,|\.|$)",
        r"situé(?:e)?\s+à\s+(.+?)(?:,|\.|$)",
        r"basé(?:e)?\s+à\s+(.+?)(?:,|\.|$)",
    ]

    for pattern in address_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            data["provider_address"] = clean_value(match.group(1))
            break

    return data


def extract_client_info(text: str):
    data = {}
    lower = text.lower()

    if "client" not in lower:
        return data

    name_patterns = [
        r"client\s*:?\s*(.+?)(?:,|\.|$)",
        r"le client est\s+(.+?)(?:,|\.|$)",
        r"client\s+s'appelle\s+(.+?)(?:,|\.|$)",
    ]

    for pattern in name_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            data["client_name"] = clean_value(match.group(1))
            break

    email = extract_email(text)
    if email:
        data["client_email"] = email

    phone = extract_phone(text)
    if phone:
        data["client_phone"] = phone

    address_patterns = [
        r"adresse\s*:?\s*(.+?)(?:,|\.|$)",
        r"habite\s+à\s+(.+?)(?:,|\.|$)",
        r"situé(?:e)?\s+à\s+(.+?)(?:,|\.|$)",
    ]

    for pattern in address_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            data["client_address"] = clean_value(match.group(1))
            break

    return data


def extract_information(text: str) -> dict:
    data = {}
    lower = text.lower()

    contract_type = extract_contract_type(lower)
    if contract_type:
        data["contract_type"] = contract_type

    price = extract_price(lower)
    if price:
        data["price"] = price

    duration = extract_duration(lower)
    if duration:
        data["duration"] = duration

    payment_method = extract_payment_method(lower)
    if payment_method:
        data["payment_method"] = payment_method

    place = extract_place(text)
    if place:
        data["place"] = place

    data.update(extract_between_parties(text))
    data.update(extract_provider_info(text))
    data.update(extract_client_info(text))

    return data