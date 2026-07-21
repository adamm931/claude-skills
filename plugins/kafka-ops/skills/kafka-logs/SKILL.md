---
name: kafka-logs
description: >
  Fetch recent logs from the project's Kafka broker. Use when asked to see Kafka logs, or to debug
  why Kafka won't start or is unhealthy.
---

# Kafka logs

Run from the project root.

```bash
docker compose -f docker/kafka.compose.yml logs --tail=100 kafka
```

Bounded tail, not `-f` — a following log stream never returns and hangs a non-interactive tool call.

Common causes of an unhealthy/crash-looping broker, in order of likelihood:
1. `KAFKA_CLUSTER_ID` in `.env` doesn't match the ID already stored in the `kafka-data` volume from
   an earlier run — the broker refuses to start. Fix via `kafka-reset` (destructive — confirm
   first) or by restoring the original `KAFKA_CLUSTER_ID` value.
2. Port `${KAFKA_PORT:-9092}` already bound by another process/container on the host.
3. Slow start mistaken for failure — Kafka legitimately takes 20-40s; check the timestamp of the
   last log line before assuming it's stuck.
