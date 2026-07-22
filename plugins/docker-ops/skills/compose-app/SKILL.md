---
name: compose-app
description: >
  Scaffold a project-local compose file (`docker/app.compose.yml`) that builds and runs the app's own
  services — a Node backend (`api`) and a static frontend (`web`) — on the same default network as any
  postgres-ops/kafka-ops services, so they resolve each other by name. Use when asked to create a
  docker-compose for the app / for backend + frontend, or to wire the services together. Needs a
  Dockerfile per service first (dockerfile-node, dockerfile-web).
---

# Compose file for the app's own services

Copy `templates/app.compose.yml.template` to `docker/app.compose.yml` (create `docker/` if needed;
don't overwrite an existing file without asking) and append `templates/env.snippet` to the project's
`.env`. Run from the repo root.

This composes **your** services (the ones you wrote Dockerfiles for). Third-party backing services —
Postgres, Kafka — stay in their own `docker/*.compose.yml` files from `postgres-ops`/`kafka-ops`; this
file doesn't redefine them, it just relies on sharing their network (see below).

## The two services

- **`api`** — built from the Node backend Dockerfile (`dockerfile-node`). Publishes `${API_PORT}`,
  reads config from `.env`, and reaches backing services by name: `postgres:5432`, `kafka:29092`.
- **`web`** — built from the frontend Dockerfile (`dockerfile-web`). Publishes `${WEB_PORT}` → nginx's
  port 80, and `depends_on: [api]`.

## Fill in the `# TODO`s

- **`build.context` / `dockerfile`** per service — point at where each Dockerfile actually lives.
  Context is relative to the compose file, so from `docker/` the repo root is `..`; a monorepo service
  is `../services/api` with `dockerfile: Dockerfile`. Keep the context as narrow as the build needs.
- **`api` environment** — the env vars the backend reads (`DATABASE_URL`, etc.). Reference `postgres`
  / `kafka` by service name in those URLs, not `localhost` — inside the network `localhost` is the
  container itself.
- **Ports** — defaults `API_PORT=3000`, `WEB_PORT=8080` in the env snippet; change if taken.

## Why no `networks:` block, no `container_name`

Same rule as `postgres-ops`/`kafka-ops`: run every compose command **from the repo root with no `-p`**.
Compose then derives one project name from the directory, so `docker/app.compose.yml`,
`docker/postgres.compose.yml`, and `docker/kafka.compose.yml` all share the **default network** and
one namespace. `api` reaches `postgres`/`kafka` with zero extra wiring. Adding an explicit network or
`container_name` here would break that sharing — leave them out.

## `depends_on` starts, it doesn't wait for ready

`depends_on: [postgres]` makes Compose *start* Postgres first, but not wait until it accepts
connections. The app must retry its DB connection on boot (or use `condition: service_healthy` against
a service that declares a healthcheck). Don't assume the DB is queryable the instant `api` starts.

## Bring it up

Point `docker-up` at both files so the app and its backing services come up together:

```bash
docker compose -f docker/postgres.compose.yml -f docker/app.compose.yml up -d --build
```

Then confirm with `docker-status` before reporting success. See `docker-up` for the first-run vs
rebuild distinction.

Retyping the `-f` list on every command gets old fast — once more than one compose file is in play,
`compose-stack` aggregates them behind a root `compose.yaml` so a bare `docker compose up -d` (or
`docker compose up -d <service>` for one service) does the same thing.
