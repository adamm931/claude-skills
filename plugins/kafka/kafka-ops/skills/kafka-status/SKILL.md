---
name: kafka-status
description: >
  Report whether the project's Kafka broker is running and healthy. Use when asked if Kafka is up,
  running, healthy, or what state the broker is in.
---

# Check Kafka status

Run from the project root.

```bash
docker compose -f docker/kafka.compose.yml ps
```

For the healthcheck state specifically:

```bash
docker compose -f docker/kafka.compose.yml ps -q kafka | xargs docker inspect -f '{{.State.Health.Status}}'
```

Report one of: not created (never set up — point to `kafka-setup`), created but not running (point
to `kafka-up`), `starting` (normal for the first 20-40s), `healthy`, or `unhealthy` (point to
`kafka-logs`).

If `docker/kafka-ui.compose.yml` exists, check it too and report it separately — it's optional and
its state doesn't affect whether the broker itself is usable.
