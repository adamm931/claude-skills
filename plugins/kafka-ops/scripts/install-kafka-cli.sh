#!/usr/bin/env bash
# Installs kcat, the practical host-side Kafka CLI (produce/consume/inspect,
# no JVM needed). Debian/Ubuntu. Idempotent.
set -euo pipefail

if command -v kcat >/dev/null 2>&1; then
    echo "kcat: ok ($(kcat -V | head -n1))"
    exit 0
fi

echo "-> installing kcat"
sudo apt-get update -qq
sudo apt-get install -y -qq kcat

if command -v kcat >/dev/null 2>&1; then
    echo "kcat: ok ($(kcat -V | head -n1))"
else
    echo "kcat: still MISSING after install — check apt output above" >&2
    exit 1
fi
