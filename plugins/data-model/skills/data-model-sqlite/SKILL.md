---
name: data-model-sqlite
description: >
  Write or update a SQLite data-layer spec as a versioned iteration doc — schema, indexes,
  key strategy, and migration conventions, following SQLite's specific storage, type-affinity,
  and single-writer behavior. Use when the user asks to spec, design, or document a database
  schema on SQLite (including libSQL/Turso and better-sqlite3 / node:sqlite setups).
---

# Writing a SQLite data-layer spec

Pairs one-to-one with an API spec (see the `api-spec` plugin): same iteration number and slug,
`docs/specs/<NN>-<feature-slug>/<NN>-<feature-slug>.data-layer.md`.

## Header

```markdown
# {ProjectName} — {NN} {Feature Title} · Data Layer

**Status:** Not started | Draft | Implemented | Placeholder
**Database:** SQLite {version}, {how it runs — e.g. "embedded, file-per-env"; "libSQL/Turso"}
**Driver:** {e.g. "better-sqlite3", "node:sqlite (Node 24+)", "@libsql/client"}
**Covers:** [iteration N API]({relative link to the .api.md})
```

The **Driver** line is worth carrying in the header for SQLite specifically (the other engine
variants don't need it): SQLite is embedded in-process, so the driver *is* the database runtime,
and several schema decisions below (pragmas, sync vs async access, `STRICT` support) depend on it.

## Section order

Same engine-agnostic shape as the Postgres/SQL Server variants:

1. **Tables** — bullet list of tables introduced/changed. Record deliberate absences (e.g. "no
   `user_id` anywhere yet") as facts, not gaps.
2. **What lands here** — schema, indexes, migrations, non-trivial queries this doc owns.
3. **Constraints inherited from the API spec** — one bullet per API design decision with a schema
   consequence, linking back to the API spec section. This is the seam between the two docs.
4. **Key strategy** — see below.
5. **Migration scripts** — see conventions below.
6. **Local database** — for SQLite this is "which file, which driver, which pragmas," not "which
   Docker image." See below.
7. **Seed data** — kept OUT of migrations, never journaled, idempotent via a reserved id
   range/prefix the script owns (delete-then-reinsert those rows only, never a blanket `DELETE`).
   Default to a minimum of 5 rows per table unless the user specifies a different count — enough to
   exercise list pagination, filters, and joins without every query degenerating to a 1-row trivial
   case. Fewer than 5 is fine only if the user asks for a smaller/minimal seed explicitly.
8. **Schema verification** — an independent check that the end state is correct, not just that
   migrations exited 0. `CREATE TABLE IF NOT EXISTS` guards make scripts safely re-runnable but also
   let one silently no-op against a partially-built database; `PRAGMA table_info(...)` /
   `PRAGMA foreign_key_list(...)` are the cheap independent assertions here.
9. **Implemented** — `| Rule | Enforced by |`, mapping each invariant to the actual constraint
   (`CHECK`, composite FK, unique index) enforcing it. Prefer a constraint the database enforces
   structurally over "the service layer checks it" — but see the foreign-keys pragma trap below,
   because in SQLite "there's an FK in the DDL" does **not** guarantee it's enforced.
10. **Open** — specified but not yet built.

## Key strategy: it's a real fork in SQLite — pick per table, and say which

SQLite's storage model makes this decision genuinely different from the server engines. Don't port
the Postgres or SQL Server writeup; the tradeoff is structured differently here.

Every ordinary SQLite table is a B-tree **keyed on a 64-bit `rowid`**. If you declare a column as
`INTEGER PRIMARY KEY`, that column *becomes* the rowid (an alias) — the table is physically ordered
by it, lookups by it are the fastest possible path, and there's no second structure. Any other
primary key (a `TEXT`/`BLOB` UUID, a composite key) is stored as a **separate unique index** while
the table stays rowid-ordered underneath — so you pay for two structures, and PK lookups do an
index-to-rowid indirection.

That gives two defensible defaults; state which one this table uses and why:

- **`INTEGER PRIMARY KEY` (rowid alias)** — the SQLite-native default. Narrowest possible key,
  fastest joins and lookups, sequential inserts, no fragmentation concern. The cost is the classic
  one: the id is server-assigned (not known before insert, so no offline-write / batch-with-in-memory-
  references), monotonic and guessable, and enumerable if it ever leaks to a public API. Fine for
  internal tables and anything where a separate public id is acceptable.
- **`TEXT`/`BLOB` UUIDv7 primary key** — when ids must be known before insert, non-enumerable, or
  stable across a later move to libSQL/Turso replicas or a distributed setup. UUIDv7 keeps the
  time-ordering (so the separate PK index still inserts sequentially rather than fragmenting). Store
  it as a **16-byte `BLOB`** where you can — half the size of the 36-char `TEXT` form, and the
  time-ordered high bytes sort correctly by plain byte comparison (SQLite has none of SQL Server's
  `UNIQUEIDENTIFIER` byte-reordering trap). Use `TEXT` only when human-readability in ad-hoc queries
  outweighs the width.
  - Do **not** also declare it `INTEGER PRIMARY KEY`-adjacent by adding a surrogate rowid you then
    expose — that recreates the "two ids forever" problem. The hidden rowid already exists; just let
    it stay hidden. If PK-lookup indirection ever measurably hurts, `WITHOUT ROWID` (below) is the
    lever, not a second exposed id.

### `WITHOUT ROWID` — the SQLite-specific option

For a table whose primary key is a non-integer you look up by constantly (e.g. a `TEXT` natural key,
a UUID PK on a hot lookup table), `CREATE TABLE ... WITHOUT ROWID` makes that PK the actual clustering
key — no rowid, no second structure, no indirection. Best for tables with short keys and few secondary
indexes (every secondary index copies the full PK). Not a default; call it out only when a table's
access pattern actually warrants it, and never for tables that lean on `INTEGER PRIMARY KEY` speed.

## SQLite-specific column conventions worth stating explicitly in the spec

SQLite has **dynamic typing with type affinity** — by default a column will store a string in an
`INTEGER` column without complaint. State how the spec defends against that, and pick per-column
representations SQLite doesn't have native types for:

- **`STRICT` tables** (SQLite 3.37+): default to declaring tables `CREATE TABLE ... (...) STRICT`.
  This turns type affinity into actual type enforcement (a `TEXT`-into-`INTEGER` write now errors),
  which is almost always what a spec'd schema wants. Note the constraint: `STRICT` tables allow only
  the types `INTEGER`, `REAL`, `TEXT`, `BLOB`, `ANY` — so the representations below are chosen from
  that set. Confirm the driver ships a SQLite ≥ 3.37 (all current Node drivers do).
- **Timestamps: no native date/time type.** Pick one representation and state it:
  `TEXT` ISO-8601 UTC (`'2026-07-22T14:30:00Z'` — human-readable, sorts lexically, works with
  `date()`/`datetime()` functions) or `INTEGER` Unix epoch (compact, cheap arithmetic). Default to
  ISO-8601 `TEXT` unless the table is large/append-heavy. Never store local-time strings.
- **Booleans: no native type.** `INTEGER` holding `0`/`1`, with a `CHECK (col IN (0,1))`. Say so;
  don't let a "boolean" column silently accept `2`.
- **UUIDs: no native type.** `BLOB` (16 bytes, preferred) or `TEXT` (36 chars) — see key strategy.
- **JSON: no native type, but first-class functions.** Store as `TEXT` and use SQLite's JSON
  functions; on SQLite 3.45+ the `jsonb` functions store a more compact binary form in a `BLOB`.
  Add a `CHECK (json_valid(col))` (or `json_valid(col, ...)`) so malformed JSON can't land.
- **Money / exact decimals:** SQLite has no `DECIMAL` type — `REAL` is IEEE-754 float and will not
  represent money exactly. Store integer minor units (cents) in `INTEGER`, and say so.
- **Length/format rules are `CHECK` constraints**, not column-type widths — SQLite ignores
  `VARCHAR(n)` length. `CHECK (length(name) <= 200)` if the cap is a real business rule.
- **Partial indexes** for soft-delete/scoping filters: `CREATE INDEX ... WHERE deleted_at IS NULL`
  — supported since SQLite 3.8, smaller than a full index, matches the common query shape.
- Prefer `CHECK` constraints and composite foreign keys for invariants that can be made structurally
  impossible — same principle as the other engines, **but see the pragma trap next.**

### The SQLite trap: foreign keys are OFF by default

`PRAGMA foreign_keys = ON` must be issued **on every connection** — it is not a schema property and
not persisted in the database file; it defaults to OFF for backwards compatibility. A schema full of
`REFERENCES` clauses enforces nothing on a connection that forgot the pragma. The spec must state,
explicitly:

- The pragma is set on every connection (most Node setups do this once at pool/connection open —
  `db.pragma('foreign_keys = ON')` in better-sqlite3, `PRAGMA` on open with node:sqlite).
- The **Implemented** table's "Enforced by: FK" rows are only true *given that pragma* — worth a
  one-line footnote there, because "there's an FK in the DDL" is not sufficient evidence in SQLite.

## Migration scripts

```
migrations/<NN>-<feature-slug>/
├── 001_create_things.sql
├── 002_create_other_things.sql
├── 003_add_foo_id_nullable.sql        # structural — nullable first
├── 004_backfill_foo_id.sql            # data — separate script from structure
├── 005_add_foo_id_constraints.sql     # rebuild table to add NOT NULL + FK (see below)
└── 006_rebuild_indexes_with_foo_id.sql
```

Naming: `NNN_verb_object.sql`, zero-padded, unique and never reused within the iteration folder.
Use whatever migration runner the project has (a `user_version`-pragma-based runner, Drizzle Kit,
Knex, a custom one) — these rules are tool-agnostic:

- **Forward-only.** No down-migrations — a production rollback is a fiction; the fix for a bad
  migration is a new forward script.
- **One concern per script.** A failed script should leave one obvious, small thing to fix.
- **Each script runs in a transaction.** SQLite wraps DDL transactionally — including `ALTER TABLE`
  and the table-rebuild sequence below — so a failed script leaves no half-applied state. This is
  stronger than SQL Server (where some DDL can't be transacted); lean on it. The one thing that
  *cannot* be inside a transaction is a schema change that requires toggling
  `PRAGMA foreign_keys` (see the rebuild note) — keep that in its own script.
- **Idempotent guards** — `CREATE TABLE IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS`,
  `ALTER TABLE ... ADD COLUMN` (SQLite has no `IF NOT EXISTS` on `ADD COLUMN` — guard it in the
  runner or via `PRAGMA table_info`). Re-running the folder must be safe.
- **Never edit an applied script.** Once it has run anywhere that isn't throwaway-local, it's
  immutable; corrections are a new script. State whether the runner checksums applied scripts — a
  `user_version`-based runner typically records only a version number, so this is convention-only.
- **Structural changes and data backfills are separate scripts.**

### SQLite's `ALTER TABLE` is limited — plan for the 12-step rebuild

SQLite's `ALTER TABLE` supports only: `RENAME TABLE`, `RENAME COLUMN`, `ADD COLUMN`, and
`DROP COLUMN` (drop since 3.35). It **cannot** add a `NOT NULL` column with FK constraints in place,
change a column type, add a `CHECK`/FK to an existing column, or alter a PK. Any of those requires
the documented **table-rebuild sequence**, which the spec should name explicitly when a migration
needs it:

1. `PRAGMA foreign_keys = OFF;` (outside the transaction).
2. `BEGIN;`
3. `CREATE TABLE things_new (...)` with the desired final schema.
4. `INSERT INTO things_new SELECT ... FROM things;`
5. `DROP TABLE things;`
6. `ALTER TABLE things_new RENAME TO things;`
7. Recreate indexes, triggers, views that referenced the table.
8. `PRAGMA foreign_key_check;` (assert no violations before committing).
9. `COMMIT;`
10. `PRAGMA foreign_keys = ON;`

So a **retrofit adding ownership/tenancy** (e.g. adding `user_id` later) splits into: `ADD COLUMN`
nullable → backfill (a separate data script) → **table rebuild** to land `NOT NULL` + the FK +
composite indexes leading with the new column → widen constraints that were global and become
per-tenant (e.g. a `UNIQUE(name)` index becomes `UNIQUE(tenant_id, name)`). Document now, in the
current iteration's index list, which indexes will eventually lead with the new column — it turns
the future rebuild into a mechanical rewrite instead of a schema audit.

## Local database

SQLite has no server to run — the "how it runs locally" is the file path, the driver, and the
connection-time pragmas. State all three:

- **File & environments** — one file per environment (`./data/app.dev.sqlite`,
  `:memory:` for tests). Pin the file location relative to the project, and note whether it's
  gitignored (it should be — the schema lives in migrations, not the file).
- **Driver** — the Node library the app connects with. Common choices:
  - **`better-sqlite3`** — synchronous, fastest, the long-standing default; prepared statements and
    transactions built in.
  - **`node:sqlite`** — the built-in `DatabaseSync` (stable in Node 24, experimental 22.5+); no
    dependency, synchronous, good for new projects on current Node.
  - **`@libsql/client`** — libSQL fork; identical local file mode plus a path to Turso/remote
    replicas later without a schema rewrite.
  - (`sqlite3` / node-sqlite3 — the older async callback library; note it if the project already
    uses it, but don't pick it for new work.)
- **Connection pragmas** — set on every connection open, and named in the spec because they're not
  in the file:
  - `PRAGMA foreign_keys = ON;` — required for FK enforcement (see the trap above).
  - `PRAGMA journal_mode = WAL;` — write-ahead logging; lets readers proceed concurrently with a
    single writer, the right default for anything with concurrent access. (Persisted in the file
    once set, unlike the others — set it once at setup, but state it.)
  - `PRAGMA busy_timeout = <ms>;` — SQLite allows exactly one writer at a time; without a busy
    timeout, a concurrent write fails immediately with `SQLITE_BUSY` instead of waiting. Set a
    few-second timeout so brief write contention retries instead of erroring.
  - `PRAGMA synchronous = NORMAL;` — the standard, safe pairing with WAL (`FULL` is only needed
    without WAL). State the choice.

### The concurrency note worth stating up front

SQLite is **single-writer**: one write transaction at a time for the whole database file, WAL or not.
This is usually a non-issue for embedded/low-concurrency apps and is what makes SQLite fast and
simple — but if the API spec implies many concurrent writers (background jobs + request writes +
imports all hitting the same tables), say so here, because it's an architecture constraint, not a
tuning knob. WAL + `busy_timeout` mitigates contention; it does not make writes parallel.
