import os
import psycopg2
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_ANON_KEY")
DATABASE_URL = os.getenv("DATABASE_URL")

if not SUPABASE_URL or not SUPABASE_KEY:
    raise ValueError("SUPABASE_URL ou SUPABASE_ANON_KEY manquant dans le .env")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def get_connection():
    """Retourne une connexion PostgreSQL brute (psycopg2) via DATABASE_URL."""
    if not DATABASE_URL:
        raise ValueError("DATABASE_URL manquant dans le .env")
    return psycopg2.connect(DATABASE_URL)