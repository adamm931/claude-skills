---
name: kafka-reset
description: >
  Destroy and recreate the project's Kafka data volume. Use when asked to reset, wipe, clear data,
  or start Kafka fresh — this DELETES all topics, messages, and consumer offsets.
---

# Reset Kafka data

**This destroys data.** Confirm with the user before running anything here — name the volume that
will be deleted so they know exactly what's at stake (all topics, messages, and consumer group
offsets).

Run from the project root.

```bash
docker compose -f docker/kafka.compose.yml down
docker volume ls --filter name=kafka-data --format '{{.Name}}'   # confirm the exact volume name
docker volume rm <the volume name found above>
docker compose -f docker/kafka.compose.yml up -d
```

`down` must come first — Docker refuses to remove a volume still attached to a running container.

## When a reset is actually the fix

`KAFKA_CLUSTER_ID` is baked into the volume at first start. If it's changed in `.env` after that,
the broker refuses to start against the existing volume because the stored cluster ID no longer
matches — a reset (or restoring the old `KAFKA_CLUSTER_ID`) is the fix, not another `.env` edit
followed by a retry.

## Not a reset

Stopping Kafka keeps data and is handled by `kafka-down`. Never delete the volume when the user only
asked to stop the broker.

## After resetting

Wait for healthy (see `kafka-up`) before reporting done.
