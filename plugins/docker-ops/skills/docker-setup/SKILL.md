---
name: docker-setup
description: >
  Verify Docker works and establish this project's containerization conventions (the `docker/`
  directory and compose-file naming). Use when asked to add, set up, or initialize Docker /
  containerization for a project — this is the mandatory first step before the other docker-ops
  skills (dockerfile-node, dockerfile-web, compose-app, docker-up, ...).
---

# Set up Docker for this project

Run from the project's repo root. This is a one-time (per project) scaffold step — re-run only to
repair a missing piece. It writes no images or compose yet; it confirms the toolchain and pins down
the conventions the other skills rely on.

## 1. Confirm Docker works

```bash
docker version --format '{{.Server.Version}}'   # daemon reachable?
docker compose version                          # compose v2+ present?
docker buildx version                           # BuildKit available? (for multi-stage builds)
```

If the daemon isn't reachable, **stop here** and tell the user to start Docker (Docker Desktop, or
`sudo service docker start` on native Linux) — do not attempt to install Docker itself; that's a
system-level change outside this skill's scope.

## 2. Conventions the other skills assume

The rest of this plugin — and the `postgres-ops` / `kafka-ops` plugins — all agree on these, so that
every service in the project lands on **one shared Docker network** and resolves the others by
service name:

- **Compose files live in `docker/`**, named `docker/<concern>.compose.yml`. This plugin adds
  `docker/app.compose.yml` (services `api` and `web`); `postgres-ops` adds `docker/postgres.compose.yml`
  (service `postgres`); `kafka-ops` adds `docker/kafka.compose.yml` (service `kafka`).
- **Every command runs from the repo root with no `-p` override.** Compose then derives its project
  name from the directory, so separate `-f` invocations share one default network and one namespace
  for volumes. `api` can reach the DB at `postgres:5432` and Kafka at `kafka:29092` with no extra
  network wiring.
- **Dockerfiles live next to the code they build**, not in `docker/` — e.g. `services/api/Dockerfile`,
  `apps/web/Dockerfile`, or a single `Dockerfile` at the root for a one-service repo. The compose
  file points at them by path. Keeping them beside the source keeps each build context small.
- **No explicit `container_name`.** Let Compose prefix names with the project — avoids collisions
  between projects on the same machine.

## 3. Add a `.dockerignore`

Every build context needs one so `node_modules`, `.git`, `.env`, and prior build output don't get
copied into the image (slower builds, secrets leaking into layers). The `dockerfile-node` and
`dockerfile-web` skills each drop a `.dockerignore` next to their build context — if you're setting
up ahead of them, copy `templates/dockerignore.template` to `.dockerignore` at the context root now.

## 4. Next steps

- Backend image → `dockerfile-node`
- Frontend image → `dockerfile-web`
- Wire them together and run → `compose-app`, then `docker-up`
