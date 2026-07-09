# Rapport de Projet — AI Contract Agent

## 1. Introduction

Ce projet consiste à développer un agent intelligent capable de créer, gérer, analyser et résumer des contrats à l'aide de l'intelligence artificielle.

## 2. Problématique

La création et l'analyse de contrats nécessitent du temps, de la précision et une bonne compréhension juridique. L'objectif est d'automatiser une partie de ce processus à l'aide d'un agent IA.

## 3. Objectifs

- Créer des contrats automatiquement.
- Générer des PDF.
- Sauvegarder les contrats.
- Rechercher des contrats.
- Résumer automatiquement un contrat.
- Analyser les risques juridiques.
- Utiliser un agent avec Tool Calling.

## 4. Architecture

Le système repose sur :

- FastAPI
- LLM Planner
- Tool Registry
- SQLite
- Génération PDF
- Logging
- Mémoire conversationnelle

## 5. Fonctionnement de l'agent

L'utilisateur envoie une demande en langage naturel.

Le LLM génère un plan.

Le système exécute les outils nécessaires.

L'agent produit une réponse finale claire.

## 6. Tool Calling

Le Tool Calling permet à l'agent de choisir automatiquement les outils à utiliser.

Exemple :

```json
{
  "steps": [
    {"tool": "list_contracts"},
    {"tool": "summarize_contract"},
    {"tool": "analyze_contract"}
  ]
}