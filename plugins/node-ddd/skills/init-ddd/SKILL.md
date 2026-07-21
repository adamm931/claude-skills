---
name: init-ddd
description: >
  Scaffold a DDD modular-monolith Node.js/TypeScript project (app entry point, shared kernel, module
  boundary enforcement, a first module) and write a project-root CLAUDE.md capturing the architecture
  rules and project choices. Use when the user asks to start, bootstrap, or initialize a new DDD /
  modular-monolith Node.js project.
---

# Initialize a DDD modular monolith

1. Run the `node-setup` skill first if `node`/`pnpm` haven't been confirmed working in this
   environment yet — this is the mandatory first step before scaffolding anything.
2. Confirm module names, HTTP framework (Fastify/Express/Nest), and integration-event transport
   (in-memory `EventEmitter` vs Kafka) with the user if not given.
3. Scaffold the project skeleton from `templates/`:
   - App entry point that wires the HTTP framework, the `Mediator`, and module registration.
   - `src/shared-kernel/index.ts` — base types (see `templates/shared-kernel.ts.template`): `Entity`,
     `AggregateRoot`, `IDomainEvent`, `DomainError`, `Mediator`.
   - `.dependency-cruiser.cjs` from `templates/dependency-cruiser.cjs.template` — the base config that
     `new-module` appends a per-module boundary rule to.
   - A first module via the `new-module` skill.
4. Write a `CLAUDE.md` at the repo root from `templates/CLAUDE.md.template`, recording chosen module
   names, DB provider, integration-event transport, and a pointer to the `architecture-rules` skill —
   so the rules persist in this repo across sessions.
5. Wire mediator middleware (Zod validation → logging → unit-of-work) in the app entry point once.
