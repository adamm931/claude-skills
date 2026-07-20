---
name: data-model-postgres
description: >
  Write or update a PostgreSQL data-layer spec as a versioned iteration doc — schema, indexes,
  key strategy, and migration conventions, following Postgres's specific storage and MVCC
  behavior. Use when the user asks to spec, design, or document a database schema on PostgreSQL.
---

# Writing a PostgreSQL data-layer spec

Pairs one-to-one with an API spec (see the `api-spec` plugin): same iteration number and slug,
`docs/specs/<NN>-<feature-slug>/<NN>-<feature-slug>.data-layer.md`.

## Header

```markdown
# {ProjectName} — {NN} {Feature Title} · Data Layer

**Status:** Not started | Draft | Implemented | Placeholder
**Database:** PostgreSQL {version}, {how it runs locally — e.g. "local, Docker"}
**Covers:** [iteration N API]({relative link to the .api.md})
```

## Section order

Same shape as the SQL Server variant — this section order is engine-agnostic:

1. **Tables** — bullet list of tables introduced/changed. Record deliberate absences (e.g. "no
   `user_id` anywhere yet") as facts, not gaps.
2. **What lands here** — schema, indexes, migrations, non-trivial queries this doc owns.
3. **Constraints inherited from the API spec** — one bullet per API design decision with a schema
   consequence, linking back to the API spec section. This is the seam between the two docs.
4. **Key strategy** — see below.
5. **Migration scripts** — see conventions below.
6. **Local database** — pin the image tag (`postgres:16.4`, not `postgres:latest` or bare `16`).
7. **Seed data** — kept OUT of migrations, never journaled, idempotent via a reserved id
   range/prefix the script owns (delete-then-reinsert those rows only, never a blanket `DELETE`).
8. **Schema verification** — an independent check that the end state is correct, not just that
   migrations exited 0 — `IF NOT EXISTS` guards make scripts safely re-runnable but also let one
   silently no-op against a partially-built database.
9. **Implemented** — `| Rule | Enforced by |`, mapping each invariant to the actual constraint
   (check constraint, composite FK, exclusion constraint) enforcing it — prefer a constraint the
   database enforces structurally over "the service layer checks it."
10. **Open** — specified but not yet built.

## Key strategy: default to `uuid` holding a UUIDv7

The reasoning is similar to SQL Server's (time-ordered, application-generated ids beat random or
server-only-known ids), but the *mechanism* is different — don't port the SQL Server writeup
verbatim, because Postgres's storage model removes the specific trap that drives it there.

- **Not UUIDv4** as the primary key if avoidable — same insert-locality argument as any B-tree PK:
  a random key means every insert lands at a random point in the PK's btree, so pages split more and
  cache locality for "recent rows" (the common access pattern) is worse. It's a real but *smaller*
  cost in Postgres than in SQL Server — see below.
- **UUIDv7** (native `uuidv7()` in Postgres 18+; use the `pg_uuidv7` extension or generate it in the
  application on earlier versions) keeps the same benefits as elsewhere: time-ordered inserts,
  ids known before insert (client-generated-id / offline-write / batch-insert scenarios), and no
  extra "public id" column.
- **Not a `bigint` sequence as the only id** for the same reason as SQL Server: forces a second
  public id for anything client-facing, and forecloses pre-insert id generation. Name it as the
  documented escape hatch for extreme write-volume cases, not the default.

### Why this is a smaller deal in Postgres than SQL Server

Postgres tables are **heaps**, not clustered indexes — there's no "the table IS the PK index"
behavior, so a random PK does not fragment the table itself the way it fragments a SQL Server
clustered index. Postgres's `uuid` type also has **no byte-reordering quirk**: it compares by
straightforward byte value, so a UUIDv7's time-ordering in the high bytes is directly visible to the
PK's btree — no `Seq`-column workaround needed. Store `Id uuid` as the primary key directly:

```sql
id  uuid primary key default gen_random_uuid(),  -- or app-generated uuidv7()
```

The real cost of a random key in Postgres is narrower: btree bloat/locality on the PK index itself,
and WAL/cache pressure if the access pattern is "recent rows" (the common case). UUIDv7 still helps
here — just don't carry over the SQL Server clustering writeup; it doesn't apply.

### A Postgres-specific option: BRIN indexes

For very large, append-mostly, time-ordered tables (audit logs, event tables), consider a `BRIN`
index on a UUIDv7 id or a `created_at` column instead of a btree — BRIN indexes are dramatically
smaller and are effective precisely because UUIDv7/timestamp values correlate with physical insertion
order. Not a default; call it out only when a table's shape and scale actually warrant it.

## Postgres-specific column conventions worth stating explicitly in the spec

- `timestamptz`, never bare `timestamp` — bare `timestamp` silently discards timezone information;
  there's essentially never a reason to choose it for anything user-facing.
- `text`, not `varchar(n)` — Postgres has no performance difference between them, and an arbitrary
  length cap is a migration you'll eventually have to run for no benefit. Use a `CHECK` constraint
  if a length limit is a real business rule, not a `varchar(n)` guess.
- `jsonb`, not `json`, for any flexible/semi-structured column — `jsonb` is indexable (GIN) and
  binary-stored; `json` only preserves exact text formatting, which is rarely what's wanted.
- Generated/materialized path columns (the Postgres equivalent of a denormalized `path` for tree
  reads) can be `GENERATED ALWAYS AS (...) STORED` when the value is a deterministic function of
  other columns in the same row; use an application-maintained column instead when it depends on the
  parent row (most materialized-path cases — the parent's path isn't visible to a generated
  expression, which only sees the current row).
- Soft-delete / scoping filters as **partial indexes**: `CREATE INDEX ... WHERE deleted_at IS NULL`
  — smaller than a full index and directly matches the common query shape.
- Prefer `CHECK` constraints and composite foreign keys for invariants that can be made structurally
  impossible (e.g. "a child's parent must belong to the same tenant") over relying on service-layer
  checks — same principle as the MSSQL variant of this skill.

## Migration scripts

```
migrations/<NN>-<feature-slug>/
├── 001_create_things.sql
├── 002_create_other_things.sql
├── 003_add_foo_id_nullable.sql        # structural — nullable first
├── 004_backfill_foo_id.sql            # data — separate script from structure
├── 005_add_foo_id_constraints.sql     # NOT NULL + FKs, after backfill
└── 006_rebuild_indexes_with_foo_id.sql
```

Naming: `NNN_verb_object.sql`, zero-padded, unique and never reused within the iteration folder.
Use whatever migration runner the project has standardized on (golang-migrate, Flyway, sqlx, a
custom DbUp-style runner, etc.) — these rules are tool-agnostic:

- **Forward-only.** No down-migrations — a production rollback is a fiction; the fix for a bad
  migration is a new forward script.
- **One concern per script.** A failed script should leave one obvious, small thing to fix.
- **Each script runs in a transaction.** Postgres wraps almost all DDL transactionally by default
  (unlike SQL Server, where several DDL operations explicitly cannot run inside a transaction) — lean
  on this; a failure leaves no half-applied state. The one common exception:
  `CREATE INDEX CONCURRENTLY` / `REINDEX CONCURRENTLY` cannot run inside a transaction block and
  must be its own script, alone, with that constraint called out explicitly.
- **Idempotent guards** — `CREATE TABLE IF NOT EXISTS`, `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`,
  or a `DO $$ BEGIN ... IF NOT EXISTS (...) THEN ... END IF; END $$;` block for constraints (which
  have no native `IF NOT EXISTS` form). Re-running the folder must be safe.
- **Never edit an applied script.** Once it has run anywhere that isn't throwaway-local, it's
  immutable; corrections are a new script. State plainly whether the migration runner checksums
  applied scripts (many don't, by default) — if not, this rule is enforced by convention only.
- **Structural changes and data backfills are separate scripts.** For large tables, prefer batched
  backfills (`UPDATE ... WHERE id IN (SELECT ... LIMIT n)` in a loop) over one giant statement — a
  single huge `UPDATE` holds row locks and bloats the WAL for the whole run.
- A **retrofit adding ownership/tenancy** to existing tables always splits into: add column nullable
  → backfill (batched, if large) → `NOT NULL` + FKs → rebuild composite indexes with the new column
  leading → widen constraints that were global and become per-tenant (e.g. `UNIQUE(name)` →
  `UNIQUE(tenant_id, name)`). Document now, in the current iteration's index list, which indexes will
  eventually lead with the new column — turns the future migration into a mechanical rewrite.
