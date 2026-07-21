---
name: vertical-slice
description: >
  Add a new vertical slice (use case) to a module: request, MediatR handler, FluentValidation
  validator, endpoint, and response DTO, following the solution's architecture rules. Use when the
  user asks to add a feature, command, or query to an existing module.
---

# Adding a vertical slice

1. Confirm the module and whether this is a Command (mutates via aggregate) or a Query (reads → DTO).
2. Create `Features/<UseCase>/` with: `<UseCase>Command|Query.cs`, `<UseCase>Handler.cs`,
   `<UseCase>Validator.cs` (commands), and an endpoint. Types are `internal`.
3. Commands: load aggregate via repository → call an aggregate method → SaveChanges (outbox commits).
   Queries: project with EF straight to the DTO; do not load the full aggregate.
4. Register nothing by hand — MediatR assembly scan and pipeline behaviors already cover it.

See `templates/Command.cs.template` and `templates/Handler.cs.template` for the skeletons.
