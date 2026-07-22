---
name: docker-up
description: >
  Build and start the app's own services (api + web from docker/app.compose.yml), together with any
  backing services. Use when asked to start, bring up, boot, run, or launch the app in Docker.
  Needs compose-app to have created docker/app.compose.yml first.
---

# Start the app in Docker

Run from the repo root.

## First run, or after any Dockerfile / source change → build

```bash
docker compose -f docker/app.compose.yml up -d --build
```

`--build` is what makes your latest code end up in the image. Compose does **not** rebuild on its own
just because source changed — omit `--build` and you'll silently run the previous image.

## Bring backing services up in the same command

If the app depends on Postgres/Kafka (from `postgres-ops`/`kafka-ops`), list every compose file in one
invocation so they all land on the shared default network:

```bash
docker compose -f docker/postgres.compose.yml -f docker/app.compose.yml up -d --build
```

Start backing services first (or in the same command with `depends_on`) so the DB exists when `api`
tries to connect — though the app should still retry, since `depends_on` doesn't wait for ready.

## After that → no rebuild needed

```bash
docker compose -f docker/app.compose.yml up -d
```

## Always confirm before reporting success

`up` returns once containers are *created*, not once the app is serving. Use `docker-status` to check
they're running (and healthy, if a healthcheck is defined) before saying it's up. If a service exits
immediately, go to `docker-logs` — don't just re-run `up`.

Report the published URLs once confirmed: the API on `http://localhost:${API_PORT:-3000}`, the web app
on `http://localhost:${WEB_PORT:-8080}`.
