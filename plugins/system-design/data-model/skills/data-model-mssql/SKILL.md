---
name: data-model-mssql
description: >
  Write or update a SQL Server data-layer spec as a versioned iteration doc — schema, indexes,
  key strategy, and migration conventions, following SQL Server's specific storage and clustering
  behavior. Use when the user asks to spec, design, or document a database schema on SQL Server.
---

# Writing a SQL Server data-layer spec

Pairs one-to-one with an API spec (see the `api-spec` plugin): same iteration number and slug,
`docs/specs/<NN>-<feature-slug>/<NN>-<feature-slug>.data-layer.md`.

## Header

```markdown
# {ProjectName} — {NN} {Feature Title} · Data Layer

**Status:** Not started | Draft | Implemented | Placeholder
**Database:** SQL Server, {how it runs locally — e.g. "local, Docker"}
**Covers:** [iteration N API]({relative link to the .api.md})
```

## Section order

1. **Tables** — a flat bullet list of table names introduced or changed this iteration. If a prior
   iteration explicitly does NOT have some column/table (e.g. no `UserId` anywhere pre-auth), say so
   here — it's the cleanest place to record the absence as a deliberate fact, not an oversight.
2. **What lands here** — one line each for: schema (columns/types/constraints/defaults), indexes,
   migrations, and any non-trivial queries (tree operations, rebalancing, etc.) that this doc owns.
3. **Constraints inherited from the API spec** — a bullet per API-spec design decision that has a
   schema consequence, each linking back to the API spec section it came from. This is the seam
   between the two docs — every "why does this column/index exist" question should be answerable by
   following one of these links.
4. **Key strategy** — see below. Always its own section; the ID strategy has enough downstream
   consequences (index width, insert pattern, offline-write feasibility) to justify a explicit writeup
   even when the answer is "just use IDENTITY."
5. **Migration scripts** — see conventions below.
6. **Local database** — how to run the engine locally. Pin the image tag (`mssql/server:2022-latest`
   is a moving target disguised as a pin — prefer a dated tag if the vendor offers one), not `latest`.
7. **Seed data** — kept OUT of the migrations folder, never journaled (a migration's contract is
   "runs exactly once, forever"; seed data's contract is the opposite — must be re-runnable). Idempotent
   via a reserved ID prefix/range the seed script owns and deletes-then-reinserts, never a blanket
   `DELETE FROM`.
8. **Schema verification** — an independent check (a small tool/script asserting every expected
   table/constraint/index exists) that restates what the migrations create. Worth calling out
   explicitly: `IF NOT EXISTS` guards make migrations safe to re-run but also let a script silently
   no-op against a partially-built database and still exit 0 — verification is the check that the
   end state is right, not just that the steps didn't error.
9. **Implemented** — once built, a table: `| Rule | Enforced by |` mapping each invariant from the
   API spec to the actual constraint name that enforces it in the database, not just in application
   code. If an invariant can be made structurally impossible (a composite FK, a check constraint)
   prefer that over "the service layer checks it."
10. **Open** — what's specified but not yet built.

## Key strategy: default to application-generated UUIDv7 in `UNIQUEIDENTIFIER`

This is the default recommendation for SQL Server; state it and justify it rather than assuming it's
obvious, because the alternatives are each reasonable-sounding and wrong for different reasons:

- **Not UUIDv4.** SQL Server's clustered index physically orders the table by key. A random v4 key
  means every insert lands on an arbitrary page — constant page splits, table fragmentation, and
  every nonclustered index also carries the (wide, random) clustering key, inflating all of them.
- **Not `NEWSEQUENTIALID()`.** Fixes ordering, but it's server-generated (the app can't know the id
  before insert — forecloses client-generated-id use cases like offline writes), leaks MAC address
  and timestamp, and resets its sequence on service restart.
- **UUIDv7** keeps a timestamp in the high bits, so values are time-ordered — inserts sequentially
  like an identity column, while staying application-generated (ids known before insert; matters for
  offline-write and batch-insert-with-in-memory-references scenarios).
- **The `BIGINT IDENTITY` + separate public-id alternative** is genuinely faster and half the width,
  and is the right call at real scale — but costs two ids per row forever (every query and mapping
  layer needs to know which is which) and forecloses client-generated ids. Don't default to it; name
  it as the documented escape hatch if write volume ever makes the width hurt (migrating to it later,
  keeping the UUID as the public id, is a contained change).

### The SQL Server-specific trap: `UNIQUEIDENTIFIER` sort order

`UNIQUEIDENTIFIER`'s comparison order is **not** byte order — it compares the last six bytes first.
UUIDv7's time-ordering lives in the *high* bytes, which that comparison order ignores, so a UUIDv7
inserted as a clustered PK fragments exactly like a v4 would. Rearranging the stored bytes into SQL
Server's comparison order "fixes" clustering but produces a value that's no longer a valid UUIDv7 to
anything reading the table directly — not worth it.

The resolution: keep `Id UNIQUEIDENTIFIER` as the actual identity, but make it a **nonclustered**
primary key, and add an internal `Seq BIGINT IDENTITY(1,1)` as the clustered key that nothing outside
the schema — no API, no FK, no query filter — ever references:

```sql
Id  UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_Things PRIMARY KEY NONCLUSTERED,
Seq BIGINT IDENTITY(1,1) NOT NULL,   -- clustered key, never exposed
```

This is not the "two ids" problem the `BIGINT IDENTITY` alternative has above — `Seq` is a storage
detail, not an identifier; nothing ever branches on it. It buys sequential inserts (no fragmentation),
an 8-byte clustering key (narrow, so every nonclustered index that carries it stays narrow), and keeps
UUIDv7 as the real, application-generated, safely-exposed identity.

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

Rules — all of these came from real incidents, not caution for its own sake:
- **Forward-only.** No down-migrations; rolling back a production schema change is a fiction, and a
  `down` path is code that never runs correctly under load. The fix for a bad migration is a new
  forward script.
- **One concern per script.** A failed script should leave one obvious, small thing to fix.
- **Each script is a single transaction** where SQL Server permits it (note: some SQL Server DDL —
  e.g. certain `ALTER TABLE` / index operations — cannot run inside an explicit transaction; check
  before assuming).
- **Idempotent guards** — `IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE ...)`. Re-running the folder
  must be safe.
- **Never edit an applied script.** Once it has run anywhere that isn't throwaway-local, it's
  immutable; corrections are a new script. If the journal doesn't checksum applied scripts (common —
  e.g. DbUp records name + applied-at only), this rule is enforced by convention alone; say so
  explicitly rather than implying it's enforced.
- **Structural changes and data backfills are separate scripts**, named as such
  (`004_backfill_foo_id.sql`) — different runtimes, different failure modes, harder to reason about
  mixed.
- A **retrofit that adds ownership/tenancy to existing tables** (e.g. adding `UserId` later) always
  splits into: add column nullable → backfill → add NOT NULL + FKs → rebuild composite indexes with
  the new column leading → widen any constraint that was global and becomes per-tenant. Document
  *now*, in the current iteration's index/constraint list, which ones will eventually lead with the
  new column — it turns the future migration into a mechanical rewrite instead of a schema audit.

### Engine-specific gotcha worth a note if it applies

Filtered/partial indexes and computed columns can carry session-setting requirements — e.g. a
filtered index requires `SET QUOTED_IDENTIFIER ON` on any connection doing DML against the table, or
writes fail with error 1934. Most drivers default this on; ad-hoc tools (`sqlcmd`) often don't. Worth
a one-line callout in the spec so it isn't rediscovered mid-incident.
