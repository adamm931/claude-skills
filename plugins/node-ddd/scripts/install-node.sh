#!/usr/bin/env bash
# Installs Node.js via nvm and activates pnpm via Corepack. Idempotent.
# Usage: install-node.sh [version]   (version defaults to --lts, e.g. 20, 22, --lts)
set -euo pipefail

version="${1:---lts}"
nvm_version="v0.40.1"

have_node() {
    command -v node >/dev/null 2>&1
}

if have_node; then
    echo "node: ok ($(node --version))"
else
    echo "-> installing Node.js ${version} via nvm"
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    if [ ! -s "$NVM_DIR/nvm.sh" ]; then
        curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_version}/install.sh" | bash
    fi
    # shellcheck disable=SC1091
    . "$NVM_DIR/nvm.sh"
    nvm install "$version"
    nvm use "$version"
    echo "-> add the nvm init block to your shell profile to persist this (see nvm's install output above)"
fi

if command -v corepack >/dev/null 2>&1; then
    corepack enable >/dev/null 2>&1 || true
    corepack prepare pnpm@latest --activate >/dev/null 2>&1 || true
fi

if have_node; then
    pnpm_version="$(command -v pnpm >/dev/null 2>&1 && pnpm --version || echo 'not found')"
    echo "node: ok ($(node --version)), pnpm: ${pnpm_version}"
else
    echo "node: still MISSING after install — check output above" >&2
    exit 1
fi
