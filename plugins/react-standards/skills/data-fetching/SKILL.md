---
name: data-fetching
description: >
  Fetch and mutate server data with TanStack (React) Query — query keys, cache invalidation,
  fetcher/hook split. Use when the user asks to fetch data, call an API, or add a query/mutation,
  or writes useEffect + useState to fetch data instead.
---

# Data fetching (TanStack Query)

Install: `@tanstack/react-query`.

## Rules

- One `QueryClient` created and provided via `QueryClientProvider` in `src/app/providers.tsx`.
- Never fetch with `useEffect` + `useState`. All server data goes through `useQuery`/`useMutation`.
- Each feature's `api/` folder holds plain fetcher functions (`fetchDashboardStats`,
  `createInvoice`); `features/*/hooks/` wraps them in `useQuery`/`useMutation` and is what
  components actually call — components never import from `api/` directly (see
  `component-design`: components stay pure, hooks own fetching).
- Query keys are arrays, feature-scoped, and include the params that affect the result, e.g.
  `["dashboard", "stats", { range }]`. Keep a `queryKeys.ts` per feature so keys aren't
  duplicated/typo'd across files.
- Mutations invalidate the related query keys in `onSuccess`
  (`queryClient.invalidateQueries(...)`) rather than manually patching cache, unless optimistic
  updates are specifically needed.
- Default `staleTime`/`retry`/error behavior configured once on the `QueryClient`, not per-call,
  unless a specific query needs to override it. Wire the client's default mutation `onError` to
  the toast pipeline — see `error-handling`.
