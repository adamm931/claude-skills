---
name: new-resource
description: >
  Add a REST resource end-to-end across the three layers: file-based route(s) under src/api/, an
  HTTP-agnostic service in src/services/, and a pg repository in src/data/ — plain JS, functional,
  following the layering rules. Use when the user asks to add an endpoint, resource, or CRUD area
  (e.g. users, orders, products) to an existing project.
---

# Add a resource (route + service + repository)

Given a resource name `<resource>` (kebab/lowercase plural for the URL & table, e.g. `users`;
PascalCase for symbols, e.g. `User`), create ONE file per layer. The dependency direction is
strictly `api -> services -> data` — never the reverse.

1. **Route (API layer)** — `src/api/<resource>/route.js` for the collection (`GET` list, `POST`
   create) from `templates/route.js.template`, and `src/api/<resource>/[id]/route.js` for a single
   item (`GET`/`PUT`/`DELETE`) from `templates/route.id.js.template`. The `[id]` folder becomes the
   `:id` param. The file-based router picks these up automatically — no manual registration. Keep
   handlers thin: parse input with Zod, call ONE service fn, shape the response. No SQL here.
2. **Service (business layer)** — `src/services/<resource>.service.js` from
   `templates/service.js.template`. Plain async functions (`list`, `getById`, `create`, `update`,
   `remove`); HTTP-agnostic (no `req`/`res`, no `express`). Put business rules here; throw the
   `lib/errors.js` factories (`notFound()`, etc.); delegate persistence to the repository.
3. **Repository (data layer)** — `src/data/<resource>.repository.js` from
   `templates/repository.js.template`. The ONLY file running SQL for this resource, via the shared
   `pool`/`query`. Parameterized queries only; fill in the real columns for `insert`/`update`. Use
   `withTransaction` for any multi-statement write.
4. **Table** — ensure a `<resource>` table exists (add a migration / SQL). Match the columns to the
   Zod schemas in the route and the `insert`/`update` in the repository.
5. Update the resource list in the root `CLAUDE.md`.

Rules: routes never import `pool` or write SQL; services never import `express`; repositories hold no
business rules and never import a service. No classes anywhere. Verify with `node --check` (the hook
runs it) and hit the new endpoints once the table exists.
