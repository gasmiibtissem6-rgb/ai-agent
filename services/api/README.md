# IDEAL API

NestJS backend API for IDEAL.

The API is the place for business logic, authorization, validation, approval workflows, trust logic, notifications, and future database communication.

Current endpoints:

```txt
GET /        App information
GET /health  Health status
```

Supabase is not connected yet.

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
