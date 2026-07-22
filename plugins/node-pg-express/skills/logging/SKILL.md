---
name: logging
description: >
  How this API logs: Winston with two transports — a colorized console and a rolling daily file
  (structured JSON) — with the level and rotation all driven by env via `config.log`. Use when adding
  log statements, changing the log level/rotation, or when asked how logging works.
---

# Logging (Winston: console + rolling file)

The logger (`src/lib/logger.js`) is a single Winston instance with two transports:
- **Console** — colorized, human-readable (`HH:mm:ss.SSS level message {meta}`). Great for `debug`
  while developing.
- **Rolling file** — `winston-daily-rotate-file`, one structured-JSON file per day under `LOG_DIR`
  (e.g. `logs/app-2026-07-22.log`), rolled by size and pruned by retention.

Every knob is env-driven through `config.log` — you tune logging without touching code.

## Usage

```js
import { logger } from '../lib/logger.js';

logger.debug('cache miss', { key });      // shown only when LOG_LEVEL=debug (or lower)
logger.info('order placed', { orderId });
logger.warn('slow query', { ms });
logger.error('charge failed', { err: err.message });
```

- Pass structured metadata as a second object arg — it's merged into the JSON file line and appended
  to the console line. Don't string-concatenate values into the message.
- Request logging is automatic: `requestLogger` middleware logs each request at the `http` level
  (method, path, status, duration) — so request noise can be silenced separately from app `info`.
- Errors flow through the error middleware, which logs unexpected 5xx with the stack; you rarely log
  errors by hand in handlers.

## Config (via `.env` -> `config.log`)

| Env | Default | Meaning |
|---|---|---|
| `LOG_LEVEL` | `info` | `error`<`warn`<`info`<`http`<`verbose`<`debug`<`silly` — logs at this level and above |
| `LOG_DIR` | `logs` | directory for rolling files (git-ignore it) |
| `LOG_MAX_SIZE` | `20m` | roll to a new file once the current exceeds this |
| `LOG_MAX_FILES` | `14d` | retention — keep this long (`14d`) or this many files (`30`), then delete |
| `LOG_ZIP` | `false` | gzip rotated files |

Set `LOG_LEVEL=debug` in development, `info` (or `http`) in production. Add `logs/` to `.gitignore`.

## Rules

- Log through `logger` only — never `console.log` in app code (the one exception is `config.js`, which
  runs before the logger exists).
- Levels are configuration, not code: don't hardcode a level or a file path — read from `config.log`.
- Never log secrets (the API key, passwords, tokens) or full request bodies with PII.
