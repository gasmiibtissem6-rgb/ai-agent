# Architecture du AI Contract Agent

## Architecture générale

Utilisateur
↓
FastAPI
↓
LLM Tool Calling Agent
↓
Planner LLM
↓
Tool Registry
↓
Tools
↓
SQLite / PDF / Logs

---

## Composants principaux

### FastAPI

Expose les endpoints REST :

- `/llm-agent`
- `/agent`
- `/contracts`
- `/ai-contract-agent`

### LLM Tool Calling Agent

Responsable de :

- comprendre la demande utilisateur
- générer un plan
- choisir les outils
- exécuter plusieurs actions
- produire une réponse finale

### Tool Registry

Contient les outils disponibles :

- list_contracts
- search_contracts
- summarize_contract
- analyze_contract
- compare_contracts
- update_contract
- delete_contract

### Database

Stocke les contrats dans SQLite.

### PDF Generator

Génère les contrats sous format PDF.

### Logger

Enregistre les actions dans :

```text
logs/agent.log