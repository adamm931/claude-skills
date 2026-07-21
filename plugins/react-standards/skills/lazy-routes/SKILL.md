---
name: lazy-routes
description: >
  Code-split route-level page components with React.lazy + Suspense in the router. Use when the
  user asks to add a new route/page, add code-splitting, or eagerly imports page components in
  router.tsx.
---

# Lazy loading routes

- All route-level page components are code-split with `React.lazy` in `src/app/router.tsx`, not
  imported eagerly:

  ```tsx
  const DashboardPage = lazy(() => import("../pages/DashboardPage"));
  ```

- Wrap the router outlet (or each route element) in `<Suspense fallback={<PageSkeleton />}>` so
  navigation shows a loading state instead of a blank screen.
- Only lazy-load at the route/page level, not for every small component — over-splitting hurts
  more than it helps.
- If using React Router's data router APIs, prefer `route.lazy()` (which code-splits the loader +
  component together) over plain `React.lazy` where available.
- Pair each route with its `errorElement` per the `error-handling` skill — don't add lazy loading
  and error boundaries as two separate passes over `router.tsx`.
