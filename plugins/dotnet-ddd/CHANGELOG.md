# Changelog

## 1.2.0
- Add `scripts/scaffold-solution.sh` and `scripts/scaffold-module.sh`: `init-ddd` and `new-module`
  previously only shipped C# content templates with no actual `dotnet new`/`dotnet sln add`/
  `dotnet add reference`/`dotnet add package` commands to run them through — every scaffold had to
  be done by hand from prose. Both scripts are idempotent (safe to re-run) and detect the target
  framework moniker from the installed SDK rather than hardcoding one.
- Fix `Module.cs.template`: its own comment placed the composition root in the **Application**
  project, but `{{Name}}DbContext` (from `DbContext.cs.template`) is `internal` — a type only
  visible within its own assembly. `Add<Name>Module` now generates into **Infrastructure**, the
  project that's actually in the same assembly as the DbContext. `new-module`'s reference graph
  updated to match: the Api host now references only a module's Infrastructure project, never
  Domain/Application/Public directly.
- Fix three bugs found by actually building a scaffolded solution end-to-end (previously untested):
  idempotency checks looked only for `*.sln`, but SDK 9+'s `dotnet new sln` produces `*.slnx`;
  `SharedKernel.cs` uses `MediatR.INotification` but `SharedKernel` never got a `MediatR` package
  reference; `DbContext.cs.template`'s outbox methods (`AddInboxStateEntity` etc.) are in namespace
  `MassTransit`, not `MassTransit.EntityFrameworkCoreIntegration` as the `using` assumed.
- Fix reference graph: the Api host needs to reference a module's **Application** project, not just
  Infrastructure. `internal` doesn't cross assembly boundaries even through a project-reference
  chain, so endpoint-mapping code that constructs Application's `internal` Command/Query types can't
  live in Infrastructure (despite Infrastructure referencing Application) — it has to live in
  Application itself. `scaffold-module.sh` now adds both references from the Api host, adds a
  `Microsoft.AspNetCore.App` FrameworkReference to Application (needed for endpoint-mapping types),
  and adds `FluentValidation.DependencyInjectionExtensions` to Infrastructure (for
  `AddValidatorsFromAssembly`, needed since handlers/validators are scanned from the Application
  assembly, not Infrastructure's own).
- Fix two more bugs found building a real multi-slice module against this scaffold:
  `Module.cs.template` scanned `typeof({{Name}}Module).Assembly` for MediatR handlers — that's
  Infrastructure's own (empty) assembly, not Application's, where handlers actually live. And
  `AddValidatorsFromAssembly` was missing `includeInternalTypes: true` — validators are `internal`
  per the vertical-slice convention, and without that flag FluentValidation's scanner silently skips
  them (no error at any point; a request that should 400 on validation instead falls through to
  whatever check the aggregate happens to have, often returning 422 for the same rule — a confusing
  way to discover the flag is missing). Fixed by adding a generated `ApplicationAssemblyMarker`
  public type (new `ApplicationAssemblyMarker.cs.template`) that both `AddMediatR` and
  `AddValidatorsFromAssembly` scan by reference, and adding the flag.

## 1.1.0
- Add `dotnet-setup` skill: checks for the .NET SDK and installs it (`scripts/install-dotnet-sdk.sh`)
  if missing, mirroring the mandatory-first-step pattern in `postgres-ops`/`kafka-ops`. `init-ddd`
  now points to it as step 1.

## 1.0.0
- Initial release: architecture-rules constitution; init-ddd, new-module, vertical-slice,
  integration-event, and aggregate-design skills; ddd-reviewer agent; PostToolUse verify hook.
