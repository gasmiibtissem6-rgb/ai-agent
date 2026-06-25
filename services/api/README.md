# IDEAL API

NestJS backend API for IDEAL.

The API is the place for business logic, authorization, validation, approval workflows, trust logic, notifications, and database communication.

Current endpoints:

```txt
GET /        App information
GET /health  Health status
```

The API uses Prisma with PostgreSQL. Set `DATABASE_URL` to choose the database target:

- Docker PostgreSQL
- Native local PostgreSQL
- Supabase PostgreSQL
- Another PostgreSQL-compatible database

Supabase Auth, Storage, and Realtime variables are optional unless the feature being tested uses them.

## Development

```bash
npm install
npm run start:dev
```

From the repository root, use:

```bash
npm run dev:api
npm run build:api
```

## Environment

Copy the API environment template:

```bash
cp services/api/.env.example services/api/.env
```

The API loads `services/api/.env` first and then falls back to the repository root `.env`.

Default Docker database URL:

```env
DATABASE_URL="postgresql://ideal:ideal_dev_password@localhost:5434/ideal_dev?schema=public"
```

Use a different `DATABASE_URL` for native PostgreSQL, Supabase, or another PostgreSQL database.

## Database Commands

From the repository root:

```bash
npm run db:up
npm run db:push
npm run db:studio
npm run db:down
```

From `services/api`:

```bash
npm run db:generate
npm run db:push
npm run db:studio
```

`db:push` applies the current Prisma schema to the configured development database. Use it after changing `DATABASE_URL` or after pulling schema changes.

## Local Admin Login

For Docker-only local development, Supabase Auth is optional. If `SUPABASE_URL`
and `SUPABASE_ANON_KEY` are not configured and `NODE_ENV` is not `production`,
the API accepts a local admin account:

```txt
Email: admin@ideal.local
Password: ChangeMe123!
```

On first successful login, the API creates or updates the matching `profiles`
row with:

```txt
isAdmin: true
adminRole: SUPER_ADMIN
kycStatus: APPROVED
```

Override the defaults in `services/api/.env`:

```env
LOCAL_ADMIN_EMAIL=admin@ideal.local
LOCAL_ADMIN_PASSWORD=ChangeMe123!
```

When Supabase Auth is configured, `/auth/login/admin` uses Supabase
`signInWithPassword` and checks that the matching profile has `isAdmin: true`.

The API runs on:

```txt
http://localhost:3001
```

Check the current endpoints:

```bash
curl http://localhost:3001/
curl http://localhost:3001/health
```

## Validation

```bash
npm run build
npm run test
```

From the repository root:

```bash
npm run build:api
npm --prefix services/api run test
```
