---
name: rate-limiting
description: >
  How this API throttles requests: a GLOBAL fixed-window limiter wired in app.js, keyed by client
  (x-api-key or IP) and configured via env (`RATE_LIMIT_WINDOW`, `RATE_LIMIT_MAX`). Use when tuning the
  limit, or when asked how throttling works.
---

# Rate limiting (global, fixed window)

Rate limiting is a GLOBAL middleware wired once in `app.js` (not per route). `rateLimit`
(`src/lib/rate-limit.js`) caps each client's total request rate across the whole API, keyed by the
`x-api-key` header (or `req.ip` for public traffic).

## Wiring & config

```js
// app.js
app.use(rateLimit(config.rateLimit)); // { window, max } from env
```

- `RATE_LIMIT_WINDOW` — `'1m'`, `'30s'`, `'1h'`, or ms (default `1m`).
- `RATE_LIMIT_MAX` — max requests per window per client (default `100`).
- Responses carry `X-RateLimit-Limit/Remaining/Reset`; over-limit returns `429` with `Retry-After` in
  the standard error envelope.

## Scope & limits

- In-memory / single-process — correct for one instance. Running multiple instances? The bucket Map
  isn't shared, so limits are per-process. Swap the store for Redis (`INCR` + `EXPIRE` per client key)
  — the middleware shape stays the same.
- Need a tighter limit on one hot route? Add `rateLimit({ window, max })` to that route's `middleware`
  export in addition to the global one (it keys the same way).
