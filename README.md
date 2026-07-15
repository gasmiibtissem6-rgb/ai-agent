# IDEAL

## Overview

IDEAL is a cross-platform application for creating, negotiating, approving, and managing trusted digital deals and contracts between individuals, companies, and multiple involved parties.

The platform focuses on trust, identity, approval control, contract ownership, and clear deal versioning.

IDEAL allows users to create agreements, invite involved parties, negotiate deal terms, approve the final version, and manage the contract lifecycle safely.

## Tech Stack

### Mobile App

The mobile application is built with **Flutter**.

Location:

```txt
apps/mobile
```

Flutter is used for the cross-platform mobile experience.

### Admin Dashboard

The admin dashboard is built with **Next.js**.

Location:

```txt
apps/admin
```

The admin dashboard is used for internal management, moderation, user review, deal review, system monitoring, and operational control.

### Backend API

The backend API is built with **NestJS**.

Location:

```txt
services/api
```

NestJS is the planned main backend layer for business logic, authorization, validation, approval workflows, trust logic, notifications, and database communication. The current API is intentionally simple and exposes basic app information and health endpoints.

### Database and Infrastructure

The project uses **PostgreSQL** through the NestJS API and Prisma.

Developers can point the API at any PostgreSQL-compatible environment by setting `DATABASE_URL`:

- Docker PostgreSQL for local development
- Native local PostgreSQL
- Supabase PostgreSQL
- Another PostgreSQL instance

Supabase may also be used for:

- Authentication
- PostgreSQL database
- File storage
- Realtime updates later if needed

Core business logic must stay inside the NestJS backend API.

## Architecture

IDEAL follows this architecture:

```txt
Flutter Mobile App
        |
        v
NestJS Backend API
        |
        v
PostgreSQL / Supabase PostgreSQL

Next.js Admin Dashboard
        |
        v
NestJS Backend API
```

Frontend apps should not own sensitive business logic.

The backend API is responsible for:

- User management
- Identity verification flow
- Deal creation
- Contract ownership
- Party permissions
- Approval control
- Version locking
- Trust counters
- Admin actions
- Audit logs
- Notifications
- Database operations

## Repository Structure

```txt
apps/
  mobile/        Flutter mobile application
  admin/         Next.js admin dashboard

services/
  api/           NestJS backend API

docs/
  architecture.md
  api.md
  database.md

infra/
  Infrastructure, Docker, deployment, and environment setup

packages/
  Shared packages, types, or utilities added later

scripts/
  Project helper scripts

.github/
  GitHub workflows and CI/CD setup
```

## Core Business Rules

Before a deal is approved:

- The deal can be edited during drafting and negotiation.
- Parties can review and negotiate the terms.
- No official locked version exists yet.

After a deal is approved:

- The approved version becomes official.
- The approved version is locked.
- Future changes must create a new version.
- A new version is not valid until all required parties approve it again.

This keeps the system flexible during negotiation and secure after approval.

## Main Functional Areas

### Users

Users can create accounts, manage profiles, and participate in deals.

### Identity

The platform may support identity verification to improve trust between involved parties.

### Deals

Users can create deals, define terms, invite parties, and manage agreement progress.

### Contracts

Approved deal versions become official contract records.

### Approvals

All required parties must approve the same deal version before it becomes valid.

### Trust

Trust counters and trust indicators help users evaluate parties before entering agreements.

### Admin

Admins can manage users, review reports, monitor activity, and handle platform-level operations.

### Notifications

The system can notify users about invitations, approval requests, deal updates, and contract changes.

## Environment Variables

Environment variables should be stored in a local `.env` file.

Do not commit real secrets.

Use `.env.example` as the safe root template, or `services/api/.env.example` when you only need to configure the API.

The API loads `services/api/.env` first and then falls back to the root `.env`.

Example:

```env
DATABASE_URL="postgresql://ideal:<DB_PASSWORD>@localhost:5434/ideal_dev?schema=public"
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
JWT_SECRET=replace-with-a-local-development-secret
API_PORT=3001
```

`DATABASE_URL` is the only database selector. Change it to switch between Docker PostgreSQL, native PostgreSQL, Supabase PostgreSQL, or another PostgreSQL database.

See [docs/database.md](docs/database.md) for the full database setup guide.

## Development Setup

Install dependencies for each app before running it:

### Mobile App

```bash
cd apps/mobile
flutter pub get
flutter run
```

### Admin Dashboard

```bash
cd apps/admin
npm install
npm run dev
```

### Backend API

```bash
cd services/api
npm install
npm run start:dev
```

For Docker PostgreSQL, run these commands from the repository root before starting the API:

```bash
npm run db:up
npm run db:push
```

Current simple endpoints:

```txt
GET /        App information
GET /health  Health status
```

## Run Everything

Open separate terminals from the repository root.

### Terminal 1: PostgreSQL In Docker

```bash
npm run db:up
npm run db:push
```

This starts PostgreSQL on `localhost:5434` and applies the Prisma schema to the local database.

### Terminal 2: Backend API

```bash
npm run dev:api
```

The API runs on:

```txt
http://localhost:3001
```

Check the API:

```bash
curl http://localhost:3001/
curl http://localhost:3001/health
```

Expected responses:

```json
{ "projectName": "IDEAL", "status": "ready", "serviceName": "api" }
```

```json
{ "status": "ok" }
```

### Terminal 3: Admin Dashboard

```bash
npm run dev:admin
```

Open:

```txt
http://localhost:3000
```

For Docker-only local development, the API provides a local admin fallback when
Supabase Auth is not configured:

```txt
Email: admin@ideal.local
Password: ChangeMe123!
```

The fallback creates or updates a local `profiles` row with `SUPER_ADMIN`
permissions on first successful login. Override the defaults with
`LOCAL_ADMIN_EMAIL` and `LOCAL_ADMIN_PASSWORD` in `services/api/.env`.

When Supabase Auth is configured with `SUPABASE_URL` and
`SUPABASE_ANON_KEY`, the API uses Supabase login instead and requires a matching
admin profile in the database.

### Mobile App

```bash
cd apps/mobile
flutter run
```

## Validation And Tests

Run these from the repository root unless noted.

```bash
npm run build:admin
npm run build:api
npm --prefix services/api run test
cd apps/mobile && flutter analyze
cd apps/mobile && flutter test
```

## Development Rules

- Keep mobile code inside `apps/mobile`
- Keep admin dashboard code inside `apps/admin`
- Keep backend logic inside `services/api`
- Keep documentation inside `docs`
- Do not commit `.env`
- Do not commit generated build folders
- Do not commit `.next`, `build`, `.dart_tool`, or `node_modules`
- Do not put approval, contract, trust, or identity logic directly in frontend apps
- Use the backend API as the main communication layer

## Project Status

Current setup stage:

- Flutter mobile app created with a clean IDEAL welcome screen
- Next.js admin dashboard created with a clean IDEAL welcome page
- NestJS backend API created with Prisma/PostgreSQL configuration
- Documentation setup in progress
- Local Docker PostgreSQL setup available
