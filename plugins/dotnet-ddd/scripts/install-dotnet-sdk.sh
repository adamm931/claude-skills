#!/usr/bin/env bash
# Installs the .NET SDK (Debian/Ubuntu). Idempotent.
# Usage: install-dotnet-sdk.sh [channel]   (channel defaults to 9.0, e.g. 8.0, 9.0, LTS)
set -euo pipefail

channel="${1:-9.0}"

have_channel() {
    dotnet --list-sdks 2>/dev/null | grep -q "^${channel%.0}\."
}

if command -v dotnet >/dev/null 2>&1 && have_channel; then
    echo "dotnet sdk: ok ($(dotnet --list-sdks | grep "^${channel%.0}\." | head -n1))"
    exit 0
fi

echo "-> installing .NET SDK ${channel} via apt (Microsoft package feed)"
if command -v apt-get >/dev/null 2>&1; then
    tmp_deb="$(mktemp --suffix=.deb)"
    . /etc/os-release
    curl -fsSL "https://packages.microsoft.com/config/${ID}/${VERSION_ID}/packages-microsoft-prod.deb" -o "$tmp_deb" \
        || curl -fsSL "https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb" -o "$tmp_deb"
    sudo dpkg -i "$tmp_deb" >/dev/null
    rm -f "$tmp_deb"
    sudo apt-get update -qq
    sudo apt-get install -y -qq "dotnet-sdk-${channel}" || sudo apt-get install -y -qq dotnet-sdk-8.0
else
    echo "-> apt-get not found, falling back to dotnet-install.sh (installs to ~/.dotnet)"
    curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
    bash /tmp/dotnet-install.sh --channel "$channel" --install-dir "$HOME/.dotnet"
    export PATH="$HOME/.dotnet:$PATH"
    echo "-> add 'export PATH=\"\$HOME/.dotnet:\$PATH\"' to your shell profile to persist this"
fi

if command -v dotnet >/dev/null 2>&1 && have_channel; then
    echo "dotnet sdk: ok ($(dotnet --list-sdks | grep "^${channel%.0}\." | head -n1))"
else
    echo "dotnet sdk: still MISSING after install — check output above" >&2
    exit 1
fi
