---
name: aggregate-design
description: >
  Rules and review checklist for modeling aggregates, entities, value objects, and domain events in
  this solution. Use when creating or changing a domain model, an aggregate root, a value object, or
  a domain event.
---

# Aggregate & domain-model design

## Aggregate roots
- Keep aggregates SMALL: root + owned value objects. Large aggregates cause write contention.
- The root is the only entry point; expose collections as read-only (`IReadOnlyList`).
- All invariants are enforced INSIDE the root's methods. No public setters on domain state.
- Reference other aggregates BY ID, never by object reference.
- Mutate ONE aggregate per transaction; use a domain event to update others eventually.

## Value objects
- Immutable `record`s, defined by their values, self-validating in the constructor.
- No identity, no side effects. Good for Money, Address, Email, DateRange.

## Domain events
- Recorded by the aggregate (`Raise(...)`), implement `IDomainEvent` (plain marker; no MediatR).
- Carry what happened; may reference the aggregate. Handled in-process by `IDomainEventHandler<T>`.
- Dispatched around SaveChanges, in the same transaction; translate to integration events for
  cross-module effects (see the `integration-event` skill).

## Factories
- Construct aggregates through a factory (`{{Aggregate}}.Create(...)`) so they are born valid.
