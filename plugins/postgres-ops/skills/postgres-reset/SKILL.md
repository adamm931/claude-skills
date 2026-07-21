---
name: postgres-reset
description: >
  Destroy and recreate the project's Postgres data volume. Use when asked to reset, wipe, clear
  data, or start Postgres fresh — this DELETES data.
---

# Reset Postgres data

**This destroys data.** Confirm with the user before running anything here — name the volume that
will be deleted so they know exactly what's at stake.

Run from the project root.

```bash
docker compose -f docker/postgres.compose.yml down
docker volume rm $(docker compose -f docker/postgres.compose.yml config --format json | python3 -c "import json,sys; print(json.load(sys.stdin)['volumes']['postgres-data']['name'])")
docker compose -f docker/postgres.compose.yml up -d
```

If the project name is stable, the volume is simply `<project>_postgres-data` — `docker volume ls
--filter name=postgres-data` finds it if the command above is awkward to run as-is.

`down` must come first — Docker refuses to remove a volume still attached to a running container.

## When a reset is actually the fix

`POSTGRES_PASSWORD` (and `POSTGRES_USER`/`POSTGRES_DB`) are baked into the volume at first
initialization — editing `.env` alone has no effect on an already-initialized database. If the
symptom is an authentication failure or crash-loop after changing one of these, a reset (not another
`.env` edit) is the fix.

## Not a reset

Stopping Postgres keeps data and is handled by `postgres-down`. Never delete the volume when the
user only asked to stop the container.

## After resetting

Wait for healthy (see `postgres-up`) before reporting done.
