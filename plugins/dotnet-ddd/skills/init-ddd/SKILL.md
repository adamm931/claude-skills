---
name: init-ddd
description: >
  Scaffold a DDD modular-monolith .NET solution (Api host, SharedKernel, a first module) and write a
  project-root CLAUDE.md capturing the architecture rules and project choices. Use when the user asks
  to start, bootstrap, or initialize a new DDD / modular-monolith .NET project.
---

# Initialize a DDD modular monolith

1. Run the `dotnet-setup` skill first if `dotnet` hasn't been confirmed working in this environment
   yet — this is the mandatory first step before scaffolding anything.
2. Confirm module names, database provider, and message broker with the user if not given. The
   broker is effectively always "inmemory" at scaffold time (MassTransit's built-in in-memory
   transport) — see `architecture-rules`; a real broker is a later, deliberate migration.
3. Scaffold the solution skeleton — the `.sln`, `<SolutionName>.Api` host project (wires modules,
   MediatR, MassTransit — package refs added automatically), and `<SolutionName>.SharedKernel`
   (base types from `templates/SharedKernel.cs.template`):

   ```bash
   bash "scripts/scaffold-solution.sh" <SolutionName> <postgres|sqlserver> inmemory [OutputDir]
   ```

   Idempotent — safe to re-run; skips any project that already exists. Detects the target framework
   moniker from the installed SDK (`dotnet --version`) rather than hardcoding one.
4. Scaffold the first module via the `new-module` skill (`scripts/scaffold-module.sh`).
5. Write a `CLAUDE.md` at the repo root from `templates/CLAUDE.md.template`, recording chosen module
   names, DB/provider, broker, and a pointer to the `architecture-rules` skill — so the rules persist
   in this repo across sessions. This step is manual (module list and prose aren't scaffold-script
   material).
6. Register MediatR pipeline behaviors (validation → logging → unit-of-work) in the host once.
