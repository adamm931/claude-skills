---
name: vertical-slice
description: >
  Add a new vertical slice (use case) to a module as one folder per use case with one file per
  component — command/query, handler, validator, response DTO, and endpoint — following the
  solution's Clean Architecture rules (Result pattern, custom ICommand/IQuery messaging, IEndpoint).
  Use when the user asks to add a feature, command, or query to an existing module.
---

# Adding a vertical slice

A slice is **one folder per use case, one file per component** — never a single merged file. File
and folder names are fully qualified: **`<Feature>.<UseCase>.<Component>`** (the
`module.operation.component` convention). `<Feature>` is the aggregate/area (e.g. `Order`, `Task`),
`<UseCase>` is the operation (`Create`, `Cancel`, `GetById`), `<Component>` is `Command` / `Query` /
`Validator` / `Handler` / `Response`.

## Layout

```
Features/<Feature>/<Feature>.<UseCase>/
    <Feature>.<UseCase>.Command.cs      # or .Query.cs  — the message (ICommand/IQuery)
    <Feature>.<UseCase>.Validator.cs    # commands only — FluentValidation, auto-run by decorator
    <Feature>.<UseCase>.Handler.cs      # internal sealed, returns Result / Result<T>
    <Feature>.<UseCase>.Response.cs     # queries (and commands that return a body)
Endpoints/<Feature>/<Feature>.<UseCase>/
    <Feature>.<UseCase>.cs              # internal sealed : IEndpoint (no component suffix)
```

Example — "create order": `Features/Order/Order.Create/Order.Create.Command.cs`,
`Order.Create.Validator.cs`, `Order.Create.Handler.cs`, `Order.Create.Response.cs`, and
`Endpoints/Order/Order.Create/Order.Create.cs`.

> Namespaces mirror the folder, but pick a segment that does not collide with a BCL type — use the
> plural or the full aggregate name (`...Application.Orders.Create`, not `...Task.Create`, which
> shadows `System.Threading.Tasks.Task`). The file/folder names stay dotted; only the namespace
> segment is disambiguated.

## Workflow

1. **Classify.** A state change is a **Command**; a read is a **Query**. Name from the pattern:
   `<Verb><Feature>` command, `Get<X>` / `List<X>` query.
2. **Check the Domain layer.** If the aggregate or its `<Feature>Errors` static class (the error
   factories) doesn't exist, add it first — commands return those errors, never throw.
3. **Create the Application slice** in `Features/<Feature>/<Feature>.<UseCase>/`: command/query,
   validator (commands), handler, response DTO. Types are `internal sealed` except the message
   record and the validator, which are `public` so the scanner and decorator can see them.
4. **Create the endpoint** in `Endpoints/<Feature>/<Feature>.<UseCase>/<Feature>.<UseCase>.cs` —
   `internal sealed : IEndpoint`, resolve the handler interface directly, `result.Match(...)`.
5. **Register nothing by hand.** Handlers are Scrutor-scanned, validators via
   `AddValidatorsFromAssembly(..., includeInternalTypes: true)`, endpoints via `AddEndpoints`. The
   `ValidationDecorator` runs validators before the handler; the handler never validates input shape.

## Non-negotiable conventions

- **Result, never throw** for expected failures. Handlers return `Result` / `Result<T>`; guard
  clauses `return Result.Failure(<Feature>Errors.NotFound(id))`. Exceptions are for the truly
  exceptional only.
- **Commands** load the aggregate via its repository → call an aggregate method → `SaveChanges`
  (outbox commits in the same transaction). **Queries** project with EF straight into the
  `<Feature>.<UseCase>.Response` DTO — never load or return the aggregate.
- **One `Response` per slice.** Do not share DTOs across slices even if identical today.
- **Endpoints** map `Error.Type` → HTTP status through `CustomResults.Problem` (NotFound→404,
  Conflict→409, Problem/Validation→400, Failure→500). No hand-rolled error responses.

See `templates/` for the skeleton of every component file.
