---
name: init-app
description: >
  Scaffold a layered Node.js/Express REST API in plain JavaScript (ESM, functional, no classes): the
  Express app + file-based router loader, the api/services/data/lib layer folders, a single pg Pool,
  env-validated config, a health route, and a project-root CLAUDE.md capturing the rules. Use when the
  user asks to start, bootstrap, or initialize a new Express + Postgres API project.
---

# Initialize a layered Express + pg API

1. Run the `node-setup` skill first if `node`/`pnpm` haven't been confirmed working in this
   environment yet — mandatory before scaffolding anything. Confirm a reachable Postgres exists (or
   scaffold one with the `postgres-ops` plugin) so `npm start` can connect.
2. Confirm the project name and the first resource (e.g. `users`) if not given.
3. Scaffold the skeleton from `templates/` into this layout:

   ```
   src/
     server.js            # entry: build app, listen, graceful shutdown  (server.js.template)
     app.js               # express: json, logger, responder, GLOBAL auth+rate-limit, router, errors  (app.js.template)
     router.js            # walks src/api/ (folder-per-method), compiles schema.json, builds router  (router.js.template)
     api/                 # FILE-BASED ROUTES — folder tree = URL tree, last folder = HTTP method
       health/get/route.js#   -> GET /health (public)  (health.route.js.template)
     services/            # business layer (added per resource)
     data/
       pool.js            # the ONE pg Pool + query + withTransaction  (pool.js.template)
     lib/
       config.js          # env parsed + validated with Ajv (incl. API_KEY, rate limit)  (config.js.template)
       logger.js          # Winston: console + rolling daily file, env-driven  (logger.js.template)
       errors.js          # HTTP error factories incl. validationError, no classes  (errors.js.template)
       async-handler.js   # forward async throws to the error handler  (async-handler.js.template)
       error-middleware.js# the one place errors become responses (envelope)  (error-middleware.js.template)
       respond.js         # response envelope: res.ok/created/page + HATEOAS links  (respond.js.template)
       validate.js        # compileSchema(schema.json) -> Ajv validation middleware  (validate.js.template)
       auth.js            # GLOBAL x-api-key auth + public allowlist  (auth.js.template)
       rate-limit.js      # GLOBAL fixed-window limiter, keyed by client  (rate-limit.js.template)
       idempotency.js     # reusable Idempotency-Key middleware (opt-in per route)  (idempotency.js.template)
       query-params.js    # parseListQuery (whitelist) + buildListQuery  (query-params.js.template)
   package.json           # "type":"module", "imports":{"#*":"./src/*"}, express/pg/ajv/winston  (package.json.template)
   .env.example           # DATABASE_URL, API_KEY, rate limit, logging  (env.example.template)
   ```

   Imports use the Node-native subpath alias (package.json `"imports": { "#*": "./src/*" }`), e.g.
   `import { config } from '#lib/config.js'` — never relative `../../..`. No loader or build step;
   editors resolve `#` from the `imports` field. (Node forbids a `#/…` key/specifier — it must be `#`
   with no slash.)

   Substitute `{{projectName}}` / `{{ProjectName}}` when copying `package.json`, `.env.example`, and
   `CLAUDE.md`. Copy `health.route.js.template` to `src/api/health/get/route.js`. Also create
   `.gitignore` (ignore `node_modules`, `.env`, `logs/`).
4. Write `CLAUDE.md` at the repo root from `templates/CLAUDE.md.template`, recording the layering and
   the resource list, so the rules persist across sessions.
5. Install deps (`pnpm install` or `npm install`), copy `.env.example` -> `.env`, then scaffold the
   first resource with the `new-resource` skill.
6. Verify: `node --check src/**/*.js` passes (the verify hook does this), and `npm start` boots and
   `GET /health` returns `{ "status": "ok" }`.

The whole stack stays plain JS and functional — no classes, no TypeScript, one validation library
(Ajv). The router is built once at boot from the folder tree (last folder = HTTP method), compiling
each route's `schema.json` for input validation. Auth + rate limit are GLOBAL (in `app.js`);
idempotency is opt-in per route via `export const middleware = [idempotency]`. Adding an endpoint is
adding a method folder + `route.js` (+ optional `schema.json`) — see `new-resource`; for each concern
see the `request-validation`, `auth`, `rate-limiting`, `idempotency`, `list-queries`, `responses`, and
`logging` skills.
