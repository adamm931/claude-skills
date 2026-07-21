---
name: node-setup
description: >
  Verify Node.js (and pnpm) are installed (installing them if missing) before scaffolding or building
  anything in this plugin. Use when asked to set up, install, or check Node.js, or before running
  `init-ddd`/`new-module` in an environment where `node` hasn't been confirmed to work yet.
---

# Set up Node.js

This is a one-time (per machine) check — run it before `init-ddd` if you haven't already confirmed
`node` works in this environment this session.

## 1. Check what's already there

```bash
node --version
pnpm --version 2>/dev/null || echo "pnpm not found"
```

If a suitable Node major version (>=20) is already installed, skip to step 3.

## 2. Install Node if missing

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/install-node.sh" [version]
```

Idempotent — re-checks `node --version` first and exits early if already present. Installs via `nvm`
(default `--lts`; pass e.g. `20` for a specific major version), then enables `pnpm` via Corepack.

## 3. Confirm

```bash
node --version && pnpm --version
```

Report the resolved versions before moving on to `init-ddd` or `new-module`.
