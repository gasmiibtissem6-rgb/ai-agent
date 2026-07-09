# AI Contract Agent

## Présentation

AI Contract Agent est un agent intelligent de gestion de contrats développé avec FastAPI et un modèle de langage (LLM).

L'agent est capable de comprendre les demandes de l'utilisateur, planifier les actions à effectuer, sélectionner automatiquement les outils nécessaires et produire une réponse en langage naturel.

Le système combine :

- Intelligence artificielle
- Tool Calling
- Mémoire conversationnelle
- Génération de contrats
- Analyse juridique
- Résumé automatique
- Comparaison de contrats
- Recherche intelligente
- Génération PDF

---

# Architecture

Utilisateur
↓
FastAPI
↓
LLM Planner
↓
Tool Registry
↓
Tools
↓
SQLite

---

# Fonctionnalités

## Création de contrat

Création guidée d'un contrat par conversation.

## Génération PDF

Production automatique d'un document PDF.

## Recherche intelligente

Exemple :

Montre-moi les contrats de coaching à Djerba.

## Résumé automatique

Résume le contrat 1.

## Analyse juridique

Analyse des risques.

Détection :

- clauses manquantes
- niveau de risque
- recommandations

## Comparaison

Comparer deux contrats.

## Mémoire

L'agent comprend :

Analyse-le

après

Affiche le contrat 1

## Tool Calling

Le LLM décide lui-même quels outils utiliser.

## Logging

Tous les appels sont enregistrés dans

logs/agent.log

## Metrics

Chaque requête retourne :

- temps d'exécution
- nombre d'outils utilisés
- succès

---

# Technologies

- Python
- FastAPI
- SQLite
- SQLAlchemy
- Groq API
- LLM
- Pydantic

---

# Installation

```bash
git clone <repository>

cd AI-Contract-Agent

pip install -r requirements.txt

uvicorn main:app --reload
```

---

# API

## POST /llm-agent

Exemple :

```json
{
  "session_id": "demo",
  "message": "Liste les contrats puis résume le contrat 1 et analyse-le"
}
```

---

