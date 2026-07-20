---
name: init-ddd
description: >
  Scaffold a DDD modular-monolith .NET solution (Api host, SharedKernel, a first module) and write a
  project-root CLAUDE.md capturing the architecture rules and project choices. Use when the user asks
  to start, bootstrap, or initialize a new DDD / modular-monolith .NET project.
---

# Initialize a DDD modular monolith

1. Confirm module names, database provider, and message broker with the user if not given.
2. Scaffold the solution skeleton from `templates/`:
   - `ECommerce.Api` host project (wires modules, MediatR, MassTransit).
   - `ECommerce.SharedKernel` (base types — see `templates/SharedKernel.cs.template`).
   - A first module via the `new-module` skill.
3. Write a `CLAUDE.md` at the repo root from `templates/CLAUDE.md.template`, recording chosen module
   names, DB/provider, broker, and a pointer to the `architecture-rules` skill — so the rules persist
   in this repo across sessions.
4. Register MediatR pipeline behaviors (validation → logging → unit-of-work) in the host once.
