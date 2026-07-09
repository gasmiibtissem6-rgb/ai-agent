from database import get_connection

def send_notification(recipient: str, message: str) -> str:
    """Écrit une notification dans la base de données."""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        "INSERT INTO notifications (recipient, message) VALUES (%s, %s) RETURNING id;",
        (recipient, message),
    )
    new_id = cur.fetchone()[0]
    conn.commit()
    cur.close()
    conn.close()
    return f"Notification {new_id} envoyée à {recipient} : {message}"
