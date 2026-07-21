# Changelog

## 1.1.0
- Added `mock-data-layer`: stand up a spec-driven mock API with MSW plus a DTO→domain adapter layer
  that simplifies raw wire responses, so the React UI can be built against an API spec (e.g. a
  `*.api.md`) before the backend endpoints exist. MSW intercepts at the network boundary, so the
  real fetchers/mappers/query keys stay unchanged and un-mocked endpoints fall through to the real
  backend (`onUnhandledRequest: "bypass"`); retiring a mock is just deleting its handler. Uses a
  JSON-seed + coded-handler split: starting data lives in `db/seed/*.json` (one file per resource,
  editable without touching code) while every endpoint is a coded handler backed by an in-memory
  store, giving real POST→GET→PATCH→DELETE behaviour (a created row shows up in the next list).
  Ships boilerplate templates for the MSW browser/server setup, env-driven config, and a generic
  in-memory collection store with cursor pagination. Cross-referenced from `data-fetching` and
  `app-scaffold`.

## 1.0.0
- Initial release: `app-scaffold` (Vite + feature-based folder structure, with
  `scripts/scaffold-app.sh` actually running `npm create vite`/dependency installs rather than
  leaving it as prose), `forms` (React Hook Form + Zod), `theming` (shadcn/ui tokens, light/dark,
  switchable design-system presets), `component-design` (pure components / logic-in-hooks),
  `data-fetching` (TanStack Query), `state-management` (Jotai), `error-handling` (toast + error
  pages + centralized 401s), `lazy-routes` (React.lazy + Suspense), and `lint-format`
  (ESLint/Prettier/Husky/strict TS) skills.
