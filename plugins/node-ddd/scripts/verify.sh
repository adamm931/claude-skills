#!/usr/bin/env bash
set -euo pipefail

# Only run if there is a package.json in the project directory.
cd "${CLAUDE_PROJECT_DIR:-.}"
if [ ! -f package.json ]; then
  exit 0
fi

# Plain JS project: no typecheck step. A syntax smoke-check via node --check if a src exists.
if command -v node >/dev/null 2>&1 && [ -d src ]; then
  echo "verify: syntax"
  find src -name '*.js' -print0 | xargs -0 -r -n1 node --check
fi

# Module boundary check (dependency-cruiser), if configured.
if [ -f .dependency-cruiser.cjs ]; then
  echo "verify: module boundaries"
  npx --no-install depcruise src --config .dependency-cruiser.cjs
elif [ -f .dependency-cruiser.js ]; then
  echo "verify: module boundaries"
  npx --no-install depcruise src --config .dependency-cruiser.js
fi
