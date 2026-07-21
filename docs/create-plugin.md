# Creating a plugin in this marketplace

This repo is a single Claude Code **marketplace** (`.claude-plugin/marketplace.json`) that hosts
multiple **plugins**, each living directly under `plugins/` — one folder per plugin, no grouping
folder in between.

## Naming convention

Every plugin is named:

```
{stack}-{topic}
```

- `stack` — the language/framework/platform the plugin targets (`dotnet`, `node`, `react`, ...).
- `topic` — the specific concern or pattern the plugin covers within that stack (`ddd`,
  `data-fetching`, `auth`, ...).

The name itself carries the stack — a folder grouping would just repeat what's already in the name.

Examples:

| Plugin name | Topic |
|---|---|
| `dotnet-ddd` | Domain-Driven Design / modular monolith |
| `node-ddd` | Domain-Driven Design |
| `react-data-fetching` | Data fetching (React Query, etc.) |
| `api-spec` | API spec writing (REST, GraphQL, ...) |
| `data-model` | Data-layer spec writing (Postgres, MSSQL, ...) |

Use all-lowercase, hyphen-separated (kebab-case) — the directory name under `plugins/` IS the plugin
name, with no nesting.

### One plugin per topic, dialects are skills

**Dialects or variants of the same topic are skills inside one plugin, not separate plugins.**
`api-spec` is one plugin covering "how to write an API spec"; REST and GraphQL are two *skills*
inside it, because they're the same job with a different notation — a consumer installing `api-spec`
should get both, and Claude picks the right one from context. Same for `data-model`: Postgres and
MSSQL are skills, not plugins, because the doc-writing methodology is the same and only the
engine-specific sections differ.

```
plugins/
├── api-spec/                              ← plugin
│   └── skills/
│       ├── api-spec-rest/SKILL.md         ← skill (dialect: REST)
│       └── api-spec-graphql/SKILL.md      ← skill (dialect: GraphQL)
└── data-model/                            ← plugin
    └── skills/
        ├── data-model-postgres/SKILL.md   ← skill (dialect: PostgreSQL)
        └── data-model-mssql/SKILL.md      ← skill (dialect: SQL Server)
```

Reach for a second *plugin* only when the two things are genuinely separable and a consumer might
reasonably want one without the other (`dotnet-ddd` vs some future `dotnet-testing`). Reach for a
second *skill* inside one plugin when they're the same job in a different dialect.

A setup/install step for a dependency the plugin needs (Docker services, an SDK, a CLI) is also a
skill inside the plugin, not its own plugin — see `dotnet-setup` inside `dotnet-ddd`, or
`postgres-setup`/`kafka-setup` inside their respective ops plugins. It only earns a plugin of its own
if a second, unrelated plugin for the same stack shows up later and needs to share it.

### Reserving space for a planned plugin

Before a plugin has real content, create its directory under `plugins/` with an empty `.gitkeep` file
so the tree/layout is visible in git even though there's no `plugin.json` yet. Do **not** add a
planned plugin to `.claude-plugin/marketplace.json` until it actually has a `plugin.json` — an entry
pointing at an empty folder will fail to install.

## Layout of a plugin

Each plugin lives at `plugins/{stack}-{topic}/` and follows this shape:

```
plugins/{stack}-{topic}/
├── .claude-plugin/
│   └── plugin.json          # manifest — the ONLY file allowed in .claude-plugin/
├── skills/
│   └── <skill-name>/
│       ├── SKILL.md
│       └── templates/       # optional, only directory skills can bundle files
├── agents/
│   └── <agent-name>.md      # optional — subagents, own context/model/tools
├── hooks/
│   └── hooks.json           # optional
├── scripts/
│   └── *.sh                 # optional, referenced from hooks.json via ${CLAUDE_PLUGIN_ROOT}
├── LICENSE
└── CHANGELOG.md
```

Rules:
- Only `plugin.json` goes inside `.claude-plugin/`. `skills/`, `agents/`, `hooks/`, `scripts/` sit at
  the plugin root, or they won't be discovered.
- A plugin-root `CLAUDE.md` is **not** loaded as context. Ship rules/conventions as an
  always-relevant skill instead (see `dotnet-ddd`'s `architecture-rules` skill for the pattern).
- Prefer a *directory* skill (`skills/<name>/SKILL.md`) over a flat command file whenever the skill
  needs to bundle templates or reference docs alongside it.
- Set `name` in `plugin.json` to the full `{stack}-{topic}` plugin name, matching the directory.

## Steps to add a new plugin

1. Create the directory: `plugins/{stack}-{topic}/` with the layout above.
2. Write `.claude-plugin/plugin.json`:
   ```json
   {
     "$schema": "https://json.schemastore.org/claude-code-plugin-manifest.json",
     "name": "{stack}-{topic}",
     "displayName": "Human-readable name",
     "version": "1.0.0",
     "description": "One sentence describing what this plugin does.",
     "author": { "name": "adamm931" },
     "repository": "https://github.com/adamm931/claude-skills",
     "license": "MIT",
     "keywords": ["stack", "topic", "..."]
   }
   ```
3. Add skills/agents/hooks as needed.
4. Register it in the root `.claude-plugin/marketplace.json`:
   ```json
   {
     "name": "{stack}-{topic}",
     "source": "./plugins/{stack}-{topic}",
     "description": "One sentence, same as plugin.json."
   }
   ```
5. Validate and test locally before pushing:
   ```bash
   claude plugin validate ./plugins/{stack}-{topic} --strict
   claude --plugin-dir ./plugins/{stack}-{topic}
   ```
6. Commit and push. Consumers already tracking this marketplace pick it up on
   `/plugin marketplace update`; new consumers run:
   ```bash
   /plugin marketplace add adamm931/claude-skills
   /plugin install {stack}-{topic}@claude-skills
   ```
