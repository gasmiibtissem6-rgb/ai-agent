# AGENTS.md

## Project rules

- Follow README.md as the source of truth for project purpose.
- Keep the monorepo structure clean.
- Mobile app code belongs in apps/mobile.
- Admin dashboard code belongs in apps/admin.
- Backend API code belongs in services/api.
- Do not move project folders unless required.
- Do not add heavy dependencies unless necessary.
- Do not commit or create real secrets.
- Do not touch .env files.
- Do not commit generated folders like node_modules, .next, build, .dart_tool, or .idea.

## Stack

- Mobile app: Flutter
- Admin dashboard: Next.js
- Backend API: NestJS
- Backend infrastructure later: Supabase PostgreSQL, Auth, Storage

## Task style

- Keep the setup simple and fresh for students.
- Remove default starter noise where safe.
- Create clean welcome screens.
- Connect frontend apps visually to the project identity.
- Keep changes minimal and easy to understand.
- After changes, run the available checks if possible.
