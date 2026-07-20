---
name: integration-event
description: >
  Add an integration event so one module can react to something that happened in another, wired
  through the MassTransit EF Core outbox for reliable, idempotent delivery. Use when the user wants
  cross-module or cross-service reactions (e.g. reserve stock when an order is placed).
---

# Adding an integration event

1. Define the event as a flat, serializable record in the SOURCE module's `*.Public/IntegrationEvents/`.
   Primitives only (Guid, decimal, string, lists) — never a domain aggregate.
2. In the source module, a domain-event handler stages it in the outbox (do NOT publish to the bus
   directly). With MassTransit's EF outbox, calling `Publish`/`Send` inside the transaction stages it.
3. In each REACTING module, add an `IConsumer<TEvent>` referencing the source `*.Public`. Register it
   with `x.AddConsumer<...>()`. Keep the consumer idempotent — dedupe on the event id.
4. Confirm the module owns the reaction (loads its own aggregate, one aggregate per transaction).

Transport is in-memory in the monolith (`UsingInMemory`) and a broker after extraction
(`UsingRabbitMq` / Azure Service Bus) — the event and consumer code do not change.
