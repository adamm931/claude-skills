---
name: vertical-slice
description: >
  Add a new vertical slice (use case) to a module: a command/query factory, a mediator handler
  function, a Zod schema, and a route wired to the module's Mediator, following the project's
  architecture rules (plain JS, functional). Use when the user asks to add a feature, command, or
  query to an existing module.
---

# Adding a vertical slice

1. Confirm the module and whether this is a Command (mutates via aggregate) or a Query (reads → DTO).
2. Create `application/features/<use-case>/` with: `<use-case>.command.js` (or `.query.js`) exporting
   a `<UseCase>Type` string tag + a command/query factory fn + a Zod schema; `<use-case>.handler.js`
   exporting a handler factory (`handler({ deps }) => async (request) => ...`); and a route in the
   module's router that parses the request, builds the message via the factory, sends it to the
   `Mediator`, and returns the response.
3. Commands: load aggregate via repository → apply a pure aggregate operation `(state, args) ->
   { state, events }` → `repo.save(state, events)` (the outbox write happens in the same DB
   transaction). Queries: project with Prisma straight to the DTO; do not load the full aggregate.
4. Register the handler with the module's `Mediator` in `<name>.module.js`, keyed by its `<UseCase>Type`
   tag — mediator middleware (Zod validation → logging → unit-of-work) already covers cross-cutting
   concerns; don't re-implement them in the handler.

See `templates/command.js.template` and `templates/handler.js.template` for the skeletons.
