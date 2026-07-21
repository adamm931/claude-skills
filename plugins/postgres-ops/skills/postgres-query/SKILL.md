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

## No local `psql` and no working `sudo`

`install-psql-cli.sh` already handles this: if `sudo -n apt-get install` fails non-interactively, it
falls back to a root-free install — `apt-get download` (writes `.deb`s to the cwd, no root needed)
plus `dpkg -x` (extracts without installing) into `~/.local/lib/pgclient`, with a `~/.local/bin/psql`
wrapper that sets `LD_LIBRARY_PATH` for `libpq.so.5`. Just re-run the script; nothing below should be
needed on a Debian/Ubuntu host with `~/.local/bin` on `PATH`.

If that *still* doesn't work (non-apt base, no network access for `apt-get download`, `~/.local/bin`
not on `PATH` and can't be added), fall back further to running `psql` inside the Postgres container
itself — the `postgres:*` image already ships it. Get the container name from `docker compose ps`
(defaults to `<project-dir-name>-postgres-1`) and pipe credentials from `.env` the same way:

```bash
set -a && . ./.env && set +a
docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" -i <container> \
  psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT version()"
```

Script files pipe over stdin (no `-f`, since the file lives on the host, not in the container):

```bash
docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" -i <container> \
  psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" < script.sql
```

Multiple ad-hoc statements (including meta-commands like `\dt`) work well as a heredoc against the
same `docker exec -i ... psql` invocation, one query per `\echo`-labeled block for readable output.

This is also the fallback when the host user can't reach the Docker daemon directly (not in the
`docker` group, no interactive `sudo` available to fix that either) — `sg docker -c "docker exec -i
... psql ..."` applies the group membership for a single command without needing a fresh login
session.
