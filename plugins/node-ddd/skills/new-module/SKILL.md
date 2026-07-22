---
name: new-module
description: >
  Scaffold a new bounded-context module as a `src/modules/<name>/` directory (public, domain,
  application, infrastructure) with an enforced boundary rule and a registration entry point. Use
  when the user asks to add a module, bounded context, or new area (e.g. Orders, Payments, Inventory)
  to the project.
---

# Scaffold a bounded-context module

Given a module name `<name>` (kebab-case directory, PascalCase symbols), create under
`src/modules/<name>/`:

1. `public/` — the ONLY directory other modules may import, via `public/index.js`. Holds the module's
   public API functions, DTO/contract shapes (`public/contracts/`), and integration-event factories
   (`public/integration-events/`). No Prisma, no domain logic.
2. `domain/` — aggregate modules (pure functions over frozen state), value-object factories, domain
   events. Depends only on `shared-kernel`.
3. `application/` — mediator command/query handler functions under `application/features/`. References
   `domain` + `public` only.
4. `infrastructure/` — Prisma repository factories (`create<Aggregate>Repository(prisma)`; schema
   `<name>`, via `@@schema("<name>")`), the outbox writer, and the module's registration function.

Then generate `<name>.module.js` from `templates/module.js.template` (composition root that wires
repositories + handler functions into the `Mediator`) and a `prisma/schema/<name>.prisma` fragment
from `templates/module.prisma.template`.

Append a boundary rule to the root `.dependency-cruiser.cjs` `forbidden` array (see the placeholder
left by `init-ddd`):
```js
{
  name: 'no-cross-module-internals-<name>',
  severity: 'error',
  from: { pathNot: '^src/modules/<name>/' },
  to: { path: '^src/modules/<name>/(domain|application|infrastructure)/' },
},
```

Register the module in the app entry point: `register<Name>Module(mediator, prisma)`.

Rules: never import another module's `domain`/`application`/`infrastructure`; the module owns its own
schema; no cross-module foreign keys. Plain JS, ESM, functional — no classes.
