---
name: responses
description: >
  The single response envelope every endpoint returns — `{ data, message }` plus `links` (HATEOAS) for
  single items or `pagination` for lists — produced by the `res.ok` / `res.created` / `res.page` /
  `res.noContent` helpers. Use when shaping a response, adding resource links, or when asked what the
  API returns.
---

# Response envelope

Every response uses ONE shape so clients can rely on it. The helpers come from `src/lib/respond.js`
(registered as the `responder` middleware in `app.js`); handlers never build the envelope by hand.

## Single item — `res.ok(data, links)` / `res.created(data, links)`

```js
res.ok(customer, {
  self:   ['GET',    `/customers/${id}`],
  update: ['PUT',    `/customers/${id}`],
  delete: ['DELETE', `/customers/${id}`],
});
```
```json
{
  "data": { "id": 1, "name": "Acme" },
  "links": {
    "self":   { "method": "GET",    "href": "https://api.example.com/customers/1" },
    "update": { "method": "PUT",    "href": "https://api.example.com/customers/1" },
    "delete": { "method": "DELETE", "href": "https://api.example.com/customers/1" }
  },
  "message": { "status": 200, "type": "success", "text": "OK" }
}
```

`links` (HATEOAS) advertises the operations a client can perform on this resource. Each value is
`['METHOD', '/path']` (a bare `'/path'` means GET); the responder expands relative paths to full URLs
from the request's host. `res.created` is the same with status `201`.

## List — `res.page(rows, { page, pageSize, total })`

```json
{
  "data": [ { "id": 1 }, { "id": 2 } ],
  "pagination": {
    "page": 1, "pageSize": 20, "total": 137, "totalPages": 7,
    "hasNext": true, "hasPrev": false,
    "links": {
      "self": ".../customers?page=1&pageSize=20",
      "first": ".../customers?page=1&pageSize=20",
      "last": ".../customers?page=7&pageSize=20",
      "next": ".../customers?page=2&pageSize=20",
      "prev": null
    }
  },
  "message": { "status": 200, "type": "success", "text": "OK" }
}
```

Pair with the `list-queries` skill, which produces `{ rows, total }` and the parsed `page`/`pageSize`.

## No content — `res.noContent()`

`204`, empty body. Use for `DELETE`.

## Errors — handled centrally

Errors are NOT built in handlers. Throw a `lib/errors.js` factory (`notFound()`, `badRequest()`, …) or
let a `ZodError` propagate; the error middleware emits the matching envelope:
```json
{ "data": null, "message": { "status": 404, "type": "error", "text": "Customer not found" } }
```
Validation failures add `message.details` with per-field errors.

## Rules

- Every success goes through a `res.*` helper — never `res.json(...)` a bare payload, so the envelope
  stays uniform.
- `message.type` is `"success"` or `"error"`; `message.status` mirrors the HTTP status.
- Single-item reads should return `links` for their operations; lists return `pagination`.
