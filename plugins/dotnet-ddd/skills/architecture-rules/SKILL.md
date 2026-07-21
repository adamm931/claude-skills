---
name: architecture-rules
description: >
  The mandatory architecture rules for this .NET solution: DDD tactical patterns,
  vertical slice organization, module boundaries, custom ICommand/IQuery messaging with the Result
  pattern for in-process handling,
  MassTransit for integration events, and the transactional outbox. Consult before
  creating or modifying any module, slice, aggregate, event, or handler.
---

# Architecture Constitution

## Boundaries
- One module = one bounded context. Modules reference each other ONLY via `*.Public`.
- All implementation types are `internal`. Never expose an aggregate or DbContext across a module.
- Modules relate by id. No cross-module joins or foreign keys. Each module owns its schema.

## Domain model
- Aggregates small; reference other aggregates by id; ONE aggregate mutated per transaction.
- Invariants live inside the aggregate root. Value objects are immutable records, self-validating.
- Aggregates record domain events; they do not publish to the bus themselves.

## Slices (features)
- Organize by feature, not by technical layer: **one folder per use case, one file per component**.
  Names are fully qualified — `<Feature>.<UseCase>.<Component>` (the `module.operation.component`
  convention): `Features/Order/Order.Create/Order.Create.Command.cs`, `.Validator.cs`, `.Handler.cs`,
  `.Response.cs`, and the endpoint at `Endpoints/Order/Order.Create/Order.Create.cs`. Never a single
  merged feature file.
- Commands go through the aggregate + one transaction. Queries project straight to DTOs.
- **Result, never throw** for expected failures: handlers return `Result` / `Result<T>` and
  `return Result.Failure(<Feature>Errors.X(...))`. Error factories live on a `<Feature>Errors` static
  class in the Domain layer; `Error.Type` (NotFound/Conflict/Problem/Validation/Failure) drives the
  HTTP status at the edge. See the `vertical-slice` skill.

## Messaging
- In-process (commands, queries): custom `ICommand` / `ICommand<T>` / `IQuery<T>` +
  `ICommandHandler<>` / `ICommandHandler<,>` / `IQueryHandler<,>` (in `SharedKernel`), discovered by
  Scrutor assembly scan. **No MediatR.** Cross-cutting concerns are Scrutor **decorators** over the
  handler interfaces (validation → logging), never copy-pasted into handlers.
- Domain events: `IDomainEvent` + `IDomainEventHandler<>`, dispatched from the unit of work.
- Endpoints implement `IEndpoint` (auto-discovered via `AddEndpoints`/`MapEndpoints`), resolve the
  handler interface directly, and translate `Result` at the edge with `result.Match(Results.Ok,
  CustomResults.Problem)`.
- Between modules (integration events): MassTransit. In-memory in the monolith, broker after split.
- Integration events are flat/serializable. Domain events may carry the aggregate.

## Reliability
- Publish integration events through the MassTransit EF Core outbox (`UseBusOutbox`), staged in the
  same transaction as the aggregate. Consumers MUST be idempotent (dedupe on message id).

When asked to add code, follow these rules exactly. If a request violates a rule, say so and propose
the compliant alternative.
