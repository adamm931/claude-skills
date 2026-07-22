# Changelog

## 1.0.0
- Initial release. Layered (`api -> services -> data` + shared `lib`), plain-JS/functional REST API.
- Skills: architecture-rules (constitution), node-setup, init-app (scaffold), new-resource, logging.
- File-based, **folder-per-method** routing (`customers/get/route.js` -> GET /customers; `[id]` ->
  `:id`); `route.js` default-exports the handler, optional `export const middleware = [...]`.
- **JSON Schema (Ajv)** validation via a sibling `schema.json` (headers/params/query/body); Ajv also
  validates env in `config.js`. One validation library, no Zod.
- Cross-cutting: request-validation (schema.json), auth (**global** x-api-key + public allowlist),
  rate-limiting (**global**, per-client), idempotency (reusable middleware, opt-in via the route's
  `middleware` export, backed by the `idempotency_keys` table), list-queries (pagination + whitelisted
  sort/filter), responses (one envelope `{ data, links|pagination, message }` + HATEOAS), logging
  (Winston: console + rolling daily file, env-driven).
- Internal imports via the Node-native `#/` alias (package.json `"imports"`), no build step.
- layered-reviewer agent; PostToolUse verify hook (syntax + layer-boundary guards).
