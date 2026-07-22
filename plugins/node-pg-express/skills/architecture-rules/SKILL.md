---
name: architecture-rules
description: >
  The mandatory architecture rules for this Node.js REST API (plain JavaScript, ESM, functional — no
  classes, no TypeScript): a strict one-way api -> services -> data layering with a shared lib,
  folder-per-method file-based routing on Express, JSON Schema (Ajv) input validation via a sibling
  schema.json, and raw PostgreSQL via a single pg Pool. Consult before creating or modifying any route,
  service, repository, schema, or shared utility.
---

# Architecture Constitution

A fast, thin, layered REST API. Optimize for a short path from request to SQL and back: no ORM, no
per-request object graphs, no classes. Every request flows in ONE direction through the layers.

## Style
- Plain JavaScript, ES modules (`import`/`export`, `"type": "module"`). NO TypeScript.
- NO classes anywhere — factory functions, closures, and modules of plain/async functions only.
- ONE validation library: JSON Schema via **Ajv** — for both request input (`schema.json`) and env
  (`config.js`). No Zod. Use JSDoc for editor hints, never for enforcement.
- Internal imports use the `#/` alias (Node-native package.json `"imports": { "#/*": "./src/*" }`) —
  `import { config } from '#/lib/config.js'`, NEVER relative `../../..`. External/npm packages import
  by their bare name as usual.
- Data passed between layers is plain objects. Return values, not shared mutable state.

## Layers (strict, one-directional: `api -> services -> data`)
`src/lib` is shared by every layer. A layer may import the one below it and `lib`, never the one above.

- **API layer — `src/api/`** — file-based routes (see Routing). A `route.js` handler is THIN: read
  validated input from `req.valid`, call ONE service function, shape the response with a `res.*`
  helper. It NEVER imports the `pg` Pool and contains NO SQL. It does not implement business rules.
- **Business layer — `src/services/`** — all business logic and orchestration, as plain async
  functions grouped by resource (`customers.service.js`). A service is HTTP-agnostic: plain args in,
  plain data out, throws typed errors (`notFound()`, `badRequest()`). It NEVER imports `express` or
  touches `req`/`res`. It calls repositories.
- **Data layer — `src/data/`** — repositories (`customers.repository.js`) are the ONLY code that talks
  to PostgreSQL, via the shared `pool`. Parameterized queries; return plain rows/objects. NO business
  rules, no knowledge of HTTP.
- **Shared — `src/lib/`** — cross-cutting utilities usable by any layer: `config`, `logger`, error
  factories, `asyncHandler`, `validate` (Ajv), `respond`, `auth`, `rate-limit`, `idempotency`,
  `query-params`. NO business logic, NO SQL, no `req`/`res` handling.
  - Logging is Winston (`logger`) with a console + rolling daily-file transport, level/rotation from
    `config.log` (env). Log through `logger` only — never `console.log` in app code; never log secrets.

## Routing (file-based, folder-per-method)
- The folder tree under `src/api/` IS the URL tree, and the LAST folder is the HTTP method.
  `src/api/customers/get/route.js` -> `GET /customers`; `src/api/customers/[id]/delete/route.js` ->
  `DELETE /customers/:id`. A `[param]` folder becomes `:param`.
- A method folder holds:
  - **`route.js`** — `export default (req, res) => ...` (the handler). Optionally
    `export const middleware = [ ... ]` — reusable per-route middleware (e.g. `idempotency`).
  - **`schema.json`** — optional JSON Schema for input: `{ headers, params, query, body }`.
- `src/router.js` walks `src/api/` ONCE at startup: for each `route.js` it derives the method + path,
  compiles the sibling `schema.json` into a validation middleware, and registers
  `validate -> ...middleware -> handler`. Adding a method folder + `route.js` adds an endpoint — there
  is NO manual route table.

## Input validation (JSON Schema, at the edge)
- Each route's `schema.json` declares JSON Schema for the parts it validates (`headers`/`params`/
  `query`/`body`). Ajv coerces types (query/params are strings) and applies `default`s; clean data
  lands on `req.valid.<part>` — read from there, never re-parse `req.body`/`req.query`.
- Validation happens ONLY at the edge (the router, from `schema.json`). Services receive clean data
  and must not re-validate shapes. A failure -> 400 with `message.details`.
- Prefer `"additionalProperties": false` on `body` to reject unknown fields; use `format` (email,
  uuid, date-time, ...) via ajv-formats.

## Cross-cutting concerns
- **Auth + rate limit are GLOBAL** — applied once in `app.js`, not per route. `apiKeyAuth` requires a
  valid `x-api-key` for every request except `PUBLIC_PATHS` (e.g. `/health`); `rateLimit` caps each
  client's overall request rate. (skills: `auth`, `rate-limiting`)
- **Idempotency is opt-in per route** — a reusable shared middleware. A write route enables it with
  `export const middleware = [idempotency]`; clients send `Idempotency-Key` and retries replay the
  first 2xx response (needs the `idempotency_keys` table). (skill: `idempotency`)
- **List queries** — the route validates raw `?page=&pageSize=&sort=&filter[field]=` via `schema.json`,
  then `parseListQuery(req.valid.query, { sortable, filterable })` applies the field WHITELIST and the
  repo builds a parameterized query with `buildListQuery` — user input never becomes a SQL identifier.
  (skill: `list-queries`)

## Responses (one envelope)
Every success goes through a `res.*` helper (from `lib/respond.js`); never `res.json` a bare payload.
- Single item: `res.ok(data, links)` / `res.created(...)` -> `{ data, links, message }`, where `links`
  is HATEOAS operations (`self`/`update`/`delete` as `['METHOD','/path']`) expanded to full URLs.
- List: `res.page(rows, { page, pageSize, total })` -> `{ data, pagination, message }`.
- `res.noContent()` -> 204.
- Errors are emitted by the ONE error middleware in the same envelope `{ data: null, message }` — throw
  a `lib/errors.js` factory, never format an error body in a handler. (skill: `responses`)

## Data access
- ONE `pg.Pool` per process (`src/data/pool.js`), imported wherever needed. Parameterized queries
  ONLY (`$1, $2`) — never string-concat user input into SQL. Multi-statement writes go through
  `withTransaction`.

## Performance
- Keep every layer thin and functional — no per-request instantiation, no ORM. The router, the Ajv
  validators, and the Pool are built once at boot and reused. Keep global middleware minimal.

When asked to add code, follow these rules exactly. If a request violates a rule, say so and propose
the compliant alternative.
