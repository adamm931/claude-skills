---
name: dockerfile-node
description: >
  Write a production-grade, multi-stage Dockerfile for a Node.js backend service (API/worker) —
  small final image, non-root user, prod-only dependencies, works for plain-ESM or TypeScript apps.
  Use when asked to containerize, Dockerize, or add a Dockerfile for a Node/Express/API service.
  Run docker-setup first if Docker hasn't been verified for this project.
---

# Dockerfile for a Node backend

Place the `Dockerfile` **next to the service's `package.json`** (e.g. `services/api/Dockerfile`, or a
root `Dockerfile` for a single-service repo). Copy `templates/Dockerfile.template` there and
`templates/dockerignore.template` to `.dockerignore` in the same directory (the build context root).

## Why multi-stage

The template has three stages so the final image ships **only** what runs in production:

1. **`deps`** — `npm ci --omit=dev` against just the lockfile, so this layer is cached and only
   rebuilds when dependencies change, not on every source edit.
2. **`build`** — full install + `npm run build` (transpile TS, bundle, etc.). Present even for
   plain-JS apps via `--if-present`, so the template is one file for both cases.
3. **`runtime`** — a fresh `node:*-alpine` with prod `node_modules` from `deps` and build output
   from `build`. No compilers, no dev deps, no source that isn't needed to run.

## Fill in the three things that vary per app

The template has `# TODO` markers for these — resolve them from the repo, don't guess silently:

- **Node version** — match the project's `.nvmrc` / `engines.node` / CI. Default in the template is
  `node:22-alpine`.
- **What the runtime stage copies** — a build step that emits `dist/` copies `dist/`; a plain-ESM
  app with no build (like a `node-pg-express` service) copies `src/` (or the app dirs) instead. The
  template ships the `dist/` form with the plain-JS alternative in a comment — keep the one that
  matches, delete the other.
- **The start command** — the `CMD`. Read it off `package.json`'s `start` script / `main` /
  the entrypoint file (`node dist/server.js`, `node src/server.js`, ...).

## Non-negotiables the template already encodes

- **Runs as non-root.** The official `node` image ships an unprivileged `node` user (uid 1000); the
  runtime stage switches to it with `USER node`. Don't run the app as root.
- **`NODE_ENV=production`** set in the runtime stage.
- **`EXPOSE`** documents the port; the actual published port is decided by compose (`compose-app`),
  not here. Keep the `EXPOSE` value in sync with the port the app listens on.
- **Alpine base** for a small image. If the app needs native modules that don't build on musl
  (`bcrypt`, some `sharp` builds), switch the base to `node:22-slim` (Debian) — note the trade-off
  to the user rather than fighting musl.

## Verify the build before reporting success

```bash
docker build -t <service>:dev services/api    # path = the build context (dir with the Dockerfile)
```

A green build is the bar for "done"; running it is `compose-app` + `docker-up`. If it fails on a
`COPY` of `dist/`, the app has no build step — switch the runtime stage to copy source instead.
