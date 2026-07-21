---
name: component-design
description: >
  Split component logic (data fetching, business rules) into custom hooks and keep components
  pure/presentational, instead of the old container/presentational class-component split. Use
  when writing or reviewing any React component, especially one that fetches data or calls an API
  directly.
---

# Component design: pure components, logic in hooks

Do not use the old container/presentational-component split (a wrapper class component that
fetches data, feeding a dumb child). Its modern equivalent: custom hooks own logic, components
stay pure.

## Presentational (pure) components

Everything in `src/components/` and `features/*/components/`:
- Receive all data and event handlers via props only. No data fetching, no direct API calls, no
  reads from global store/context (except pure UI context like theme), no business logic/validation.
- Never perform an action directly — they call a callback prop instead (`onSubmit`, `onSelect`,
  `onDelete`) and let the caller decide what happens.
- May use local UI-only state (`useState` for an open/closed toggle, a hover flag) — that's fine,
  it's not business logic.
- Fully testable/storybook-able with just props, no mocking of APIs or stores required.

## Logic lives in custom hooks

One hook per unit of behavior, colocated in `features/*/hooks/`:
- The hook owns data fetching (via React Query — see `data-fetching` — or the `api/` client),
  derived state, and business rules.
- Returns a small surface: `{ data, isLoading, error, onSubmit, onDelete }` — plain data plus
  callback functions, never JSX.
- Example: `useDashboardData()` fetches and shapes dashboard data; `DashboardPage.tsx` calls it
  and passes the results as props into pure `<DashboardChart data={...} onRangeChange={...} />`.

## Pages are the composition layer

Page/route components are the composition layer, not a "container class":
- A page component calls one or more feature hooks, then arranges pure components and wires hook
  callbacks to their callback props.
- Keep pages thin — if a page has more than a few lines of business logic, that logic belongs in
  a hook, not the page.

## Rule of thumb

"Does this compute/fetch/validate something?" → hook. "Does this render something from props?" →
pure component. A component should never need to know *why* a callback does what it does, only
*that* it should call it.
