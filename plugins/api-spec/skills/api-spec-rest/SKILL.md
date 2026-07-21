---
name: api-spec-rest
description: >
  Write or update a REST API spec as a versioned iteration doc — endpoints, representations,
  and the design decisions behind them, with explicit deferred scope and open questions. Use
  when the user asks to spec, design, or document a REST API or a new feature/iteration of one.
---

# Writing a REST API spec

Specs live one per iteration/feature, at `docs/specs/<NN>-<feature-slug>/<NN>-<feature-slug>.api.md`
(zero-padded, e.g. `01-initial`, `02-user-auth`). Each iteration builds on the last — link back to
prior iterations and forward to what a later one will cover. A companion data-layer spec
(`<NN>-<feature-slug>.data-layer.md`, see the `data-model` plugin) covers schema for the same slice.

## Header

Every spec opens with a metadata block, no exceptions:

```markdown
# {ProjectName} — {NN} {Feature Title} · API

**Status:** Draft | In Review | Implemented | Placeholder
**Last updated:** {date}
**Scope:** one or two sentences — what this iteration covers and, just as important, what it
explicitly does not yet.

{One sentence pointing to the previous and next iteration, if any, as links.}
```

`Placeholder` is a legitimate status for a future iteration you're recording constraints for but
not designing yet (see "Placeholder specs" below).

## Section order

Use numbered `##` sections, roughly in this order — omit ones that don't apply, don't renumber
existing sections in later edits (append, don't reshuffle):

1. **Core model / What changes from the prior iteration** — the shape of the resource(s), or,
   for a follow-on iteration, exactly what changes on existing endpoints and why (see "Iterating on
   an existing API" below).
2. **Endpoints** — one `##` per resource family if there's more than one. Each is a table:

   ```markdown
   | Method | Path | Purpose |
   | --- | --- | --- |
   | `POST` | `/api/v1/things` | Create. Body: `{ name, parent_id? }` |
   | `GET` | `/api/v1/things/:id` | Read one |
   ```

   State the request body shape inline in the Purpose column for simple cases; break out a full
   JSON example under Representations for anything non-trivial. Note pagination style explicitly
   (cursor vs offset) and justify it if it's not the obvious default — cursor pagination avoids the
   duplicate/skip problem offset has under concurrent inserts, and is the default choice unless
   there's a reason for offset (e.g. a UI that needs page numbers).

3. **Representations** — the canonical JSON shape(s) returned, as fenced `json` blocks with
   realistic example values, not `<placeholder>` tokens. Show alternate shapes (e.g. flat vs nested
   tree) as separate examples with a one-line note on when each applies.
4. **Design decisions** — numbered subsections (`5.1`, `5.2`, ...), one non-obvious decision each.
   Each subsection: state the decision as a heading, then justify it. When an alternative was
   considered, name it and say why it lost — this is what saves the decision from being re-litigated
   later. Reserve this section for things a reviewer would ask "why not X instead?" about; skip
   decisions that are simply the obvious default.
5. **Errors** — the error envelope shape once, as a `json` block, then a status-code table:

   ```markdown
   | Status | When |
   | --- | --- |
   | `400` | Malformed request |
   | `404` | Not found |
   | `422` | Semantically invalid (be specific — name the actual conditions) |
   ```

   Note which status codes don't exist *yet* and which iteration introduces them (e.g. `401`/`403`
   arriving with auth) — this makes the envelope's growth traceable across iterations.
6. **Deferred** — an explicit list of what this iteration does NOT cover, each item linking to the
   iteration that will (or "not yet scheduled" if none). This is not filler: a reviewer scanning
   only this section should be able to tell what's intentionally out of scope vs simply missing.
7. **Open questions** — genuinely undecided things that affect the design, phrased so the decision
   is clear once made. Delete or resolve into a Design Decision once answered; don't let it become a
   graveyard.

## Iterating on an existing API

When a new iteration changes an existing surface (e.g. adding auth to an API that had none):
- Open with **"What changes in iteration N"**, not a restated core model. List what's added
  (new failure modes, new required headers) and be explicit that everything else is unchanged.
- State identity/authorization rules precisely enough to prevent a class of bug, not just describe
  behavior — e.g. "identity comes from the token, never the URL" is a rule that makes an entire bug
  class (IDOR) structurally impossible, and is worth a named subsection.
- Add new statuses to the existing error table rather than starting a new one.
- Call out any prior data that needs a migration decision (e.g. "existing rows have no owner —
  assign to X or wipe") and point to the data-layer spec for the actual migration.

## Placeholder specs

For an iteration you know is coming but haven't designed: `**Status:** Placeholder`, sketch the
expected endpoint surface as a fenced code block (method + path + one-line purpose, not a full
table), list open questions that block real design, and — most importantly — list the decisions
**already made in earlier iterations that must not foreclose this one** (e.g. "don't add a unique
constraint that assumes single ownership forever if sharing is coming"). That's the section's real
job: constraining today's design with tomorrow's known shape, cheaply.

## House rules worth defaulting to

- State transitions that aren't a simple field flip (completing a task, suspending a user) get a
  dedicated endpoint (`POST /things/:id/complete`), not `PATCH { field: true }` — it gives future
  side effects a home and keeps `PATCH` for plain field edits.
- Prefer a timestamp (`completed_at`) over a boolean when "when did this happen" has any chance of
  mattering later — the boolean is always derivable from the timestamp, never the reverse.
- Prefixed, opaque resource IDs (`usr_`, `tsk_`) — cheap at write time, saves guessing in every log
  line and bug report.
- `404`, not `403`, for a resource that exists but isn't the caller's — a `403` on someone else's
  resource confirms it exists (an enumeration leak); if identity always comes from the token, a
  non-owned row is simply absent from the query result set, and `404` falls out for free.
- Silent responses for anything that could become an enumeration oracle (password-reset-requested
  endpoints always return `204` regardless of whether the email exists).
