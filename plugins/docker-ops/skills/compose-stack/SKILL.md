---
name: compose-stack
description: >
  Combine the project's per-concern compose files (docker/app.compose.yml, docker/postgres.compose.yml,
  docker/kafka.compose.yml, ...) into one stack via a root `compose.yaml` `include:`, so a bare
  `docker compose up` from the repo root runs everything and `docker compose up <service>` brings up
  just the service you name. Use when asked how to run multiple compose files together, to bring up a
  specific service, or to register a newly-scaffolded service into the stack.
---

# Aggregate the compose files into one stack

Each plugin here keeps its own file — `docker/app.compose.yml` (`api` + `web`),
`docker/postgres.compose.yml` (`postgres`), `docker/kafka.compose.yml` (`kafka`). Listing them all
with `-f` on every command is what this skill removes. Compose's `include:` element pulls them into a
single model from one root file.

## The root aggregator

Copy `templates/compose.yaml.template` to **`compose.yaml` at the repo root** (not under `docker/`).
Compose auto-discovers a root `compose.yaml`, so once it exists every command is a bare
`docker compose ...` run from the repo root — no `-f`, no `-p`. List one `include:` entry per concern
file that exists in the project; comment out the ones the project doesn't use.

```yaml
include:
  - docker/app.compose.yml
  - docker/postgres.compose.yml   # only if postgres-ops is set up
  - docker/kafka.compose.yml      # only if kafka-ops is set up
```

Paths are relative to `compose.yaml` (the repo root), so they read as `docker/...`. Everything still
lands on the one default network — the project name stays directory-derived — so `api` reaches
`postgres:5432` / `kafka:29092` exactly as before.

## Registering a newly-scaffolded service

This is the "manage the compose files" job: whenever `compose-app`, `postgres-setup`, `kafka-setup`,
etc. add a new `docker/<concern>.compose.yml`, **add one `include:` line** for it here. That's the
only edit — the concern file itself stays self-contained and owned by its own plugin.

## Bring up the whole stack, or one service

From the repo root:

```bash
docker compose up -d --build        # everything in the include list
docker compose up -d api            # just api — plus anything it depends_on
docker compose up -d postgres api   # a chosen subset by service name
```

Naming a service is how you "bring up the service you want": Compose starts that service and its
`depends_on` chain, and leaves the rest down. Same for the other verbs — `docker compose ps`,
`docker compose logs <service>`, `docker compose down` all operate on the aggregated stack with no
`-f`.

## Once this exists, the lifecycle skills simplify

`docker-up` / `docker-down` / `docker-status` / `docker-logs` can drop their `-f` lists and run bare
`docker compose ...` from the root. They still work the long way (explicit `-f`) for a project that
hasn't aggregated — the aggregator is the convenience layer, not a requirement.

## Alternative without a new file

If you'd rather not add `compose.yaml`, set `COMPOSE_FILE` in the project's `.env` instead — Compose
reads it as the file list for bare commands:

```dotenv
COMPOSE_FILE=docker/postgres.compose.yml:docker/kafka.compose.yml:docker/app.compose.yml
```

`include:` is the better default (declarative, and supports per-service subset bring-up cleanly);
reach for `COMPOSE_FILE` only when a root `compose.yaml` would clash with something the project
already has.
