---
name: docker-status
description: >
  Report whether the app's services (api + web) are running. Use when asked if the app is up,
  running, or what state its containers are in.
---

# Check app status

Run from the repo root.

```bash
docker compose -f docker/app.compose.yml ps
```

Report per service (`api`, `web`) one of: not created (never started — point to `docker-up`, or
`compose-app` if `docker/app.compose.yml` itself is missing), `running`, `restarting` (crash-looping —
point to `docker-logs`), or `exited` (point to `docker-logs`).

If a service defines a healthcheck, read its health state:

```bash
docker compose -f docker/app.compose.yml ps -q api | xargs docker inspect -f '{{.State.Status}} {{if .State.Health}}({{.State.Health.Status}}){{end}}'
```

An `exited` or crash-looping container almost always means a build ran but the process died on
startup (bad `CMD`, missing env var, can't reach `postgres`/`kafka`) — `docker-logs` shows why.
