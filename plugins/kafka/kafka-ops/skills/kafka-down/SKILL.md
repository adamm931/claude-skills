---
name: kafka-down
description: >
  Stop the project's Kafka broker (and kafka-ui if present) without deleting topic data. Use when
  asked to stop, shut down, or turn off Kafka locally.
---

# Stop Kafka

Run from the project root.

```bash
docker compose -f docker/kafka.compose.yml down
[ -f docker/kafka-ui.compose.yml ] && docker compose -f docker/kafka-ui.compose.yml down
```

This stops and removes the containers but **keeps the named volume** (`kafka-data`) — topics,
messages, and consumer offsets survive. Do not add `-v` here; that's a destructive reset, handled by
the `kafka-reset` skill, and must never be run without the user explicitly confirming.
