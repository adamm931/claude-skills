---
name: error-handling
description: >
  Two-tier error handling — toast for recoverable query/mutation errors, error boundary pages for
  route-level/unrecoverable errors — plus centralized 401 handling. Use when the user asks to
  handle API/mutation errors, add error pages, or a component shows its own toast/alert directly.
---

# Error handling: toasts + error pages

## Rules

- Two tiers: recoverable errors → toast notification; unrecoverable/route-level errors →
  dedicated error page.
- Toasts: use shadcn/ui's toast (sonner-based). Trigger from a query/mutation's `onError`, not
  from inside pure components — a pure component never shows its own toast, it calls
  `onError`/`onSubmit` and the hook/page decides how to surface it (see `component-design`).
- Define a shared `ApiError` type parsed once in `src/lib/apiClient.ts` so every query/mutation
  gets a consistent `{ status, message, fieldErrors? }` shape instead of raw fetch errors.
- Set a sensible default in the `QueryClient` (e.g. global `onError` for mutations) that toasts
  unexpected errors automatically, so most mutations don't need to repeat error-handling
  boilerplate; opt out per-call when a mutation needs custom handling (e.g. showing field errors
  from Zod/RHF instead of a toast — see `forms`).
- Route-level/unrecoverable errors use an error boundary + dedicated pages:
  `src/pages/ErrorPage.tsx` (generic 500) and `src/pages/NotFoundPage.tsx` (404), wired via React
  Router's `errorElement` on the root route and on individual route definitions where a feature
  needs its own fallback.
- 401s are handled centrally in the api client (redirect to login), not via a toast on every
  failed call.
