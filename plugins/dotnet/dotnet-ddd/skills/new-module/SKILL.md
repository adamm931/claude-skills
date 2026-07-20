---
name: new-module
description: >
  Scaffold a new bounded-context module as four projects (Public, Domain, Application,
  Infrastructure) with enforced boundaries and a registration entry point. Use when the user asks to
  add a module, bounded context, or new area (e.g. Orders, Payments, Inventory) to the solution.
---

# Scaffold a bounded-context module

Given a module name `<Name>`, create four projects under `Modules/<Name>/`:

1. `{{Sln}}.<Name>.Public` — the ONLY project other modules may reference. Holds the module's
   interface(s), DTOs (`Contracts/`), and integration events (`IntegrationEvents/`). No EF, no logic.
2. `{{Sln}}.<Name>.Domain` — aggregates, value objects, domain events, repository interfaces. `internal`.
   Depends on `SharedKernel` only.
3. `{{Sln}}.<Name>.Application` — MediatR slices under `Features/`. `internal`. References Domain + Public.
4. `{{Sln}}.<Name>.Infrastructure` — `DbContext` (owns schema `<name>`), repository impls, outbox wiring.

Then generate `<Name>Module.cs` from `templates/Module.cs.template` (public composition root) and the
`DbContext` from `templates/DbContext.cs.template`. Register the module in the Api host:
`builder.Services.Add<Name>Module(builder.Configuration);`

Rules: implementation types `internal`; reference other modules only via their `*.Public`; the module
owns its own schema; no cross-module foreign keys.
