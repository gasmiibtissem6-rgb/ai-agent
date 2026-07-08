# Auth Module — Handoff Notes

_Last updated: 2026-07-08_

This documents the **user-facing authentication layer** added to the NestJS API
(`services/api`) and the Supabase/DB wiring it depends on. It is written for the
next backend maintainer. Everything here is additive — the existing **admin**
auth flow was intentionally left untouched (see "Do not break" below).

---

## 1. What exists now

Authentication has two separate surfaces:

| Surface | Route(s) | Token | Who |
|---|---|---|---|
| **Admin login** (pre-existing) | `POST /api/v1/auth/login/admin` | Supabase access token *or* NestJS-signed JWT (local dev fallback) | Next.js admin |
| **User auth** (new) | `POST /api/v1/auth/{register,login,refresh,logout,forgot-password}` | Supabase session tokens | Flutter mobile/web |
| **Shared** | `GET /api/v1/auth/me` | either token | both |

The unified `JwtAuthGuard` validates **both** Supabase JWTs (via
`supabase.auth.getUser()` or offline HS256 if `SUPABASE_JWT_SECRET` is set) and
NestJS JWTs (via `JWT_SECRET`), and resolves a Prisma `Profile` → `AuthenticatedUser`.
`RolesGuard`, `@Roles`, `@Public`, `@CurrentUser` are unchanged.

### New user-auth endpoints

All responses use the global envelope `{ success, message, data, requestId }`
(`TransformInterceptor`); errors use `HttpExceptionFilter`.

| Endpoint | Guard | Request body | `data` returned |
|---|---|---|---|
| `POST /auth/register` | `@Public()` | `{ email, password, fullName }` | `{ user:{id,email,fullName}, access_token, refresh_token, expires_at }` |
| `POST /auth/login` | `@Public()` | `{ email, password }` | `{ access_token, refresh_token, expires_at, profile }` |
| `POST /auth/refresh` | `@Public()` | `{ refresh_token }` | `{ access_token, refresh_token, expires_at }` |
| `POST /auth/logout` | `JwtAuthGuard` | — (Bearer header) | `{ success: true }` |
| `POST /auth/forgot-password` | `@Public()` | `{ email }` | `{ success: true }` (generic; never reveals if the email exists) |

Behavior notes:
- **Register** uses the **service-role** Supabase client `auth.admin.createUser({ email_confirm: true })` → **no email OTP step** (product decision), then signs in to return a live session, then **upserts a `Profile`** in code (never depends on the DB trigger).
- **Login** returns the canonical `Profile` (same row `GET /auth/me` resolves; self-heals a missing row via upsert).
- **Logout** is best-effort server-side `auth.admin.signOut(jwt)` — never throws.
- Errors are mapped: duplicate email → **409**, weak password → **400**, bad credentials → **401**, invalid/expired refresh → **401**.

---

## 2. Files

**Added**
```
src/auth/user-auth.controller.ts          # the 5 routes above
src/auth/user-auth.service.ts             # Supabase-delegated logic (2 clients)
src/auth/user-auth.controller.spec.ts     # delegation + token-extraction tests
src/auth/user-auth.service.spec.ts        # register/login/refresh/logout/forgot tests
src/auth/dto/register.dto.ts
src/auth/dto/login.dto.ts
src/auth/dto/refresh-token.dto.ts
src/auth/dto/forgot-password.dto.ts
```

**Modified**
```
src/auth/auth.module.ts        # register UserAuthController + UserAuthService
src/prisma/prisma.service.ts   # fixed the Supabase signup trigger (see §4)
```

**Untouched (do not break):** `auth.controller.ts`, `auth.service.ts` (`login()`/`loginLocalAdmin()`),
`jwt-auth.guard.ts`, `roles.guard.ts`, `/auth/me`, and everything in `src/admin/`.

---

## 3. Supabase clients & env

`UserAuthService` builds **two** Supabase clients from `ConfigService`:
- **anon** (`SUPABASE_ANON_KEY`): `signInWithPassword`, `refreshSession`, `resetPasswordForEmail`.
- **admin / service-role** (`SUPABASE_SERVICE_ROLE_KEY`): `auth.admin.createUser`, `auth.admin.signOut`.

Required env (already in `.env.example`, enforced by `validateEnv()` in `main.ts` as
an all-or-nothing group):
```
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=      # server-side only — MUST NOT ship to Flutter
JWT_SECRET=
DATABASE_URL=                   # MUST point at the Supabase Postgres (see §5)
# optional:
SUPABASE_JWT_SECRET=            # enables offline token verification
SUPABASE_PASSWORD_RESET_REDIRECT=   # optional redirectTo for reset emails
ALLOWED_ORIGINS=                # CORS allowlist (see §5)
```

> ⚠️ The **service-role key is all-powerful**. It lives only in the API's env and
> is never returned to clients. Flutter only ever sees its own access/refresh tokens.

---

## 4. The Supabase signup trigger (critical gotcha)

`PrismaService.onModuleInit` creates a `public.handle_new_user()` function + an
`on_auth_user_created` trigger on `auth.users` that mirrors every new auth user
into `public.profiles`, plus a backfill and a realtime publication.

The function is `SECURITY DEFINER`, so when Supabase Auth fires it, it runs under
the **`supabase_auth_admin`** role whose `search_path` excludes `public`. Two things
are therefore mandatory (and are now in the code):
1. `SET search_path = public, extensions` on the function.
2. Schema-qualify the enum cast: `'NOT_STARTED'::public.kyc_status`.

Without them, **every** Supabase user creation fails with
`500 "Database error saving new user"` (register returns an opaque `{}` → 400, and
Google OAuth silently fails to create a profile). If you ever edit this function,
keep both guards.

Note: register also upserts the profile in application code, so it does not rely on
this trigger — but **Google OAuth and any externally-created users do**, so the
trigger must stay working.

---

## 5. Operational gotchas

- **`DATABASE_URL` must be the Supabase Postgres**, not a local Postgres. If it points
  elsewhere, the `auth` schema is missing (trigger errors) and Prisma writes land in a
  different DB than Supabase Auth — a split brain. Direct connection form:
  `postgresql://postgres:<pw>@db.<ref>.supabase.co:5432/postgres?schema=public`
  (or the pooler on `:6543` with `pgbouncer=true`).
- **CORS for Flutter web:** `main.ts getAllowedOrigins()` only allows `localhost:3000/3001`
  by default. Flutter web dev serves on a random port, so set
  `ALLOWED_ORIGINS=http://localhost:3000,http://localhost:<flutter-port>` and run
  `flutter run -d chrome --web-port=<flutter-port>`. (A dev-only "allow any localhost"
  relaxation was discussed but not implemented.)

---

## 6. Tests

`npm test` in `services/api` — 10 suites / 64 tests green, including the 16 new
user-auth tests. The suite is fully offline (Supabase clients are mocked; Prisma is
mocked). New tests live in `user-auth.service.spec.ts` and `user-auth.controller.spec.ts`.

---

## 7. Not done / still on Supabase (future work)

Deliberately left on the Supabase SDK for now (client-side), pending migration:
- **Google OAuth** login.
- **Password-reset completion** (the reset email deep-links into Supabase recovery;
  only the *sending* goes through `POST /auth/forgot-password`).
- **Delete account** (`rpc('delete_user')`).

On the Flutter side, `chat`, `deals`, and `kyc` still read `supabase.auth.currentUser`
directly, so those features are broken for email/password (NestJS) users until their
own migration sessions. Auth itself is fully migrated.
