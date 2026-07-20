#!/usr/bin/env bash
# Installs the host-side psql client (Debian/Ubuntu). Idempotent.
set -euo pipefail

if command -v psql >/dev/null 2>&1; then
    echo "psql: ok ($(psql --version))"
    exit 0
fi

echo "-> installing postgresql-client"
sudo apt-get update -qq
sudo apt-get install -y -qq postgresql-client

if command -v psql >/dev/null 2>&1; then
    echo "psql: ok ($(psql --version))"
else
    echo "psql: still MISSING after install — check apt output above" >&2
    exit 1
fi
