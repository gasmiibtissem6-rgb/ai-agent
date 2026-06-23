# API

The backend API is located in services/api.

Current endpoints:

```txt
GET /        Returns project name, status, and service name.
GET /health  Returns a simple health status.
```

Run the API from the repository root:

```bash
npm run dev:api
```

Test the current endpoints:

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

Build and test:

```bash
npm run build:api
npm --prefix services/api run test
```

The API will later handle:

- Authentication coordination
- User management
- Role-based access
- Business logic
- Database operations
- External service integrations
