---
name: postgres-query
description: >
  Run SQL queries against the project's PostgreSQL instance using psql. Use when asked to query
  Postgres, inspect tables or schemas, or run SQL locally.
---

# Query PostgreSQL

Run from the project root. Load credentials from `.env` first:

```bash
set -a && . ./.env && set +a
export PGPASSWORD="$POSTGRES_PASSWORD"
```

## Basic query

```bash
psql -h localhost -p "${POSTGRES_PORT:-5432}" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT version()"
```

## Common meta-commands

```bash
-c "\l"                      # list databases
-c "\dt"                     # list tables
-c "\d orders"                # describe a table
-c "\dn"                      # list schemas
-c "SELECT COUNT(*) FROM orders"
```

Backslash meta-commands only work through `psql`; they are not SQL.

## Script files

```bash
psql -h localhost -p "${POSTGRES_PORT:-5432}" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f script.sql
```

## Cleaner output for scripting

```bash
-t          # tuples only, no headers or row count
-A          # unaligned, good for piping
-q          # quiet
-F ","      # field separator (with -A)
```

```bash
psql -h localhost -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAq -c "SELECT id FROM orders LIMIT 5"
```

## Non-interactive safety

Add `-v ON_ERROR_STOP=1` when running scripts — without it, `psql` continues past failed statements
and still exits `0`.

## Writes

Confirm with the user before `DROP`, `TRUNCATE`, or an unqualified `DELETE`/`UPDATE` (no `WHERE`).

## If the connection fails

1. `postgres-status` — is the container up and healthy?
2. A password mismatch means `.env` changed after the volume was initialized — see `postgres-reset`.
3. Connecting from inside another container in the same compose project? Use the service name
   `postgres` as the host, not `localhost` — `localhost` only works from the host machine.
