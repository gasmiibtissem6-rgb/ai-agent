from database import get_connection

def create_contract(title: str, content: str, contract_type: str = "Service") -> str:
    """Crée un nouveau contrat dans la base de données."""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        "INSERT INTO contracts (title, content, contract_type) VALUES (%s, %s, %s) RETURNING id;",
        (title, content, contract_type),
    )
    new_id = cur.fetchone()[0]
    conn.commit()
    cur.close()
    conn.close()
    return f"Contrat {new_id} créé : \"{title}\" ({contract_type})"
