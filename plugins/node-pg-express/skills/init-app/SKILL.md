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
     app.js               # express app: json, logger, router, error handler  (app.js.template)
     router.js            # walks src/api/, builds the Express router  (router.js.template)
     api/                 # FILE-BASED ROUTES — folder tree = URL tree
       health/route.js    #   -> GET /health  (health.route.js.template)
     services/            # business layer (added per resource)
     data/
       pool.js            # the ONE pg Pool + query + withTransaction  (pool.js.template)
     lib/
       config.js          # env parsed + validated with Zod  (config.js.template)
       logger.js          # structured logger + request logger  (logger.js.template)
       errors.js          # HTTP error factories, no classes  (errors.js.template)
       async-handler.js   # forward async throws to the error handler  (async-handler.js.template)
       error-middleware.js# the one place errors become responses  (error-middleware.js.template)
       validate.js        # parse req parts against a Zod schema  (validate.js.template)
   package.json           # "type":"module", express/pg/zod  (package.json.template)
   .env.example           # DATABASE_URL etc.  (env.example.template)
   ```

   Substitute `{{projectName}}` / `{{ProjectName}}` when copying `package.json`, `.env.example`, and
   `CLAUDE.md`. Also create `.gitignore` (ignore `node_modules`, `.env`).
4. Write `CLAUDE.md` at the repo root from `templates/CLAUDE.md.template`, recording the layering and
   the resource list, so the rules persist across sessions.
5. Install deps (`pnpm install` or `npm install`), copy `.env.example` -> `.env`, then scaffold the
   first resource with the `new-resource` skill.
6. Verify: `node --check src/**/*.js` passes (the verify hook does this), and `npm start` boots and
   `GET /health` returns `{ "status": "ok" }`.

The whole stack stays plain JS and functional — no classes, no TypeScript. The router is built once
at boot; adding a route later is just adding a folder + `route.js` (see `new-resource`).
