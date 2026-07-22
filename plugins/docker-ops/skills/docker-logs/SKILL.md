---
name: docker-logs
description: >
  Fetch recent logs from the app's services (api / web). Use when asked to see the app's logs, or to
  debug why a container won't start, exits, or crash-loops.
---

# App logs

Run from the repo root. Name the service to scope the output (`api` or `web`); omit it for both.

```bash
docker compose -f docker/app.compose.yml logs --tail=100 api
```

Bounded tail, not `-f` — a following stream never returns and hangs a non-interactive tool call.

Common causes of a service that exits or crash-loops, in order of likelihood:
1. **App threw on startup** — missing/empty env var, or it can't reach a backing service. Inside the
   network the DB is `postgres:5432` and Kafka is `kafka:29092`, **not** `localhost` — `localhost`
   from within a container is that container itself. Check the connection strings in
   `docker/app.compose.yml` / `.env`.
2. **Wrong `CMD` or entrypoint** in the Dockerfile — e.g. `node dist/server.js` when the app has no
   build step and the file lives at `src/server.js`. See `dockerfile-node`.
3. **Backing service not ready yet** — `depends_on` starts it but doesn't wait for ready; if the app
   doesn't retry its connection, it dies before the DB accepts connections.
4. **Port already bound** on the host — `${API_PORT}` / `${WEB_PORT}` taken by another process.

For a build that fails before any container starts, the error is in the `docker-up` build output, not
here — re-read that instead.
