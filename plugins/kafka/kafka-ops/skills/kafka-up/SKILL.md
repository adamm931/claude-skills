---
name: kafka-up
description: >
  Start the project's Kafka broker (and kafka-ui if present). Use when asked to start, bring up,
  boot, or launch Kafka locally.
---

# Start Kafka

Run from the project root (where `docker/kafka.compose.yml` lives — see `kafka-setup` if it
doesn't exist yet).

```bash
docker compose -f docker/kafka.compose.yml up -d
```

If `docker/kafka-ui.compose.yml` exists and the user wants the UI too:

```bash
docker compose -f docker/kafka-ui.compose.yml up -d
```

## Always wait before reporting success

Kafka takes noticeably longer than most containers to become ready — 20-40s is normal. Poll the
healthcheck rather than reporting success immediately:

```bash
timeout 90 bash -c '
until [ "$(docker compose -f docker/kafka.compose.yml ps -q kafka | xargs docker inspect -f "{{.State.Health.Status}}")" = "healthy" ]; do
  sleep 3
done'
```

If it times out, check logs (`kafka-logs`) rather than retrying blindly. The most common cause is a
`KAFKA_CLUSTER_ID` in `.env` that doesn't match the ID already stored in the `kafka-data` volume
from a previous run with a different value — that needs `kafka-reset`, not a retry.

Report the port it's listening on (`${KAFKA_PORT:-9092}`) once healthy.
