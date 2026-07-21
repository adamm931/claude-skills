---
name: aggregate-design
description: >
  Rules and review checklist for modeling aggregates, entities, value objects, and domain events in
  this project. Use when creating or changing a domain model, an aggregate root, a value object, or a
  domain event.
---

# Aggregate & domain-model design

## Aggregate roots
- Keep aggregates SMALL: root + owned value objects. Large aggregates cause write contention.
- The root is the only entry point; expose collections as readonly arrays, never mutable ones.
- All invariants are enforced INSIDE the root's methods. No public setters on domain state — use
  private fields with getters.
- Reference other aggregates BY ID, never by object reference.
- Mutate ONE aggregate per transaction; use a domain event to update others eventually.

## Value objects
- Immutable classes or readonly types, defined by their values, self-validating in the constructor
  (or a static factory that throws `DomainError`).
- No identity, no side effects. Good for Money, Address, Email, DateRange.

## Domain events
- Recorded by the aggregate (`this.raise(...)`), implementing `IDomainEvent`.
- Carry what happened; may reference the aggregate (they stay in-process via the `Mediator`).
- Dispatched around the repository's `save()`, in the same transaction; translate to integration
  events for cross-module effects (see the `integration-event` skill).

## Factories
- Construct aggregates through a static factory (`{{Aggregate}}.create(...)`) so they are born valid.
