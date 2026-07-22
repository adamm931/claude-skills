---
name: api-spec-run
description: >
  Call and test a REST API's endpoints with curl on Linux, driven by its spec doc. Reads an
  `.api.md` iteration spec (from `api-spec-rest`) — or a spec pasted/described inline — turns each
  endpoint into a runnable curl command, chains them into a realistic flow, and checks the responses
  against what the spec promises. Use when the user asks to call, hit, exercise, smoke-test, or
  verify API endpoints against a spec, or to generate curl commands from one.
---

# Running a REST API from its spec

Turn a spec into `curl` calls, run them against a live server, and check each response against what
the spec says should happen. The spec is the source of truth for paths, bodies, representations, and
status codes — read it first, don't guess the surface.

## 1. Get the spec and the base URL

- **Spec source.** Prefer the iteration doc at `docs/specs/<NN>-<slug>/<NN>-<slug>.api.md`. If the
  user names a file, read that. If they paste or describe the API inline, work from that instead —
  the doc is convenient, not required. Pull from it: the **Endpoints** tables (method, path,
  purpose/body), the **Representations** JSON, and the **Errors** status-code table.
- **Base URL.** Ask if unknown; default to `http://localhost:3000` (or the port the project's run
  skill / `docker compose` / `.env` reveals). Store it once so it's swappable:

  ```bash
  BASE=http://localhost:3000
  ```

- **Server up?** Do a cheap liveness check before anything else — a health route if the spec has
  one, else the list endpoint. If it fails to connect, stop and point the user at starting the
  server (the project's run skill); don't report the endpoints as broken when nothing is listening.

## 2. Curl conventions (Linux)

Keep every call in the same shape so output is comparable and greppable:

```bash
curl -sS -X POST "$BASE/api/v1/things" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name":"first"}' \
  -w '\n%{http_code}\n'
```

- `-sS` — silent but still show errors. `-w '\n%{http_code}\n'` prints the status on its own line so
  you (and the assertions) can read it without `-i` noise.
- Use `-i` instead only when a header is the thing under test (e.g. a `Location` on `201`).
- One `$BASE` variable, never a hardcoded host. Capture auth once into `$TOKEN` and reuse it.
- For a response you need to read fields out of, pipe the body through `jq`; keep the status check
  separate (see below). If `jq` isn't installed, say so and fall back to `python3 -m json.tool`.
- **Never** put a real secret or password on the command line in a form you'll echo back — read it
  from an env var or a prompt, and redact it in anything you show the user.

## 3. Chain the calls into a real flow

Don't fire endpoints in isolation — exercise the lifecycle the way the spec's create→read→update→
delete arc implies, threading IDs through so the test proves the resource actually persisted:

```bash
# create, capture the id the spec says it returns
ID=$(curl -sS -X POST "$BASE/api/v1/things" \
  -H 'Content-Type: application/json' \
  -d '{"name":"first"}' | jq -r '.id')

# read it back
curl -sS "$BASE/api/v1/things/$ID" -w '\n%{http_code}\n'

# update, then delete, then confirm the delete took (expect 404)
curl -sS -X PATCH "$BASE/api/v1/things/$ID" -H 'Content-Type: application/json' -d '{"name":"renamed"}' -w '\n%{http_code}\n'
curl -sS -X DELETE "$BASE/api/v1/things/$ID" -w '\n%{http_code}\n'
curl -sS "$BASE/api/v1/things/$ID" -w '\n%{http_code}\n'   # spec says 404 now
```

Build the request bodies from the spec's **Representations** with realistic values, not
`<placeholder>` tokens. For a state-transition endpoint (`POST /things/:id/complete`) call the
dedicated route the spec defines — don't `PATCH` a field the spec deliberately didn't expose.

## 4. Check responses against the spec

For each call, verify — don't just dump output:

- **Status code** matches the spec's Errors table for that condition. This is the assertion that
  actually catches regressions, so make it explicit:

  ```bash
  code=$(curl -sS -o /tmp/body.json -w '%{http_code}' "$BASE/api/v1/things/$ID")
  test "$code" = "200" && echo "PASS read=$code" || echo "FAIL read=$code (expected 200)"
  ```

- **Body shape** matches the Representation — required fields present, IDs carry the spec's prefix
  (`tsk_`, `usr_`), timestamps present where the spec chose a timestamp over a boolean.
- **The negative cases the spec cares about**, not just the happy path — these are where specs and
  implementations drift:
  - a not-owned / non-existent resource returns `404` (the spec's anti-enumeration rule), never
    `403`;
  - a malformed body returns `400`, a semantically-invalid one `422` — hit the *specific* `422`
    conditions the spec names;
  - an enumeration-oracle endpoint (password-reset-requested) returns its silent `204` regardless
    of input;
  - statuses the spec marks as "not yet" (e.g. `401` before auth ships) are genuinely absent.

## 5. Report

Give a compact pass/fail summary keyed to the spec, most useful line first:

```
POST   /api/v1/things            201  PASS  → tsk_9f2, Location present
GET    /api/v1/things/tsk_9f2    200  PASS
GET    /api/v1/things/tsk_zzz    404  PASS  (not-found → 404, no leak)
PATCH  /api/v1/things/tsk_9f2    422  FAIL  expected 200 — body: {"error":"name required"}
```

For each FAIL, quote the actual status and body and say which line of the spec it contradicts —
that's what makes the run actionable. If the mismatch is the spec being wrong rather than the code
(the spec promised a field the API sensibly doesn't return), flag it as a spec bug and suggest
updating the doc via `api-spec-rest`, don't silently "fix" the expectation.

## Make it repeatable

When the flow is more than a couple of calls, write it to a script in the project's scratch/scripts
area (`scripts/smoke/<slug>.sh`) with `set -euo pipefail`, `$BASE`/`$TOKEN` at the top, and the
assertions inline — so the same spec check can be re-run after the next change instead of retyped.
Offer this; don't create it unprompted for a one-off call.
