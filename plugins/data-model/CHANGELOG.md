# Changelog

## 1.1.0
- Add `data-model-sqlite` skill: SQLite data-layer spec conventions, adapted for SQLite's own
  storage model rather than ported from the server engines — rowid vs `INTEGER PRIMARY KEY` vs
  UUIDv7 `BLOB`/`WITHOUT ROWID` key strategy, type-affinity/`STRICT` column conventions, the
  foreign-keys-off-by-default trap, the `ALTER TABLE` 12-step table-rebuild migration pattern, and
  driver/pragma-based "local database" setup (better-sqlite3, node:sqlite, @libsql/client).

## 1.0.0
- Initial release: `data-model-mssql` and `data-model-postgres` skills (methodology extracted from
  the ToDoly data-layer-spec convention — header block, key-strategy writeup, migration script
  conventions — adapted per-engine for SQL Server clustering/`UNIQUEIDENTIFIER` behavior vs
  PostgreSQL heap storage/`uuid` behavior).
