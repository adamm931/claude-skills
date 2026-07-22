---
name: architecture-rules
description: >
  The mandatory architecture rules for this Node.js project (plain JavaScript, ESM, functional — no
  classes): DDD tactical patterns, vertical slice organization, module boundaries, an in-process
  Mediator for commands/queries/domain events, and the outbox pattern for integration events. Consult
  before creating or modifying any module, slice, aggregate, event, or handler.
---

# Architecture Constitution

## Style
- Plain JavaScript, ES modules (`import`/`export`, `"type": "module"`). NO classes anywhere — use
  factory functions, closures, and modules of pure functions.
- State is plain data, made immutable with `Object.freeze`; never mutate in place.
- There are no compile-time types, so contracts are enforced at runtime: Zod schemas at the edges,
  self-validating factories in the domain. Use JSDoc for editor hints, not enforcement.

## Boundaries
- One module = one bounded context, under `src/modules/<name>/`. Modules import each other ONLY via
  `src/modules/<name>/public` (its `index.js` barrel).
- Everything outside `public/` (`domain/`, `application/`, `infrastructure/`) is module-internal —
  enforced by the `.dependency-cruiser.cjs` rule added for each module. Never deep-import another
  module's internals.
- Modules relate by id. No cross-module joins or foreign keys. Each module owns its own Postgres
  schema (Prisma multi-file schema, `@@schema("<name>")`).

## Domain model
- Aggregates small; reference other aggregates by id; ONE aggregate updated per transaction.
- An aggregate is a module of PURE functions over an immutable state object: a `create(...)` factory
  plus operations shaped `(state, args) -> { state, events }`. Invariants are enforced inside those
  functions and in self-validating value-object factories — there is no state to set from outside.
- Value objects are factory functions returning `Object.freeze({...})`, validating in the factory
  (throw `domainError`). No identity, no side effects.
- Aggregate operations RETURN the domain events they produced; they do not raise on `this` or publish
  to a bus themselves.

## Slices (features)
- Organize by feature under `application/features/<use-case>/`, not by technical layer.
- Commands go through the aggregate + one transaction. Queries project straight to DTOs via Prisma,
  bypassing the aggregate.
- Every request is a plain message object with a string `type` tag (built by a command/query factory
  fn) handled by the module's `Mediator`; cross-cutting concerns (Zod validation, logging,
  unit-of-work) are mediator middleware, never copy-pasted into handlers.
- Handlers are functions, not classes: `handler({ deps }) => async (request) => response` (DI by
  partial application).

## Messaging
- In-process (commands, queries, domain events): the hand-rolled functional `Mediator`
  (`createMediator()`) in the shared kernel, dispatching by the request's `type` tag.
- Between modules (integration events): outbox table + relay. In-memory `EventEmitter` in the
  monolith; Kafka (`kafkajs` — see the `kafka-ops` plugin for a project-local broker) after splitting
  into services.
- Integration events are flat/serializable (JSON-safe) objects. Domain events may carry the aggregate
  state (they stay in-process via the `Mediator`).

## Reliability
- Write integration events to an `OutboxMessage` row in the SAME transaction as the aggregate change;
  a relay publishes unsent rows and marks them sent. Consumers MUST be idempotent — dedupe on event id
  (an `InboxMessage` table) before acting.

When asked to add code, follow these rules exactly. If a request violates a rule, say so and propose
the compliant alternative.
