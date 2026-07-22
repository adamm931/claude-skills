# Changelog

## 2.0.0
- BREAKING: switched the whole stack from TypeScript to **plain JavaScript (ESM), functional style —
  no classes**. Templates are now `.js`.
- Mediator is now `createMediator()` (a factory returning `{ register, use, send }`) and dispatches by
  a request's string `type` tag instead of by class/`constructor`.
- Aggregates are modules of pure functions over `Object.freeze`d state; operations return
  `{ state, events }` (events returned, not raised on `this`). Value objects are frozen-object
  factories. `DomainError` class replaced by the `domainError()` factory (+ `isDomainError`).
- Commands/queries are plain message objects from factory fns; handlers are functions with DI by
  partial application. Dropped the `Entity`/`AggregateRoot`/`IDomainEvent` base types.
- verify hook drops the `tsc` typecheck (adds a `node --check` syntax pass); dependency-cruiser config
  drops `tsConfig`.

## 1.0.0
- Initial release: architecture-rules constitution; node-setup, init-ddd, new-module, vertical-slice,
  integration-event, and aggregate-design skills; ddd-reviewer agent; PostToolUse verify hook.
