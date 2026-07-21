#!/usr/bin/env bash
set -euo pipefail

# Only run if there is a package.json in the project directory.
cd "${CLAUDE_PROJECT_DIR:-.}"
if [ ! -f package.json ]; then
  exit 0
fi

if [ -f tsconfig.json ]; then
  echo "verify: typecheck"
  npx --no-install tsc --noEmit
fi

# Module boundary check (dependency-cruiser), if configured.
if [ -f .dependency-cruiser.cjs ]; then
  echo "verify: module boundaries"
  npx --no-install depcruise src --config .dependency-cruiser.cjs
elif [ -f .dependency-cruiser.js ]; then
  echo "verify: module boundaries"
  npx --no-install depcruise src --config .dependency-cruiser.js
fi
