---
name: architecture-rules
description: >
  The mandatory architecture rules for this Node.js/TypeScript project: DDD tactical patterns,
  vertical slice organization, module boundaries, an in-process Mediator for commands/queries/domain
  events, and the outbox pattern for integration events. Consult before creating or modifying any
  module, slice, aggregate, event, or handler.
---

# Architecture Constitution

## Boundaries
- One module = one bounded context, under `src/modules/<name>/`. Modules import each other ONLY via
  `src/modules/<name>/public` (its `index.ts` barrel).
- Everything outside `public/` (`domain/`, `application/`, `infrastructure/`) is module-internal —
  enforced by the `.dependency-cruiser.cjs` rule added for each module. Never deep-import another
  module's internals.
- Modules relate by id. No cross-module joins or foreign keys. Each module owns its own Postgres
  schema (Prisma multi-file schema, `@@schema("<name>")`).

## Domain model
- Aggregates small; reference other aggregates by id; ONE aggregate mutated per transaction.
- Invariants live inside the aggregate root's methods, never behind public setters. Value objects are
  immutable, self-validating classes or readonly types.
- Aggregates record domain events; they do not publish to a bus themselves.

## Slices (features)
- Organize by feature under `application/features/<use-case>/`, not by technical layer.
- Commands go through the aggregate + one transaction. Queries project straight to DTOs via Prisma,
  bypassing the aggregate.
- Every request is a `Command`/`Query` object handled by the module's `Mediator`; cross-cutting
  concerns (Zod validation, logging, unit-of-work) are mediator middleware, never copy-pasted into
  handlers.

## Messaging
- In-process (commands, queries, domain events): the hand-rolled `Mediator` in the shared kernel.
- Between modules (integration events): outbox table + relay. In-memory `EventEmitter` in the
  monolith; Kafka (`kafkajs` — see the `kafka-ops` plugin for a project-local broker) after splitting
  into services.
- Integration events are flat/serializable (JSON-safe). Domain events may carry the aggregate.

## Reliability
- Write integration events to an `OutboxMessage` row in the SAME transaction as the aggregate change;
  a relay publishes unsent rows and marks them sent. Consumers MUST be idempotent — dedupe on event id
  (an `InboxMessage` table) before acting.

When asked to add code, follow these rules exactly. If a request violates a rule, say so and propose
the compliant alternative.
