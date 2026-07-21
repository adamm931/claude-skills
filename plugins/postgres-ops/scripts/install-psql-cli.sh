#!/usr/bin/env bash
# Installs the host-side psql client (Debian/Ubuntu). Idempotent.
#
# Tries `sudo apt-get install` first. If sudo isn't usable non-interactively (no
# passwordless sudo configured, no TTY to prompt), falls back to a root-free install:
# `apt-get download` (writes .debs to cwd, no root needed) + `dpkg -x` (extracts
# without installing) into ~/.local/lib/pgclient, with a ~/.local/bin/psql wrapper
# that sets LD_LIBRARY_PATH for libpq.so.5. Requires ~/.local/bin on PATH (true by
# default on most Debian/Ubuntu desktop and cloud images).
set -euo pipefail

if command -v psql >/dev/null 2>&1; then
    echo "psql: ok ($(psql --version))"
    exit 0
fi

install_via_sudo() {
    sudo -n apt-get update -qq && sudo -n apt-get install -y -qq postgresql-client
}

install_root_free() {
    echo "-> sudo unavailable non-interactively; installing psql to ~/.local without root"
    local tmp
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' RETURN
    cd "$tmp"

    # postgresql-client is a thin metapackage; resolve the real versioned package
    # (e.g. postgresql-client-18) from its Depends field.
    apt-get download postgresql-client >/dev/null
    local versioned
    versioned="$(dpkg-deb -f postgresql-client_*.deb Depends | sed 's/,.*//' | awk '{print $1}')"

    apt-get download "$versioned" libpq5 >/dev/null

    mkdir extracted
    for f in *.deb; do dpkg -x "$f" extracted; done

    local psql_bin
    psql_bin="$(find extracted -type f -name psql -path '*/bin/*' | head -1)"
    local libpq
    libpq="$(find extracted -name 'libpq.so.5*' -type f | head -1)"

    if [[ -z "$psql_bin" || -z "$libpq" ]]; then
        echo "psql: root-free extraction did not produce expected files" >&2
        return 1
    fi

    mkdir -p ~/.local/lib/pgclient ~/.local/bin
    cp "$psql_bin" ~/.local/lib/pgclient/psql
    cp "$libpq" ~/.local/lib/pgclient/
    ln -sf "$(basename "$libpq")" ~/.local/lib/pgclient/libpq.so.5

    cat > ~/.local/bin/psql <<'WRAPPER'
#!/bin/sh
exec env LD_LIBRARY_PATH="$HOME/.local/lib/pgclient:$LD_LIBRARY_PATH" "$HOME/.local/lib/pgclient/psql" "$@"
WRAPPER
    chmod +x ~/.local/bin/psql

    case ":$PATH:" in
        *":$HOME/.local/bin:"*) ;;
        *) echo "NOTE: ~/.local/bin is not on PATH — add 'export PATH=\"\$HOME/.local/bin:\$PATH\"' to your shell rc" >&2 ;;
    esac
}

echo "-> installing postgresql-client"
if ! install_via_sudo; then
    install_root_free
fi

if command -v psql >/dev/null 2>&1 || [[ -x ~/.local/bin/psql ]]; then
    hash -r
    echo "psql: ok ($(~/.local/bin/psql --version 2>/dev/null || psql --version))"
else
    echo "psql: still MISSING after install — check output above" >&2
    exit 1
fi
