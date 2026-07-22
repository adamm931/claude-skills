#!/usr/bin/env bash
set -euo pipefail

# Only run if there is a package.json in the project directory.
cd "${CLAUDE_PROJECT_DIR:-.}"
if [ ! -f package.json ]; then
  exit 0
fi

# Plain JS project: no typecheck step. Syntax smoke-check via `node --check` if src exists.
if command -v node >/dev/null 2>&1 && [ -d src ]; then
  echo "verify: syntax"
  find src -name '*.js' -print0 | xargs -0 -r -n1 node --check
fi

# Layer-boundary check: the API layer must never import the pg Pool or write SQL directly;
# the data layer must never import Express. Cheap grep guardrails (advisory, non-fatal).
if [ -d src/api ]; then
  if grep -rnE "from '#?/?.*data/pool" src/api 2>/dev/null; then
    echo "verify: WARNING — src/api imports the pg Pool. Routes must call a service, not the data layer." >&2
  fi
fi
if [ -d src/data ]; then
  if grep -rnE "from 'express'" src/data 2>/dev/null; then
    echo "verify: WARNING — src/data imports express. The data layer must not know about HTTP." >&2
  fi
fi
