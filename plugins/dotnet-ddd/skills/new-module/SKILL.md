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
3. `{{Sln}}.<Name>.Application` — vertical slices under `Features/` and endpoints under `Endpoints/`
   (one folder per use case, one file per component — see `vertical-slice`). `internal`. References
   Domain + Public + SharedKernel.
4. `{{Sln}}.<Name>.Infrastructure` — `DbContext` (owns schema `<name>`), repository impls, outbox wiring.
   References Domain + Application + Public.

...wires the reference graph above, adds packages (FluentValidation + Scrutor to Application, plus a
`Microsoft.AspNetCore.App` FrameworkReference for the `IEndpoint` types; the EF Core provider +
`MassTransit.EntityFrameworkCore` to Infrastructure), and generates `<Name>Module.cs` and
`<Name>DbContext.cs` from `templates/` into **Infrastructure** — not Application. `<Name>DbContext`
is `internal`, so the composition root that references it (`Add<Name>Module`) must live in the same
assembly; it cannot live in Public or Application. The script also adds the reference from the Api
host to this module's Infrastructure project.

The Api host references only the module's **Infrastructure** project. `Add<Name>Module` (in
Infrastructure) registers everything — the DbContext, repositories, the Scrutor-scanned handlers and
validation decorators, and the module's `IEndpoint`s via `AddEndpoints(applicationAssembly)`. There
is **no** `Map<Name>Endpoints` per module: the endpoints are `internal sealed : IEndpoint` classes
that live in the Application assembly (they construct the `internal` command/query types, so they
must), and the host maps them all uniformly with a single `app.MapEndpoints();` after build. Register
in the host: `builder.Services.Add<Name>Module(builder.Configuration);`, then once for all modules
`app.MapEndpoints();`.

Rules: implementation types `internal`; reference other modules only via their `*.Public`; the module
owns its own schema; no cross-module foreign keys.
