---
name: integration-event
description: >
  Add an integration event so one module can react to something that happened in another, wired
  through an outbox table + relay for reliable, idempotent delivery. Use when the user wants
  cross-module or cross-service reactions (e.g. reserve stock when an order is placed).
---

# Adding an integration event

1. Define the event as a flat, JSON-serializable type in the SOURCE module's
   `public/integration-events/`. Primitives only (string, number, ISO date strings, arrays) — never a
   domain aggregate.
2. In the source module, a domain-event handler writes a row to the module's `OutboxMessage` table in
   the SAME transaction as the aggregate save (do NOT publish directly from the aggregate or handler).
3. A relay (a poller, or Postgres `LISTEN`/`NOTIFY` off the outbox table) reads unpublished outbox rows
   and publishes them — in-process via `EventEmitter` in the monolith, or to Kafka (`kafkajs`; see the
   `kafka-ops` plugin for a project-local broker) after splitting into services — then marks them sent.
4. In each REACTING module, add a listener/consumer for the event, importing only the source module's
   `public`. Keep it idempotent: check the event id against the `InboxMessage` table before acting, and
   insert into it in the same transaction as the reaction.
5. Confirm the module owns the reaction (loads its own aggregate, one aggregate per transaction).

Transport is swappable (`EventEmitter` vs Kafka) — the event shape and consumer code do not change,
only the relay's publish call.
