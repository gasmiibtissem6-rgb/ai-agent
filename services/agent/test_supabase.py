from database import supabase

try:
    response = supabase.table("deals").select("*").limit(5).execute()
    print("✅ Connexion réussie !")
    print(response.data)
except Exception as e:
    print("❌ Erreur :", e)
