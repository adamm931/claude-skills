---
name: new-module
description: >
  Scaffold a new bounded-context module as four projects (Public, Domain, Application,
  Infrastructure) with enforced boundaries and a registration entry point. Use when the user asks to
  add a module, bounded context, or new area (e.g. Orders, Payments, Inventory) to the solution.
---

# Scaffold a bounded-context module

Given a module name `<Name>`, create four projects under `src/Modules/<Name>/`:

```bash
bash "scripts/scaffold-module.sh" <SolutionRootDir> <SolutionName> <Name> <postgres|sqlserver>
```

Idempotent — safe to re-run; skips any project that already exists. This creates:

1. `{{Sln}}.<Name>.Public` — the ONLY project other modules may reference. Holds the module's
   interface(s), DTOs (`Contracts/`), and integration events (`IntegrationEvents/`). No EF, no logic.
2. `{{Sln}}.<Name>.Domain` — aggregates, value objects, domain events, repository interfaces. `internal`.
   Depends on `SharedKernel` only.
3. `{{Sln}}.<Name>.Application` — MediatR slices under `Features/`. `internal`. References Domain + Public.
4. `{{Sln}}.<Name>.Infrastructure` — `DbContext` (owns schema `<name>`), repository impls, outbox wiring.
   References Domain + Application + Public.

...wires the reference graph above, adds packages (MediatR/FluentValidation to Application;
the EF Core provider + `MassTransit.EntityFrameworkCore` to Infrastructure), and generates
`<Name>Module.cs` and `<Name>DbContext.cs` from `templates/` into **Infrastructure** — not
Application. `<Name>DbContext` is `internal`, so the composition root that references it
(`Add<Name>Module`) must live in the same assembly; it cannot live in Public or Application. The
script also adds the reference from the Api host to this module's Infrastructure project.

The Api host ends up needing **two** references into the module, not one: Infrastructure (for
`Add<Name>Module`) *and* Application (for endpoint mapping, once added via `vertical-slice`).
`internal` doesn't cross an assembly boundary even through a project-reference chain — Infrastructure
having a reference to Application does NOT let Infrastructure host code that constructs Application's
`internal` Command/Query types. So `Map<Name>Endpoints` (which does exactly that — builds a Command,
calls `IMediator.Send`) has to live in **Application** itself, in the same assembly as those types,
with only its own entry-point method `public`. Register both in the host:
`builder.Services.Add<Name>Module(builder.Configuration);` and `app.Map<Name>Endpoints();`.

Rules: implementation types `internal`; reference other modules only via their `*.Public`; the module
owns its own schema; no cross-module foreign keys.
