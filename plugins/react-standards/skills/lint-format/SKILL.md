---
name: lint-format
description: >
  Set up ESLint, Prettier, Husky/lint-staged, and strict TypeScript for a React project. Use when
  the user asks to set up linting/formatting/pre-commit hooks, or when tsconfig strict mode is off.
---

# Linting/formatting standard

- ESLint with: `@typescript-eslint`, `eslint-plugin-react`, `eslint-plugin-react-hooks`,
  `eslint-plugin-jsx-a11y` (accessibility), `eslint-plugin-simple-import-sort` (or
  `eslint-plugin-import`) for import ordering.
- `react-hooks/exhaustive-deps` set to `"error"`, not `"warn"` — missing deps are a real bug class
  with hooks-based logic.
- `jsx-a11y` recommended ruleset enabled — catches missing alt text, invalid ARIA, non-interactive
  elements with click handlers, etc., since pure components (see `component-design`) are the
  accessibility surface of the app.
- Prettier for formatting, with `eslint-config-prettier` to disable ESLint's own formatting rules
  so the two never fight.
- Husky + lint-staged: run `eslint --fix` and `prettier --write` on staged files pre-commit so
  lint issues never reach a PR.
- `tsconfig.json` strict mode on (`strict: true`) — no implicit `any`, since Zod/React Query/
  Jotai all lean on inferred types working correctly.
