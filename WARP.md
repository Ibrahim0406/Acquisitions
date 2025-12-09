# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Commands

- Install dependencies:
  - `npm install`
- Start the development server with auto-reload:
  - `npm run dev`
- Lint the codebase:
  - `npm run lint`
- Lint and auto-fix issues:
  - `npm run lint:fix`
- Check formatting:
  - `npm run format:check`
- Format the codebase:
  - `npm run format`
- Generate Drizzle migrations from the schema in `src/models`:
  - `npm run db:generate`
- Apply pending Drizzle migrations:
  - `npm run db:migrate`
- Open Drizzle Studio:
  - `npm run db:studio`

> There is currently no test runner configured (no Jest/Vitest/Mocha config or `test` script). If you add tests, also add the relevant `npm test` / per-suite commands here.

### Environment

- The app expects at least:
  - `DATABASE_URL` for Neon/Drizzle (used by `src/config/database.js` and `drizzle.config.js`).
  - `JWT_SECRET` for signing JWTs (defaults to a placeholder in `src/utils/jwt.js`, which should be overridden in real environments).
  - Optional: `PORT` (defaults to `3000`).
  - Optional: `LOG_LEVEL` and `NODE_ENV` (affect logging and cookie security).

To run locally:

- Create a `.env` file at the project root and define the variables above.
- Start the dev server via `npm run dev`, then hit:
  - `GET /` → basic hello response.
  - `GET /health` → health probe with uptime and timestamp.
  - `GET /api` → API liveness check.

## High-level architecture

This is a small Express-based HTTP API that follows a layered structure (config → routes → controllers → services → database) with Drizzle ORM and Neon as the backing Postgres layer.

### Entry point & server

- `src/index.js`
  - Loads environment variables via `dotenv/config`.
  - Imports `src/server.js` to actually start the server.
- `src/server.js`
  - Imports the configured Express app from `src/app.js`.
  - Reads `PORT` from the environment (falls back to `3000`).
  - Starts the HTTP listener and logs the URL to stdout.

Warp agents should generally:

- Treat `src/index.js` as the process entry point.
- Keep server start-up logic in `src/server.js` and leave `src/app.js` focused on HTTP configuration.

### Application configuration (`src/app.js`)

`src/app.js` is responsible for assembling the Express app:

- Global middleware:
  - `helmet` for security headers.
  - `cors` with default configuration.
  - `express.json` and `express.urlencoded` for body parsing.
  - `cookie-parser` for cookie handling.
  - `morgan` logging, wired into the project-wide Winston logger (`#config/logger.js`).
- Health and liveness endpoints:
  - `GET /` logs a message and returns a basic string.
  - `GET /health` returns JSON `{ status, timestamp, uptime }`.
  - `GET /api` returns a simple JSON liveness payload.
- Feature routing:
  - Mounts the auth feature at `app.use('/api/auth', authRoutes)` (see below).

When adding new features, follow the same pattern:

- Add a route file under `src/routes`.
- Wire it into `src/app.js` under an `/api/...` prefix.

### Module aliasing

The project uses Node `imports` aliases (see `package.json`) to avoid deep relative paths:

- `#config/*` → `./src/config/*`
- `#controllers/*` → `./src/controllers/*`
- `#middleware/*` → `./src/middleware/*`
- `#models/*` → `./src/models/*`
- `#routes/*` → `./src/routes/*`
- `#services/*` → `./src/services/*`
- `#utils/*` → `./src/utils/*`
- `#validations/*` → `./src/validations/*`

When generating new modules, prefer these aliases in imports rather than relative paths.

### Configuration layer (`src/config`)

- `src/config/database.js`
  - Creates a Neon HTTP client (`neon(DATABASE_URL)`).
  - Wraps it with Drizzle (`drizzle(sql)`).
  - Exports both `db` (for ORM queries) and `sql` (if raw SQL is needed).
- `src/config/logger.js`
  - Centralizes Winston logger configuration.
  - Writes to `logs/error.log` and `logs/combined.log`.
  - In non-production environments, also logs to the console with colors.

All cross-cutting concerns (logging, db connections, etc.) should be added under `src/config` and consumed via the `#config/*` alias.

### Data model layer (`src/models`)

- `src/models/user.model.js`
  - Defines the `users` table using Drizzle's `pgTable` API.
  - Fields include `id`, `name`, `email` (unique), `password`, `role`, and timestamp columns.

Future tables should be defined similarly under `src/models` and included in `drizzle.config.js` (`schema: './src/models/*.js'`).

### Auth feature: routes → controller → service → model

The current domain logic revolves around authentication and user management.

- Routes (`src/routes/auth.routes.js`)
  - POST `/api/auth/sign-up` → `signup` controller.
  - POST `/api/auth/sign-in` and `/api/auth/sign-out` are placeholders returning simple strings.
- Controller (`src/controllers/auth.controller.js`)
  - Uses `signupSchema` (Zod) to validate the incoming payload.
  - On validation failure, returns `400` with a formatted error string via `formatValidationError`.
  - On success:
    - Delegates user creation to `createUser` in `#services/auth.service.js`.
    - Signs a JWT via `jwttoken.sign`.
    - Sets an HTTP-only cookie via `cookies.set`.
    - Logs the event and returns a sanitized user object.
  - Handles the service-layer "user already exists" error as `409`.
- Service (`src/services/auth.service.js`)
  - Provides `hashPassword` and `createUser`.
  - Uses `bcrypt` for password hashing.
  - Interacts with the database via Drizzle `db` and the `users` table.
  - Logs and rethrows errors via the shared logger.
- Model (`src/models/user.model.js`)
  - See Data model layer above.

When adding new auth flows (sign-in, password reset, etc.), follow the same layering:

1. Define route(s) under `src/routes`.
2. Add controller functions under `src/controllers`.
3. Add or extend services under `src/services`.
4. Update models and Drizzle migrations as needed.

### Utilities (`src/utils`)

- `src/utils/jwt.js`
  - Wraps `jsonwebtoken` with `jwttoken.sign(payload)` and `jwttoken.verify(token)`.
  - Central place to update JWT expiration, algorithm, and error handling.
- `src/utils/cookies.js`
  - Provides `cookies.getOptions()` with standard security flags.
  - Helpers: `cookies.set(res, name, value, options)`, `cookies.clear(res, name, options)`, and `cookies.get(req, name)`.
  - Centralizes cookie behavior so that changes (e.g., `sameSite`, `maxAge`) are made once.
- `src/utils/format.js`
  - `formatValidationError(errors)` converts Zod error objects into user-friendly strings.

### Validation (`src/validations`)

- `src/validations/auth.validation.js`
  - `signupSchema` and `signinSchema` are Zod schemas for auth requests.
  - Controllers should always validate against these schemas before hitting services.

### Drizzle configuration

- `drizzle.config.js`
  - Points Drizzle at `./src/models/*.js` for schema definitions.
  - Uses the `DATABASE_URL` environment variable.
  - Outputs generated migrations/artifacts into `./drizzle`.

Warp agents generating database-related code should:

- Extend the schema under `src/models`.
- Regenerate migrations via `npm run db:generate`.
- Apply migrations via `npm run db:migrate` if running against a live database.

## Notes for future Warp agents

- There are currently no CLAUDE, Cursor, or Copilot instruction files in this repo.
- There is no `README.md` at the root; this `WARP.md` doubles as the primary high-level guide for now.
- When introducing tests, prefer colocating them under a `tests` or `__tests__` directory and updating ESLint config (`eslint.config.js`) and `package.json` scripts accordingly.