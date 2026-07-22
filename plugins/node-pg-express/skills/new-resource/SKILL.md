---
name: new-resource
description: >
  Add a REST resource end-to-end: folder-per-method routes under src/api/ (each a route.js + optional
  schema.json), an HTTP-agnostic service in src/services/, and a pg repository in src/data/ — plain JS,
  functional, following the layering rules. Use when the user asks to add an endpoint, resource, or
  CRUD area (e.g. users, orders, products).
---

# Add a resource (routes + service + repository)

Given a resource name `<resource>` (kebab/lowercase plural for URL & table, e.g. `customers`;
PascalCase for symbols, e.g. `Customer`), create a method folder per operation plus one service and
one repository. Dependency direction is strictly `api -> services -> data`.

## 1. Routes (API layer) — folder per method

```
src/api/customers/
├── get/     route.js  + schema.json   -> GET  /customers        (list)
├── post/    route.js  + schema.json   -> POST /customers        (create)
└── [id]/
    ├── get/    route.js + schema.json -> GET    /customers/:id
    ├── put/    route.js + schema.json -> PUT    /customers/:id
    └── delete/ route.js + schema.json -> DELETE /customers/:id
```

Copy from `templates/` (substitute `{{resource}}`/`{{Resource}}`):
- `collection-get.route.js` + `collection-get.schema.json` — list; `parseListQuery` + `res.page`.
- `collection-post.route.js` + `collection-post.schema.json` — create; `body` schema, HATEOAS `self`
  link, and `export const middleware = [idempotency]` for safe retries.
- `item-get.route.js` + `item-get.schema.json` — single read; `params` schema, HATEOAS links.
- `item-put.route.js` + `item-put.schema.json` — update; `params` + `body`.
- `item-delete.route.js` + `item-delete.schema.json` — delete; `params`, `res.noContent()`.

Each `route.js` is THIN: read `req.valid.*`, call ONE service fn, respond with a `res.*` helper. No
SQL, no `req.query` re-parsing. (Auth + rate limit are GLOBAL in `app.js` — nothing to declare here.)

## 2. Service (business layer)
`src/services/<resource>.service.js` from `templates/service.js.template`. Plain async functions
(`list`, `getById`, `create`, `update`, `remove`); HTTP-agnostic; throws `lib/errors.js` factories;
`list(spec)` returns `{ rows, total }`.

## 3. Repository (data layer)
`src/data/<resource>.repository.js` from `templates/repository.js.template`. The ONLY file running SQL
for this resource, via the shared `pool`/`query`. Fill in real columns for `insert`/`update`; keep the
`COLUMNS` whitelist in sync with the route's `sortable`/`filterable`. `findMany(spec)` uses
`buildListQuery`. Use `withTransaction` for multi-statement writes.

## 4. Table & wiring
- Ensure a `<resource>` table exists (add a migration / SQL). Match columns to the schema.json fields
  and the `COLUMNS` whitelist.
- If any write route is idempotent, ensure the `idempotency_keys` table exists (`idempotency` skill).
- Update the resource list in the root `CLAUDE.md`.

Rules: routes never import `pool` or write SQL; services never import `express`; repositories hold no
business rules and never import a service; only whitelisted columns reach `WHERE`/`ORDER BY`. No
classes. Verify with `node --check` (the hook runs it) and hit the endpoints once the table exists.
