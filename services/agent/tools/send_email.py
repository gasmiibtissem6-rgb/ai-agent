import os
import smtplib
from email.mime.text import MIMEText
from dotenv import load_dotenv
import resend

load_dotenv()

resend.api_key = os.getenv("RESEND_API_KEY")


def _send_via_resend(to: str, subject: str, body: str) -> str:
    resend.Emails.send({
        "from": "onboarding@resend.dev",
        "to": to,
        "subject": subject,
        "text": body,
    })
    return f"Email envoyé à {to} via Resend."


def _send_via_gmail(to: str, subject: str, body: str) -> str:
    gmail_address = os.getenv("GMAIL_ADDRESS")
    gmail_password = os.getenv("GMAIL_APP_PASSWORD")

    msg = MIMEText(body)
    msg["Subject"] = subject
    msg["From"] = gmail_address
    msg["To"] = to

    with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
        server.login(gmail_address, gmail_password)
        server.sendmail(gmail_address, [to], msg.as_string())

    return f"Email envoyé à {to} via Gmail."


def send_email(to: str, subject: str, body: str) -> str:
    """Envoie un email via le fournisseur configuré (resend ou gmail)."""
    provider = os.getenv("EMAIL_PROVIDER", "resend")

    if provider == "gmail":
        return _send_via_gmail(to, subject, body)
    return _send_via_resend(to, subject, body)
