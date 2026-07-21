---
name: app-scaffold
description: >
  Scaffold a new React + TypeScript (Vite) app with a feature-based folder structure and wire up
  App.tsx, router.tsx, providers.tsx. Use when the user asks to start, bootstrap, or initialize a
  new React app, or asks how a React project should be structured.
---

# Scaffold a React app

1. Run the scaffold script — it creates the Vite app, installs the dependencies every other skill
   in this plugin assumes are present (react-router-dom, react-hook-form, zod, @hookform/resolvers,
   @tanstack/react-query, jotai, sonner, plus lint/format dev deps), and lays out the folder tree:

   ```bash
   bash "scripts/scaffold-app.sh" <AppName> [OutputDir]
   ```

   Idempotent — safe to re-run; skips the Vite scaffold if `package.json` already exists.

2. Confirm with the user (if not already clear) which feature domains the app starts with (e.g.
   `auth`, `dashboard`, `billing`) — each becomes a folder under `src/features/`.

3. Lay out the tree. This is the shape every other skill in this plugin assumes:

   ```
   src/
   ├── app/                        # app-wide setup
   │   ├── App.tsx
   │   ├── router.tsx
   │   ├── providers.tsx           # context providers, query client, theme, etc.
   │   └── store.ts                # root store (if using redux; jotai atoms don't need this)
   ├── features/                   # one folder per business domain
   │   └── <feature>/
   │       ├── components/
   │       ├── hooks/
   │       ├── api/
   │       ├── types.ts
   │       ├── schemas.ts          # zod schemas — see the forms skill
   │       ├── atoms.ts            # jotai atoms — see the state-management skill
   │       ├── queryKeys.ts        # see the data-fetching skill
   │       └── index.ts            # public exports of the feature — the ONLY way in
   ├── components/                 # truly shared/reusable UI (buttons, modals, layout)
   ├── hooks/                      # shared hooks used across features
   ├── lib/                        # generic helpers, api client instance, config
   ├── mocks/                      # MSW mock API while the backend is in progress — see mock-data-layer
   ├── pages/ (or routes/)         # thin route components that compose features
   ├── types/                      # shared global types
   ├── styles/
   ├── main.tsx
   └── index.css
   ```

4. Fill in `src/app/`:
   - `providers.tsx` — composes `QueryClientProvider` (see `data-fetching` skill), the theme
     provider (see `theming` skill), and `<Toaster />` (see `error-handling` skill) into one tree.
   - `router.tsx` — set up React Router; route elements come from `src/pages/`. Wire lazy-loading
     per the `lazy-routes` skill and `errorElement` per the `error-handling` skill from the start,
     not bolted on later.
   - `App.tsx` — renders the router inside providers.

5. Point the user at `component-design` (pure components vs. hooks), `lint-format` (ESLint/
   Prettier/Husky setup), and the relevant per-feature skills (`forms`, `data-fetching`,
   `state-management`) before they start writing feature code.

## Rules

- Each feature under `src/features/` is self-contained: its components, hooks, API calls, and
  types live together — never scattered across top-level `components/`, `hooks/`, `api/`.
- Each feature exposes an `index.ts` as its public API. Other code imports from `features/auth`,
  never from `features/auth/components/LoginForm` directly — internals stay refactorable.
- Features must not import from each other directly. If one feature needs something from another,
  promote the shared piece up into `src/components/`, `src/hooks/`, or `src/lib/`.
- Keep `src/pages/` (or `src/routes/`) thin — they only wire feature components onto a route, no
  business logic.
- TypeScript everywhere; `tsconfig.json` has `strict: true` (see `lint-format`).
