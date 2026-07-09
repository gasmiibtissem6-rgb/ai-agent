from typing import Dict, List


class ConversationAgent:

    def __init__(self):
        self.required_fields = [
            "contract_type",
            "provider_name",
            "client_name",
            "provider_address",
            "client_address",
            "provider_email",
            "client_email",
            "provider_phone",
            "client_phone",
            "duration",
            "price",
            "payment_method",
            "place",
        ]

        self.questions = {
            "contract_type": "Quel type de contrat souhaitez-vous créer ?",
            "provider_name": "Quel est le nom du prestataire ?",
            "client_name": "Quel est le nom du client ?",
            "provider_address": "Quelle est l'adresse du prestataire ?",
            "client_address": "Quelle est l'adresse du client ?",
            "provider_email": "Quel est l'email du prestataire ?",
            "client_email": "Quel est l'email du client ?",
            "provider_phone": "Quel est le téléphone du prestataire ?",
            "client_phone": "Quel est le téléphone du client ?",
            "duration": "Quelle est la durée du contrat ?",
            "price": "Quel est le montant du contrat ?",
            "payment_method": "Quel est le mode de paiement ?",
            "place": "Dans quelle ville sera signé le contrat ?",
        }

    def missing_fields(self, data: Dict) -> List[str]:
        return [
            field
            for field in self.required_fields
            if not data.get(field)
        ]

    def next_field(self, data: Dict):
        missing = self.missing_fields(data)
        return missing[0] if missing else None

    def next_question(self, data: Dict):
        field = self.next_field(data)
        if not field:
            return None
        return self.questions[field]

    def save_answer(self, data: Dict, answer: str) -> Dict:
        field = self.next_field(data)

        if field:
            data[field] = answer

        return data

    def is_complete(self, data: Dict):
        return len(self.missing_fields(data)) == 0

    def build_prompt(self, data: Dict):
        return f"""
Tu es un juriste professionnel.

Rédige un contrat professionnel complet avec les informations suivantes :

Type de contrat : {data["contract_type"]}

Prestataire :
Nom : {data["provider_name"]}
Adresse : {data["provider_address"]}
Téléphone : {data["provider_phone"]}
Email : {data["provider_email"]}

Client :
Nom : {data["client_name"]}
Adresse : {data["client_address"]}
Téléphone : {data["client_phone"]}
Email : {data["client_email"]}

Durée : {data["duration"]}
Prix : {data["price"]}
Mode de paiement : {data["payment_method"]}
Lieu de signature : {data["place"]}

Le contrat doit être clair, professionnel, structuré et juridiquement cohérent.
"""