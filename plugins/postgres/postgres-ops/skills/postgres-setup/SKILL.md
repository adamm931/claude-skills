---
name: postgres-setup
description: >
  Scaffold a project-local, Dockerized PostgreSQL service (compose file, .env entries) and install
  the psql CLI. Use when asked to add, set up, or initialize Postgres/PostgreSQL for a project —
  this is the mandatory first step before any other postgres-ops skill.
---

# Set up PostgreSQL for this project

Run from the project's repo root. This is a one-time (per project) scaffold step — re-run only to
repair a missing piece.

## 1. Confirm Docker works

```bash
docker version --format '{{.Server.Version}}'   # daemon reachable?
docker compose version                          # compose v2+ present?
```

If the daemon isn't reachable, **stop here** and tell the user to start Docker (Docker Desktop, or
`sudo service docker start` on native Linux) — do not attempt to install Docker itself; that's a
system-level change outside this skill's scope.

## 2. Place the compose file

Copy `templates/postgres.compose.yml.template` to `docker/postgres.compose.yml` in the project
(create the `docker/` directory if it doesn't exist). Don't overwrite an existing
`docker/postgres.compose.yml` without asking — check first.

## 3. Wire up `.env`

Append `templates/env.snippet` to the project's `.env` (create `.env` from `.env.example` first if
the project uses that pattern; otherwise create `.env` directly). If `POSTGRES_*` vars already
exist, don't duplicate them — leave the existing values alone. Make sure `.env` is gitignored.

Change `POSTGRES_PASSWORD` from the placeholder if this is anything beyond a disposable local
sandbox.

## 4. Install the psql CLI

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/install-psql-cli.sh"
```

Idempotent — safe to re-run. Installs `postgresql-client` via `apt` (Debian/Ubuntu; adapt the
package manager if the environment isn't apt-based).

## 5. Bring it up and confirm

```bash
docker compose -f docker/postgres.compose.yml up -d
```

Then use the `postgres-status` skill to confirm it's healthy before reporting success — `up`
returns as soon as the container is *created*, not when Postgres is actually ready.

## Naming conventions this scaffold uses

- Compose file: `docker/postgres.compose.yml`, service name `postgres`.
- No explicit `container_name` or external network — every command in this plugin's skills is run
  **from the project root without a `-p` override**, so Compose's project name defaults consistently
  to the directory name and every service in this project (Postgres, and Kafka if the `kafka-ops`
  plugin is also installed) shares the same default network and can resolve each other by service
  name (`postgres`, `kafka`, ...).
- Volume `postgres-data` — Compose prefixes it with the project name automatically, so it won't
  collide with another project's Postgres volume.
