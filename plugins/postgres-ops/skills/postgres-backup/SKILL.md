---
name: postgres-backup
description: >
  Back up or restore the project's PostgreSQL database with pg_dump/pg_restore. Use when asked to
  back up, dump, export, restore, or import Postgres data.
---

# Backup and restore PostgreSQL

Run from the project root.

## Backup (plain SQL dump)

```bash
docker compose -f docker/postgres.compose.yml exec -T postgres \
    pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" > backup.sql
```

## Backup (custom format — supports selective/parallel restore)

```bash
docker compose -f docker/postgres.compose.yml exec -T postgres \
    pg_dump -U "$POSTGRES_USER" -Fc "$POSTGRES_DB" > backup.dump
```

## Restore (plain SQL dump)

```bash
docker compose -f docker/postgres.compose.yml exec -T postgres \
    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 < backup.sql
```

## Restore (custom format)

```bash
docker compose -f docker/postgres.compose.yml exec -T postgres \
    pg_restore -U "$POSTGRES_USER" -d "$POSTGRES_DB" --clean --if-exists < backup.dump
```

`--clean --if-exists` drops existing objects before recreating them — confirm with the user before
restoring into a database that already has data, since this overwrites it.

## Keep dumps out of the repo

Add `*.sql.bak`, `backup.sql`, `*.dump` (whatever pattern applies) to `.gitignore` — a dump can
contain real or seeded data that shouldn't be committed, and dumps grow the repo indefinitely if
someone forgets.

## Local file vs container

`pg_dump`/`pg_restore` run **inside** the container via `exec`; the redirect (`>`/`<`) happens on
the host shell, so the resulting file lands in the project directory, not inside the container.
