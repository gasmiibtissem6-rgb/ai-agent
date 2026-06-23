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

The project is designed to use **Supabase PostgreSQL** as the primary database.

Supabase may also be used for:

* Authentication
* PostgreSQL database
* File storage
* Realtime updates later if needed

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
Supabase PostgreSQL / Auth / Storage

Next.js Admin Dashboard
        |
        v
NestJS Backend API
```

Frontend apps should not own sensitive business logic.

The backend API is responsible for:

* User management
* Identity verification flow
* Deal creation
* Contract ownership
* Party permissions
* Approval control
* Version locking
* Trust counters
* Admin actions
* Audit logs
* Notifications
* Database operations

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

* The deal can be edited during drafting and negotiation.
* Parties can review and negotiate the terms.
* No official locked version exists yet.

After a deal is approved:

* The approved version becomes official.
* The approved version is locked.
* Future changes must create a new version.
* A new version is not valid until all required parties approve it again.

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

Use `.env.example` as the safe template.

Example:

```env
DATABASE_URL=
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
JWT_SECRET=
API_PORT=3001
```

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

Current simple endpoints:

```txt
GET /        App information
GET /health  Health status
```

## Run Everything

Open separate terminals from the repository root.

### Terminal 1: Backend API

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
{"projectName":"IDEAL","status":"ready","serviceName":"api"}
```

```json
{"status":"ok"}
```

### Terminal 2: Admin Dashboard

```bash
npm run dev:admin
```

Open:

```txt
http://localhost:3000
```

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

* Keep mobile code inside `apps/mobile`
* Keep admin dashboard code inside `apps/admin`
* Keep backend logic inside `services/api`
* Keep documentation inside `docs`
* Do not commit `.env`
* Do not commit generated build folders
* Do not commit `.next`, `build`, `.dart_tool`, or `node_modules`
* Do not put approval, contract, trust, or identity logic directly in frontend apps
* Use the backend API as the main communication layer

## Project Status

Current setup stage:

* Flutter mobile app created with a clean IDEAL welcome screen
* Next.js admin dashboard created with a clean IDEAL welcome page
* NestJS backend API created with simple app info and health endpoints
* Documentation setup in progress
* Infrastructure setup pending
