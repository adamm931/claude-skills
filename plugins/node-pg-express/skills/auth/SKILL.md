---
name: auth
description: >
  How this API authenticates: v1 is a single API key from env, applied GLOBALLY (secure by default) —
  every request needs a valid `x-api-key` header except paths on the public allowlist. Use when
  configuring the API key, adding a public route, or planning the later move to JWT.
---

# Authentication (v1: global API key from env)

Auth is a GLOBAL middleware wired once in `app.js` — it is NOT declared per route. `apiKeyAuth`
(`src/lib/auth.js`) runs before the router and requires a valid `x-api-key` on every request, except
paths on the public allowlist. The key comes from `API_KEY` (validated in `config.js`); the compare is
constant-time. Missing/wrong key → `401` in the standard error envelope.

## Wiring (already in app.js)

```js
const PUBLIC_PATHS = ['/health'];
app.use(rateLimit(config.rateLimit));
app.use(apiKeyAuth({ publicPaths: PUBLIC_PATHS }));
app.use(await buildRouter());
```

## Make a route public

Add its path prefix to `PUBLIC_PATHS` in `app.js` (matches the exact path or any subpath). Everything
not listed requires the key — secure by default. Individual routes declare NOTHING about auth.

## Setup

- Put `API_KEY` in `.env` (see `.env.example`) — `config.js` fails fast at startup if missing.
- Clients send `x-api-key: <the key>`. Never log the key or echo it in responses.

## Later: JWT

Keep auth global; swap the middleware:
- Replace `apiKeyAuth` with a `jwtAuth` that verifies a `Bearer` token and sets `req.user`, still wired
  once in `app.js` with the same public allowlist.
- If you need per-route roles, check `req.user` inside the handler or add a small role-guard to a
  route's `middleware` export. The global gate stays.
