---
name: kafka-topics
description: >
  List, create, describe, or delete Kafka topics and produce/consume messages on the project's
  broker. Use when asked about Kafka topics, partitions, consumer groups, or publishing and reading
  events locally.
---

# Kafka topics and messages

Broker from the host: `localhost:${KAFKA_PORT:-9092}`. From another container in the same compose
project: `kafka:29092`. Using the wrong one from the wrong place is the usual cause of a hang.

## Inspect (kcat, no JVM)

```bash
kcat -b localhost:9092 -L                    # brokers, topics, partitions
kcat -b localhost:9092 -L -t orders          # one topic
```

## Produce

```bash
echo '{"id":1,"status":"new"}' | kcat -b localhost:9092 -t orders -P

# with a key
echo 'value' | kcat -b localhost:9092 -t orders -P -k my-key
```

Auto-topic-creation is enabled, so producing to an unknown topic creates it with default settings
(single partition, replication factor 1).

## Consume

```bash
kcat -b localhost:9092 -t orders -C -o beginning -e     # all, then exit
kcat -b localhost:9092 -t orders -C -o end               # only new (blocks)
kcat -b localhost:9092 -t orders -C -o -10 -e             # last 10
kcat -b localhost:9092 -t orders -C -o beginning -e -f 'p%p o%o k%k: %s\n'
```

**Always pass `-e` in a non-interactive session.** Without it, `kcat` waits for more messages
forever and hangs the tool call.

## Topic administration

`kcat` cannot create or delete topics with explicit settings — use the broker's bundled scripts via
`docker compose exec` (service name `kafka`, not a hardcoded container name):

```bash
docker compose -f docker/kafka.compose.yml exec kafka \
    /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list

docker compose -f docker/kafka.compose.yml exec kafka \
    /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 \
    --create --topic orders --partitions 3 --replication-factor 1

docker compose -f docker/kafka.compose.yml exec kafka \
    /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic orders

docker compose -f docker/kafka.compose.yml exec kafka \
    /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --delete --topic orders
```

**Replication factor must be `1`** — this is a single-broker dev cluster; any higher value fails.

## Consumer groups

```bash
docker compose -f docker/kafka.compose.yml exec kafka \
    /opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list

docker compose -f docker/kafka.compose.yml exec kafka \
    /opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
    --describe --group my-group
```

`--describe` shows lag per partition — the first thing to check when a consumer looks stuck.

## If it hangs or times out

Test from inside the container:

```bash
docker compose -f docker/kafka.compose.yml exec kafka \
    /opt/kafka/bin/kafka-broker-api-versions.sh --bootstrap-server localhost:9092
```

Works inside but not from the host → the `EXTERNAL` advertised listener is wrong; it must resolve to
`localhost:${KAFKA_PORT:-9092}`. Check `docker/kafka.compose.yml`'s `KAFKA_ADVERTISED_LISTENERS`.

## Destructive operations

Deleting a topic or resetting consumer offsets loses data — confirm with the user first.
