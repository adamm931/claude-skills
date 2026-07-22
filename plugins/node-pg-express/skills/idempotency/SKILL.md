---
name: idempotency
description: >
  How this API makes unsafe requests safe to retry: a reusable shared middleware a route opts into via
  `export const middleware = [idempotency]`. Clients send an `Idempotency-Key` header; the first
  successful response is stored (in the `idempotency_keys` table) and replayed on retry. Use when
  adding idempotency to a POST/PUT/PATCH, or setting up the required table.
---

# Idempotency (safe retries for unsafe methods)

Network retries can send the same POST twice. Idempotency makes the second one return the first one's
result instead of creating a duplicate. It's a reusable shared middleware (`src/lib/idempotency.js`);
a route opts in by listing it in its `middleware` export — the router runs it after validation, before
the handler.

```js
// src/api/customers/post/route.js
import { idempotency } from '../../../lib/idempotency.js';

export const middleware = [idempotency];   // opt this route into idempotency

export default async (req, res) => { ... };
```

## How it works

1. Client sends `Idempotency-Key: <uuid>` with the request.
2. Middleware looks up `(key, method, path)` in `idempotency_keys`. A hit → returns the stored
   `status` + `body`, handler never runs.
3. On a miss, the handler runs; if the response is 2xx, its `status` + JSON `body` are stored under the
   key on `finish`.
4. No `Idempotency-Key` header → NOT deduped (add a guard in the handler if you want to require it).

## Setup

1. Apply the migration `templates/idempotency_keys.sql` (run it / add to your migrations).
2. Add `export const middleware = [idempotency]` to the write routes that need it.

## Limits

- Single-table, best-effort: two truly concurrent requests with the same key can both miss the initial
  lookup. For strict guarantees, insert the key FIRST with a unique constraint (as a lock) and treat a
  unique violation as a replay.
- Keys accumulate — reap old rows periodically (see the SQL comment).
