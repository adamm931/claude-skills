---
name: postgres-down
description: >
  Stop the project's Postgres container without deleting its data. Use when asked to stop, shut
  down, or turn off Postgres locally.
---

# Stop Postgres

Run from the project root.

```bash
docker compose -f docker/postgres.compose.yml down
```

This stops and removes the container but **keeps the named volume** (`postgres-data`) — data
survives. Do not add `-v` here; that's a destructive reset, handled by the `postgres-reset` skill,
and must never be run without the user explicitly confirming.
