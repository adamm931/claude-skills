---
name: dotnet-setup
description: >
  Verify the .NET SDK is installed (installing it if missing) before scaffolding or building
  anything in this plugin. Use when asked to set up, install, or check the .NET SDK, or before
  running `init-ddd`/`new-module` in an environment where `dotnet` hasn't been confirmed to work yet.
---

# Set up the .NET SDK

This is a one-time (per machine) check — run it before `init-ddd` if you haven't already confirmed
`dotnet` works in this environment this session.

## 1. Check what's already there

```bash
dotnet --version
dotnet --list-sdks
```

If a suitable SDK major version is already installed, skip to step 3.

## 2. Install the SDK if missing

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/install-dotnet-sdk.sh" [channel]
```

Idempotent — re-checks `dotnet --list-sdks` first and exits early if the requested channel (default
`9.0`; pass `8.0` etc. for a specific version) is already present. Installs via Microsoft's package
feed on Debian/Ubuntu (apt), falling back to the official `dotnet-install.sh` script (installs to
`~/.dotnet`) if `apt-get` isn't available — in that fallback case, tell the user to add
`export PATH="$HOME/.dotnet:$PATH"` to their shell profile so it persists across sessions.

## 3. Confirm

```bash
dotnet --version
```

Report the resolved version before moving on to `init-ddd` or `new-module`.
