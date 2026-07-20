---
name: postgres-status
description: >
  Report whether the project's Postgres container is running and healthy. Use when asked if
  Postgres is up, running, healthy, or what state the database is in.
---

# Check Postgres status

Run from the project root.

```bash
docker compose -f docker/postgres.compose.yml ps
```

For the healthcheck state specifically:

```bash
docker compose -f docker/postgres.compose.yml ps -q postgres | xargs docker inspect -f '{{.State.Health.Status}}'
```

Report one of: not created (never set up — point to `postgres-setup`), created but not running
(point to `postgres-up`), `starting`, `healthy`, or `unhealthy` (point to `postgres-logs` to see
why).
