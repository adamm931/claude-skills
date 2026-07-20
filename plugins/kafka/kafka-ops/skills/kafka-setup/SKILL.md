---
name: kafka-setup
description: >
  Scaffold a project-local, Dockerized Kafka broker (single-node KRaft, compose file, .env entries)
  and install the kcat CLI. Use when asked to add, set up, or initialize Kafka for a project — this
  is the mandatory first step before any other kafka-ops skill.
---

# Set up Kafka for this project

Run from the project's repo root. This is a one-time (per project) scaffold step — re-run only to
repair a missing piece.

## 1. Confirm Docker works

```bash
docker version --format '{{.Server.Version}}'   # daemon reachable?
docker compose version                          # compose v2+ present?
```

If the daemon isn't reachable, **stop here** and tell the user to start Docker — do not attempt to
install Docker itself.

## 2. Place the compose file(s)

Copy `templates/kafka.compose.yml.template` to `docker/kafka.compose.yml` (create `docker/` if
needed). Don't overwrite an existing file without asking.

If the user also wants a UI ("with the UI", "kafka-ui", "so I can browse topics"), also copy
`templates/kafka-ui.compose.yml.template` to `docker/kafka-ui.compose.yml`. It's optional and
separate on purpose — most day-to-day operation goes through `kafka-topics`/kcat, not a browser UI.

## 3. Wire up `.env`

Append `templates/env.snippet` to the project's `.env` (create it if missing). Don't duplicate
`KAFKA_*` vars that already exist. Make sure `.env` is gitignored.

**`KAFKA_CLUSTER_ID` is baked into the volume at first start** — note this in whatever you tell the
user, because changing it later requires a `kafka-reset`, not just an `.env` edit.

## 4. Install the kcat CLI

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/install-kafka-cli.sh"
```

Idempotent. kcat is the practical day-to-day Kafka CLI (produce/consume/inspect, no JVM) — prefer it
over the bundled `kafka-*.sh` scripts, which stay available inside the container for
administration (`kafka-topics.sh`, `kafka-consumer-groups.sh` — see `kafka-topics`).

## 5. Bring it up and confirm

```bash
docker compose -f docker/kafka.compose.yml up -d
[ -f docker/kafka-ui.compose.yml ] && docker compose -f docker/kafka-ui.compose.yml up -d
```

Then use `kafka-status` to confirm healthy before reporting success — Kafka takes 20-40s to become
ready even after the container is created.

## Naming conventions this scaffold uses

- Compose file: `docker/kafka.compose.yml`, service name `kafka`. Optional
  `docker/kafka-ui.compose.yml`, service name `kafka-ui`.
- No explicit `container_name` or external network — every command in this plugin's skills runs
  **from the project root without a `-p` override**, so Compose's default project name (from the
  directory name) is consistent across separate `-f` invocations, and every service in the project
  (including `postgres` if `postgres-ops` is also installed) shares one default network and resolves
  each other by service name.
- The broker advertises two listeners: `kafka:29092` for other containers in this project,
  `localhost:9092` for host tools. Using the wrong one from the wrong place is the most common cause
  of a hang — see `kafka-topics` for the diagnostic.
