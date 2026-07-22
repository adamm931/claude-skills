# Changelog

## 1.1.0
- Add `api-spec-run` skill: turn a REST `.api.md` spec (or an inline spec) into runnable `curl`
  calls on Linux, chain them into a create→read→update→delete flow, and assert each response
  (status codes, representation shape, the spec's not-found/validation/enumeration rules) against
  what the spec promises. Reports a compact pass/fail summary and flags spec-vs-code drift.

## 1.0.0
- Initial release: `api-spec-rest` skill (methodology extracted from the ToDoly iteration-spec
  convention — header block, numbered sections, design-decision writeups, error envelope, deferred
  scope, open questions). `api-spec-graphql` reserved, not yet built.
