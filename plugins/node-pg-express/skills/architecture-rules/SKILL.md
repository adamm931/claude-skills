---
name: architecture-rules
description: >
  The mandatory architecture rules for this Node.js REST API (plain JavaScript, ESM, functional — no
  classes, no TypeScript): a strict one-way api -> services -> data layering with a shared lib,
  Next.js-style file-based routing on Express, and raw PostgreSQL via a single pg Pool. Consult before
  creating or modifying any route, service, repository, or shared utility.
---

# Architecture Constitution

A fast, thin, layered REST API. Optimize for a short path from request to SQL and back: no ORM, no
per-request object graphs, no classes. Every request flows in ONE direction through the layers.

## Style
- Plain JavaScript, ES modules (`import`/`export`, `"type": "module"` in `package.json`). NO
  TypeScript.
- NO classes anywhere — factory functions, closures, and modules of plain/async functions only.
- Contracts are enforced at runtime (Zod schemas at the API edge), not by compile-time types. Use
  JSDoc for editor hints, never for enforcement.
- Data passed between layers is plain objects. Return values, not shared mutable state.

## Layers (strict, one-directional: `api -> services -> data`)
`src/lib` is shared by every layer. A layer may import the one below it and `lib`, never the one above.

- **API layer — `src/api/`** — file-based routes (see Routing). A `route.js` handler is THIN: read
  input from `req`, validate it, call ONE service function, shape the response. It NEVER imports the
  `pg` Pool and contains NO SQL. It does not implement business rules.
- **Business layer — `src/services/`** — all business logic and orchestration, as plain async
  functions grouped by resource (`users.service.js`). A service is HTTP-agnostic: it takes plain
  arguments, returns plain data, and throws typed errors (`notFound()`, `badRequest()`). It NEVER
  imports `express` or touches `req`/`res`. It calls repositories in the data layer.
- **Data layer — `src/data/`** — repositories (`users.repository.js`) are the ONLY code that talks to
  PostgreSQL, via the shared `pool`. They run parameterized queries and return plain rows/objects.
  NO business rules here, and no knowledge of HTTP.
- **Shared — `src/lib/`** — cross-cutting utilities usable by any layer: `config`, `logger`, error
  factories, `asyncHandler`, `validate`. NO business logic, NO SQL, no `req`/`res` handling.

## Routing (file-based, Next.js style)
- The folder tree under `src/api/` IS the URL tree. `src/api/users/route.js` -> `/users`;
  `src/api/users/[id]/route.js` -> `/users/:id` (a `[param]` folder becomes an Express `:param`).
- A `route.js` exports one function per HTTP method it serves: `export const GET = (req, res) => ...`,
  `export const POST = ...` (also `PUT`, `PATCH`, `DELETE`).
- `src/router.js` walks `src/api/` ONCE at startup, converts each folder path to an Express path, and
  registers every exported method handler (wrapped in `asyncHandler`). There is NO manual route table
  — adding a folder + `route.js` adds a route.

## Data access
- ONE `pg.Pool` per process, created in `src/data/pool.js` from env config, imported wherever needed.
  Never create a Pool or Client per request.
- Parameterized queries ONLY: `pool.query('select ... where id = $1', [id])`. NEVER string-concat
  user input into SQL (injection).
- A repository returns plain data; map rows to the shape callers expect inside the repository.
- Multi-statement writes go through the `withTransaction(async (client) => { ... })` helper
  (`BEGIN`/`COMMIT`/`ROLLBACK` on one checked-out client), never as separate `pool.query` calls.

## Errors
- Errors are plain objects from factories in `lib/errors.js`, each carrying an HTTP `status`
  (`notFound`, `badRequest`, `conflict`, ...). Services throw them; they do not format HTTP responses.
- Every route handler is wrapped in `asyncHandler` so a thrown/rejected error reaches the single
  error-handling middleware, which maps `status` -> response. Handlers never `try/catch` just to
  build an error body.

## Performance
- Keep every layer thin and functional — no per-request instantiation, no reflection, no ORM
  hydration. The router and the Pool are built once at boot and reused.
- Keep global middleware minimal (`express.json`, logging, the error handler). Put resource-specific
  work in services, not in middleware.

When asked to add code, follow these rules exactly. If a request violates a rule, say so and propose
the compliant alternative.
