---
name: state-management
description: >
  Manage client-only UI state with Jotai atoms (sidebar open, filters, active tab). Use when the
  user asks to add local/app/UI state, or reaches for Redux/Context/prop-drilling for state that
  isn't server data.
---

# Local/app state (Jotai)

Install: `jotai`.

## Rules

- Jotai atoms are for client-only state: UI state (sidebar open, selected filters, active tab),
  not server data — server data always stays in React Query (see `data-fetching`), never mirrored
  into an atom.
- Feature-local atoms live in `features/*/atoms.ts`; atoms shared across features live in
  `src/store/atoms.ts`.
- Keep atoms small and single-purpose (`sidebarOpenAtom`, `selectedFilterAtom`) rather than one
  large app-state atom; compose with derived atoms for computed values.
- Naming convention: suffix atoms with "Atom" (`themeAtom`, `sidebarOpenAtom`).
- Components read/write atoms directly with `useAtom`/`useAtomValue`/`useSetAtom`; no extra
  wrapper hook needed unless the atom logic is non-trivial.
