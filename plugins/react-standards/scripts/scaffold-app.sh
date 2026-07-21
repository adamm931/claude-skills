#!/usr/bin/env bash
# Scaffolds a React + TypeScript (Vite) app with the feature-based folder structure and the
# dependencies that react-standards' skills assume are present. Idempotent — safe to re-run;
# skips anything that already exists.
#
# Usage: scaffold-app.sh <AppName> [OutputDir]
set -euo pipefail

AppName="${1:?Usage: scaffold-app.sh <AppName> [OutputDir]}"
OutputDir="${2:-.}"

mkdir -p "$OutputDir"
cd "$OutputDir"

if [[ ! -f "$AppName/package.json" ]]; then
    npm create vite@latest "$AppName" -- --template react-ts
else
    echo "-> $AppName/package.json already exists, skipping vite scaffold"
fi

cd "$AppName"

echo "-> installing base dependencies"
npm install \
    react-router-dom \
    react-hook-form zod @hookform/resolvers \
    @tanstack/react-query \
    jotai \
    sonner

echo "-> installing dev dependencies (lint/format)"
npm install -D \
    eslint-plugin-jsx-a11y eslint-plugin-simple-import-sort \
    prettier eslint-config-prettier \
    husky lint-staged

mkdir -p src/app src/features src/components src/hooks src/lib src/pages src/types src/styles/tokens tests

# main.tsx already exists from the vite template; the rest are created empty as placeholders for
# the app-scaffold skill to fill in (App.tsx, router.tsx, providers.tsx, store.ts).
for f in App.tsx router.tsx providers.tsx store.ts; do
    [[ -f "src/app/$f" ]] || touch "src/app/$f"
done

echo "-> app scaffold ready at $OutputDir/$AppName"
echo "-> next: app-scaffold skill fills in src/app/*.tsx; theming skill sets up src/styles/"
