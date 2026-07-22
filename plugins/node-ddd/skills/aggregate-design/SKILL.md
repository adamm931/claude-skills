---
name: aggregate-design
description: >
  Rules and review checklist for modeling aggregates, value objects, and domain events in this project
  (plain JS, functional — no classes). Use when creating or changing a domain model, an aggregate, a
  value object, or a domain event.
---

# Aggregate & domain-model design

The domain is a **functional core**: immutable state + pure functions. No classes, no `this`, no
mutation. An aggregate lives in one module file (e.g. `domain/order.js`) exporting a factory and
operations.

## Aggregate state
- Keep aggregates SMALL: a root object + its owned value objects. Large aggregates cause write
  contention.
- State is plain data frozen with `Object.freeze` (freeze nested objects/arrays too). Never mutate —
  operations return a NEW frozen state.
- Reference other aggregates BY ID, never by embedded object.

## Operations (pure functions)
- Construct through a `create(...)` factory that validates every invariant and returns frozen state
  (born valid) — throw `domainError(...)` on violation.
- Each mutating operation is a pure function `(state, args) -> { state, events }`: it validates the
  invariant, returns the next frozen state, and returns the domain events it produced. It does NOT
  persist, publish, or mutate the input.
- All invariants live in these functions. There are no setters to guard because nothing outside the
  module can change state — callers only get new state back.
- Update ONE aggregate per transaction; use a domain event to update others eventually.

```js
// domain/order.js
import { domainError } from '../../../shared-kernel/index.js';
import { orderPlaced } from './events.js';

export const createOrder = ({ id, customerId, lines }) => {
  if (!lines?.length) throw domainError('Order needs at least one line.');
  return Object.freeze({ id, customerId, status: 'draft', lines: Object.freeze([...lines]) });
};

export const placeOrder = (order) => {
  if (order.status !== 'draft') throw domainError('Only a draft order can be placed.');
  const state = Object.freeze({ ...order, status: 'placed' });
  return { state, events: [orderPlaced(order.id, order.customerId)] };
};
```

## Value objects
- Factory functions returning `Object.freeze({...})`, defined by their values and self-validating in
  the factory (throw `domainError`). No identity, no side effects. Good for Money, Address, Email,
  DateRange.

```js
export const money = (amount, currency) => {
  if (!Number.isFinite(amount) || amount < 0) throw domainError('Money must be >= 0.');
  return Object.freeze({ amount, currency });
};
```

## Domain events
- Plain-object factory functions (`orderPlaced(id, customerId) => ({ name: 'orders.orderPlaced', ... })`).
- RETURNED from aggregate operations (in the `events` array), never raised on `this`. The
  repository's `save(state, events)` dispatches/persists them in the same transaction.
- Carry what happened; may reference aggregate state since they stay in-process via the `Mediator`.
  Translate to integration events for cross-module effects (see the `integration-event` skill).
