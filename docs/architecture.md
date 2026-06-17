# Architecture

This repository uses a clean monorepo structure.

## Main Parts

- apps/mobile: Flutter mobile application
- apps/admin: Next.js admin dashboard
- services/api: NestJS backend API
- docs: project documentation
- infra: infrastructure and deployment files
- packages: shared packages added later
- scripts: helper scripts

## Rule

Frontend apps handle user interface only.

Core business logic should live in the backend API.

Supabase is planned as infrastructure for database, authentication, storage, and related services.

The current frontend apps show clean project welcome screens. The current backend API is intentionally small and exposes app information and health status while business modules are planned.
