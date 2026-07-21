---
name: postgres-logs
description: >
  Fetch recent logs from the project's Postgres container. Use when asked to see Postgres logs, or
  to debug why Postgres won't start or is unhealthy.
---

# Postgres logs

Run from the project root.

```bash
docker compose -f docker/postgres.compose.yml logs --tail=100 postgres
```

Bounded tail, not `-f` — a following log stream never returns and hangs a non-interactive tool call.
If the user explicitly wants to watch logs live, run `-f` in a way they can interrupt (e.g. tell
them the command to run themselves), don't run it as a blocking tool call.

Common causes of an unhealthy/crash-looping container, in order of likelihood:
1. `POSTGRES_PASSWORD` was changed in `.env` after the volume was already initialized — Postgres
   bakes the password in at first start. Fix via `postgres-reset` (destructive — confirm first), not
   by editing `.env` again.
2. Port `${POSTGRES_PORT:-5432}` already bound by another process/container on the host.
3. The `postgres-data` volume is corrupted from an unclean shutdown — also a `postgres-reset` case if
   the data isn't needed.
