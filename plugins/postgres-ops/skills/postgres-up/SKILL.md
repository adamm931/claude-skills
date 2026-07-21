---
name: postgres-up
description: >
  Start the project's Postgres container. Use when asked to start, bring up, boot, or launch
  Postgres locally.
---

# Start Postgres

Run from the project root (where `docker/postgres.compose.yml` lives — see `postgres-setup` if it
doesn't exist yet).

```bash
docker compose -f docker/postgres.compose.yml up -d
```

## Always wait before reporting success

`up -d` returns as soon as the container is *created*, not when Postgres is ready to accept
connections. Poll the healthcheck rather than reporting success immediately:

```bash
timeout 60 bash -c '
until [ "$(docker compose -f docker/postgres.compose.yml ps -q postgres | xargs docker inspect -f "{{.State.Health.Status}}")" = "healthy" ]; do
  sleep 2
done'
```

If it times out, don't retry blindly — check logs first (`postgres-logs`). The two usual causes are
a `POSTGRES_PASSWORD` that doesn't match an already-initialized volume, or the port already being
in use by another Postgres instance on the host.

Report the port it's listening on (`${POSTGRES_PORT:-5432}` from `.env`) once healthy.
