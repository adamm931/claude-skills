# Creating a plugin in this marketplace

This repo is a single Claude Code **marketplace** (`.claude-plugin/marketplace.json`) that hosts
multiple **plugins**, grouped into a folder per `stack` under `plugins/`, so any tech can grow more
topics later without reshuffling the tree.

## Naming convention

Every plugin is named:

```
{stack}-{topic}
```

- `stack` — the language/framework/platform the plugin targets (`dotnet`, `node`, `react`, `api`,
  `data-schema`, `system-design`, ...). Also the name of its grouping folder under `plugins/`.
- `topic` — the specific concern or pattern the plugin covers within that stack (`ddd`,
  `data-fetching`, `auth`, ...).

Examples:

| Plugin name | Stack folder (group) | Topic |
|---|---|---|
| `dotnet-ddd` | `plugins/dotnet/` | Domain-Driven Design / modular monolith |
| `node-ddd` | `plugins/node/` | Domain-Driven Design |
| `react-data-fetching` | `plugins/react/` | Data fetching (React Query, etc.) |
| `api-spec` | `plugins/system-design/` | API spec writing (REST, GraphQL, ...) |
| `data-model` | `plugins/system-design/` | Data-layer spec writing (Postgres, MSSQL, ...) |

Use all-lowercase, hyphen-separated (kebab-case) for `stack`, `topic`, and the plugin directory name
itself — the directory name IS the plugin name (just nested one level deeper, under its stack).

### The three levels: group → plugin → skill

Only two levels are ever directories under `plugins/`: the **stack/group** folder
(`plugins/{stack}/`), then the **plugin** folder (`plugins/{stack}/{plugin-name}/`). A group is
never itself a plugin (no `plugin.json` at `plugins/{stack}/`), and a plugin is never nested inside
another plugin.

**Dialects or variants of the same topic are skills inside one plugin, not separate plugins.**
`api-spec` is one plugin covering "how to write an API spec"; REST and GraphQL are two *skills*
inside it, because they're the same job with a different notation — a consumer installing `api-spec`
should get both, and Claude picks the right one from context. Same for `data-model`: Postgres and
MSSQL are skills, not plugins, because the doc-writing methodology is the same and only the
engine-specific sections differ.

```
plugins/system-design/                     ← group (not a plugin — no plugin.json here)
├── api-spec/                              ← plugin
│   └── skills/
│       ├── api-spec-rest/SKILL.md         ← skill (dialect: REST)
│       └── api-spec-graphql/SKILL.md      ← skill (dialect: GraphQL)
└── data-model/                            ← plugin
    └── skills/
        ├── data-model-postgres/SKILL.md   ← skill (dialect: PostgreSQL)
        └── data-model-mssql/SKILL.md      ← skill (dialect: SQL Server)
```

Reach for a second *plugin* under a group only when the two things are genuinely separable and a
consumer might reasonably want one without the other (`dotnet-ddd` vs some future `dotnet-testing`).
Reach for a second *skill* inside one plugin when they're the same job in a different dialect.

### Reserving space for a planned plugin

Before a plugin has real content, create its directory (and any parent grouping folders) with an
empty `.gitkeep` file so the tree/layout is visible in git even though there's no `plugin.json` yet.
Do **not** add a planned plugin to `.claude-plugin/marketplace.json` until it actually has a
`plugin.json` — an entry pointing at an empty folder will fail to install.

## Layout of a plugin

Each plugin lives at `plugins/{stack}/{stack}-{topic}/` — one folder per stack, one subfolder per
plugin in that stack — and follows this shape:

```
plugins/{stack}/{stack}-{topic}/
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

Adding a second .NET plugin later (e.g. a topic other than DDD) just adds a sibling directory:
`plugins/dotnet/dotnet-<new-topic>/` — the `dotnet/` folder is shared across every `dotnet-*` plugin.

Rules:
- Only `plugin.json` goes inside `.claude-plugin/`. `skills/`, `agents/`, `hooks/`, `scripts/` sit at
  the plugin root, or they won't be discovered.
- A plugin-root `CLAUDE.md` is **not** loaded as context. Ship rules/conventions as an
  always-relevant skill instead (see `dotnet-ddd`'s `architecture-rules` skill for the pattern).
- Prefer a *directory* skill (`skills/<name>/SKILL.md`) over a flat command file whenever the skill
  needs to bundle templates or reference docs alongside it.
- Set `name` in `plugin.json` to the full `{stack}-{topic}` plugin name, matching the directory.

## Steps to add a new plugin

1. Create the directory: `plugins/{stack}/{stack}-{topic}/` with the layout above (reuse the
   `plugins/{stack}/` folder if a plugin for that stack already exists).
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
     "source": "./plugins/{stack}/{stack}-{topic}",
     "description": "One sentence, same as plugin.json."
   }
   ```
5. Validate and test locally before pushing:
   ```bash
   claude plugin validate ./plugins/{stack}/{stack}-{topic} --strict
   claude --plugin-dir ./plugins/{stack}/{stack}-{topic}
   ```
6. Commit and push. Consumers already tracking this marketplace pick it up on
   `/plugin marketplace update`; new consumers run:
   ```bash
   /plugin marketplace add adamm931/claude-skills
   /plugin install {stack}-{topic}@claude-skills
   ```
