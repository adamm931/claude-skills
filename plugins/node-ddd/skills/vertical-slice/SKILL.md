---
name: vertical-slice
description: >
  Add a new vertical slice (use case) to a module: request object, mediator handler, Zod schema, and a
  route wired to the module's Mediator, following the project's architecture rules. Use when the user
  asks to add a feature, command, or query to an existing module.
---

# Adding a vertical slice

1. Confirm the module and whether this is a Command (mutates via aggregate) or a Query (reads → DTO).
2. Create `application/features/<use-case>/` with: `<use-case>.command.ts` (or `.query.ts`),
   `<use-case>.handler.ts`, a Zod schema for the input, and a route in the module's router that
   parses the request, sends it to the `Mediator`, and returns the response.
3. Commands: load aggregate via repository → call an aggregate method → save (the outbox write
   happens in the same DB transaction as the save). Queries: project with Prisma straight to the DTO;
   do not load the full aggregate.
4. Register the handler with the module's `Mediator` in `<name>.module.ts` — mediator middleware
   (Zod validation → logging → unit-of-work) already covers cross-cutting concerns; don't re-implement
   them in the handler.

See `templates/command.ts.template` and `templates/handler.ts.template` for the skeletons.
