# Changelog

## 1.0.0
- Initial release. Authoring skills: `dockerfile-node` (multi-stage Dockerfile for a Node backend),
  `dockerfile-web` (multi-stage build → nginx for a static Vite/React frontend), `compose-app`
  (project-local `docker/app.compose.yml` wiring `api` + `web`), `compose-stack` (aggregate the
  per-concern compose files into one stack via a root `compose.yaml` `include:`, for bare
  `docker compose up` and per-service bring-up), and `docker-setup` (verify Docker, establish
  `docker/` + `.dockerignore` conventions). Lifecycle skills: `docker-up`, `docker-down`,
  `docker-status`, `docker-logs`. Follows the same project-local, run-from-repo-root compose
  conventions as `postgres-ops`/`kafka-ops`, so app services share their default network and resolve
  `postgres`/`kafka` by service name.
