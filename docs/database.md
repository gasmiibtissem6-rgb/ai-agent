# Database

IDEAL uses PostgreSQL through the NestJS API and Prisma.

`DATABASE_URL` is the single switch that selects which database a developer uses. The code should work with Docker PostgreSQL, native local PostgreSQL, Supabase PostgreSQL, or another PostgreSQL-compatible environment as long as `DATABASE_URL` is correct.

## Environment Files

Use one of these local files:

- Root `.env` from `.env.example`
- API-only `services/api/.env` from `services/api/.env.example`

The API loads `services/api/.env` first. If that file is missing a value, it falls back to the root `.env`.

Never commit real `.env` files or real secrets.

## Docker PostgreSQL

This is the default local setup for developers who want a disposable local database.

1. Copy the API environment template:

```bash
cp services/api/.env.example services/api/.env
```

2. Start PostgreSQL:

```bash
npm run db:up
```

3. Apply the Prisma schema:

```bash
npm run db:push
```

4. Start the API:

```bash
npm run dev:api
```

Docker connection string:

```env
DATABASE_URL="postgresql://ideal:ideal_dev_password@localhost:5434/ideal_dev?schema=public"
```

The Docker service is defined in `docker-compose.yml` and stores data in the `ideal_postgres_data` volume.

Stop the container:

```bash
npm run db:down
```

## Native Local PostgreSQL

Use this when PostgreSQL is installed directly on your machine.

1. Create a local database, for example `ideal_dev`.
2. Set `DATABASE_URL` in `services/api/.env` or root `.env`.
3. Apply the Prisma schema.

Example:

```env
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/ideal_dev?schema=public"
```

```bash
npm run db:push
npm run dev:api
```

Adjust the username, password, host, port, and database name for your machine.

## Supabase PostgreSQL

Use this when testing against a Supabase project.

1. Open the Supabase project database settings.
2. Copy the PostgreSQL connection string.
3. Put it in `DATABASE_URL`.
4. Add Supabase service variables only when the feature needs Supabase Auth, Storage, or Realtime.

Example:

```env
DATABASE_URL="postgresql://postgres:<password>@db.<project-ref>.supabase.co:5432/postgres?schema=public"
SUPABASE_URL="https://<project-ref>.supabase.co"
SUPABASE_ANON_KEY="<anon-key>"
SUPABASE_SERVICE_ROLE_KEY="<service-role-key>"
```

Then run:

```bash
npm run db:push
npm run dev:api
```

Do not commit Supabase credentials.

## Local Admin Account

Docker and native PostgreSQL development can use the API's local admin fallback.
This is only active when Supabase Auth is not configured and `NODE_ENV` is not
`production`.

Default credentials:

```txt
Email: admin@ideal.local
Password: ChangeMe123!
```

The first successful login creates or updates a `profiles` row for that email
with `SUPER_ADMIN` permissions.

Change the local credentials in `services/api/.env` if needed:

```env
LOCAL_ADMIN_EMAIL=admin@ideal.local
LOCAL_ADMIN_PASSWORD=ChangeMe123!
```

When using Supabase Auth instead, create the user in Supabase Auth and make sure
`public.profiles.auth_user_id` matches the Supabase user ID with `is_admin =
true`.

## Prisma Commands

Run these from the repository root:

```bash
npm run db:generate
npm run db:push
npm run db:studio
```

Run these from `services/api`:

```bash
npm run db:generate
npm run db:push
npm run db:studio
```

- `db:generate` regenerates the Prisma client.
- `db:push` applies the current Prisma schema to the configured development database.
- `db:studio` opens Prisma Studio for the configured database.

## Data Model Areas

The Prisma schema currently covers these business areas:

- Profiles and roles
- Companies and company members
- Deals and deal parties
- Deal versions and approvals
- Files
- KYC submissions
- Trust counters
- Audit logs
- Notifications
- Reports
- Subscriptions
