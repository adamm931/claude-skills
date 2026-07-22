---
name: request-validation
description: >
  How this API validates request input: a `schema.json` (JSON Schema) sits beside each route's
  `route.js` and declares schemas for `headers`/`params`/`query`/`body`; the router compiles it with
  Ajv and puts clean, coerced data on `req.valid`. Use when adding or changing input validation on a
  route, or when asked how validation works.
---

# Request validation (JSON Schema + Ajv, at the edge)

Validation is declarative and colocated: every route folder can hold a `schema.json` next to its
`route.js`. The router (`src/router.js`) compiles it once at startup with Ajv (`src/lib/validate.js`)
and inserts the validation middleware before the handler.

## The convention

```
src/api/customers/post/
├── route.js
└── schema.json
```

```json
// schema.json — declare any of: headers, params, query, body
{
  "body": {
    "type": "object",
    "required": ["name", "email"],
    "additionalProperties": false,
    "properties": {
      "name": { "type": "string", "minLength": 1 },
      "email": { "type": "string", "format": "email" }
    }
  }
}
```

```js
// route.js — read the clean, validated, type-coerced input
export default async (req, res) => {
  const input = req.valid.body;
  const created = await customersService.create(input);
  res.created(created, { self: ['GET', `/customers/${created.id}`] });
};
```

## Rules

- Four validatable parts: `headers`, `params`, `query`, `body` — each an optional JSON Schema.
- Ajv is configured with **type coercion** and **defaults**, so `params`/`query` strings become
  numbers/booleans per the schema (e.g. `"id": { "type": "integer" }` coerces `"42"` -> `42`), and
  missing fields get their `default`. Read the result from **`req.valid.<part>`** — never re-read
  `req.body`/`req.query` (and never assign to `req.query`; Express 5 makes it read-only).
- A failed parse -> `400` with `message.details` listing `{ part, path, message }` per error. Handlers
  never `try/catch` validation.
- Prefer `"additionalProperties": false` on `body` to reject unknown fields. Use `format` (`email`,
  `uuid`, `date-time`, `uri`, ...) — enabled via `ajv-formats`.
- Header names are lowercase (`"x-tenant-id"`), and a `headers` schema should not use
  `additionalProperties: false` (many headers you don't list are always present).
- Validation lives ONLY here (the edge). Services receive already-clean data and must not re-validate.
- For list endpoints, see `list-queries` — the `schema.json` validates raw `page`/`pageSize`/`sort`/
  `filter`, then `parseListQuery` applies the sort/filter whitelist.
