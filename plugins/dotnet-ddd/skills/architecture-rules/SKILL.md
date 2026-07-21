---
name: architecture-rules
description: >
  The mandatory architecture rules for this .NET solution: DDD tactical patterns,
  vertical slice organization, module boundaries, MediatR for in-process messaging,
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
- Organize by feature under `Features/<UseCase>/`, not by technical layer.
- Commands go through the aggregate + one transaction. Queries project straight to DTOs.
- Every request is a MediatR `IRequest`; cross-cutting concerns go in pipeline behaviors
  (validation → logging → unit-of-work), never copy-pasted into handlers.

## Messaging
- In-process (commands, queries, domain events): MediatR.
- Between modules (integration events): MassTransit. In-memory in the monolith, broker after split.
- Integration events are flat/serializable. Domain events may carry the aggregate.

## Reliability
- Publish integration events through the MassTransit EF Core outbox (`UseBusOutbox`), staged in the
  same transaction as the aggregate. Consumers MUST be idempotent (dedupe on message id).

When asked to add code, follow these rules exactly. If a request violates a rule, say so and propose
the compliant alternative.
