---
name: dockerfile-web
description: >
  Write a multi-stage Dockerfile for a static frontend (Vite/React/Vue SPA): build with Node, serve
  the compiled assets with nginx — small image, SPA history-fallback routing, optional API proxy.
  Use when asked to containerize, Dockerize, or add a Dockerfile for a frontend / web / SPA app.
  Run docker-setup first if Docker hasn't been verified for this project.
---

# Dockerfile for a static frontend

Place the `Dockerfile` **next to the app's `package.json`** (e.g. `apps/web/Dockerfile`). Copy all
three templates into that directory (the build context root):

- `templates/Dockerfile.template` → `Dockerfile`
- `templates/nginx.conf.template` → `nginx.conf`
- `templates/dockerignore.template` → `.dockerignore`

## Why build-then-nginx

A compiled SPA is just static files — there's no Node process at runtime. So the image is two stages:

1. **`build`** — `node:*-alpine`, `npm ci` + `npm run build`, producing `dist/`.
2. **`runtime`** — `nginx:*-alpine` serving that `dist/`. No Node, no `node_modules` in the final
   image; it's a few MB of assets plus nginx.

This is why the frontend image is tiny and starts instantly, unlike a Node runtime image.

## Fill in what varies per app

`# TODO` markers in the templates cover these:

- **Build output directory** — Vite/CRA emit `dist/` or `build/`. The template copies `dist/`; change
  it if the tool or `vite.config` `build.outDir` differs.
- **Node version** for the build stage — match the project.
- **API proxy (optional)** — `nginx.conf` has a commented `location /api/` block. Uncomment it so the
  browser calls same-origin `/api/...` and nginx proxies to the backend container (`http://api:3000`)
  — this avoids CORS and hard-coded backend URLs in the bundle. Leave it commented if the frontend
  calls the API by absolute URL instead.

## Non-negotiables the templates already encode

- **SPA history fallback** — `try_files $uri $uri/ /index.html;` so a deep-link refresh
  (`/orders/42`) serves `index.html` and lets the client router handle it, instead of a 404.
- **nginx listens on 80** inside the container; the published host port is compose's decision
  (`compose-app`), not the Dockerfile's.
- **Build-time config is baked in.** Vite inlines `VITE_*` env vars at build time, so anything the
  bundle needs must be a build arg / present during `npm run build`, not a runtime env var. If the
  API base URL must differ per environment without rebuilding, prefer the nginx `/api/` proxy above.

## Verify the build before reporting success

```bash
docker build -t <app>:dev apps/web        # path = the build context (dir with the Dockerfile)
```

If `COPY --from=build /app/dist` fails, the build output dir is named differently — fix the path in
both the build script's output and the `COPY`.
