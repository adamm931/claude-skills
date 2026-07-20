#!/usr/bin/env bash
set -euo pipefail

# Only run if there is a solution in the project directory.
cd "${CLAUDE_PROJECT_DIR:-.}"
if ! ls ./*.sln >/dev/null 2>&1; then
  exit 0
fi

echo "verify: dotnet build"
dotnet build --nologo -clp:ErrorsOnly

# Architecture/boundary tests (NetArchTest / ArchUnitNET), if present.
if dotnet sln list 2>/dev/null | grep -qi "Architecture.Tests"; then
  echo "verify: architecture tests"
  dotnet test --nologo --filter "Category=Architecture"
fi
