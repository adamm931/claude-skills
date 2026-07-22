---
name: docker-down
description: >
  Stop the app's own services (api + web). Use when asked to stop, shut down, or turn off the app in
  Docker. Does not touch the backing services' data.
---

# Stop the app

Run from the repo root.

> **Aggregated with `compose-stack`?** Run bare `docker compose down` (whole stack) or
> `docker compose stop <service>` to stop one service without removing it. The `-f` forms below are
> for a project that hasn't aggregated.

```bash
docker compose -f docker/app.compose.yml down
```

This stops and removes the `api` and `web` containers. The app services are stateless — there's no
volume to preserve, and the images stay cached, so `docker-up` brings them back quickly.

## Stopping backing services too

`docker/app.compose.yml down` leaves Postgres/Kafka running. To stop those as well, list their files —
but stop at `down`, never add `-v`:

```bash
docker compose -f docker/postgres.compose.yml -f docker/app.compose.yml down
```

`-v` would delete the backing services' named volumes (database contents, Kafka topics). That's a
destructive reset handled by `postgres-ops`/`kafka-ops`'s own reset skills and must never be run
without the user explicitly confirming.
