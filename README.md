# claude-skills

Personal Claude Code plugin marketplace: reusable skills and agents, named `{stack}-{topic}`,
installable across any project.

## Getting started in Claude Code

**1. Add this marketplace** — one-time, registers the catalog for every project on this machine:

```bash
/plugin marketplace add adamm931/claude-skills
```

**2. Install whichever plugins you want.** Installing at the default **user scope** makes a plugin
available in every project you open afterward — you don't reinstall per project, and you don't have
to install everything, just what a given machine/workflow needs:

```bash
/plugin install dotnet-ddd@claude-skills
/plugin install node-ddd@claude-skills
/plugin install node-pg-express@claude-skills
/plugin install api-spec@claude-skills
/plugin install data-model@claude-skills
/plugin install postgres-ops@claude-skills
/plugin install kafka-ops@claude-skills
/plugin install react-standards@claude-skills
```

(To share a plugin with a team via a repo instead of installing it just for yourself, use
`--scope project` — see [`docs/create-plugin.md`](docs/create-plugin.md) for the difference.)

**3. Just ask — you don't need to memorize skill names.** Claude reads each skill's `description`
and picks the relevant one automatically:

> "set up Postgres for this project" → triggers `postgres-setup`
> "add a vertical slice for placing an order" → triggers `dotnet-ddd`'s `vertical-slice`
> "write the API spec for the billing iteration" → triggers `api-spec-rest`

You can also invoke a skill explicitly, namespaced as `plugin-name:skill-name` (this avoids name
collisions between plugins):

```bash
/postgres-ops:postgres-setup
/kafka-ops:kafka-topics
```

**4. See what's installed** any time:

```bash
/plugin
```

**5. Pick up updates** after this repo changes:

```bash
/plugin marketplace update claude-skills
```

## Plugins

| Plugin | Skills | Description |
|---|---|---|
| [`dotnet-ddd`](plugins/dotnet-ddd) | dotnet-setup, architecture-rules, init-ddd, new-module, vertical-slice, integration-event, aggregate-design | DDD modular monolith scaffolding and review for .NET (MediatR + MassTransit) |
| [`node-ddd`](plugins/node-ddd) | node-setup, architecture-rules, init-ddd, new-module, vertical-slice, integration-event, aggregate-design | DDD modular monolith scaffolding and review for Node.js/TypeScript (hand-rolled mediator + Prisma + outbox) |
| [`node-pg-express`](plugins/node-pg-express) | architecture-rules, node-setup, init-app, new-resource, request-validation, auth, rate-limiting, idempotency, list-queries, responses, logging | Layered (api → services → data) plain-JS REST API: folder-per-method file-based routing on Express + raw pg, JSON Schema (Ajv) validation via schema.json, global api-key auth + rate-limit, idempotency, pagination/HATEOAS, Winston logging |
| [`api-spec`](plugins/api-spec) | api-spec-rest ✅, api-spec-graphql (planned) | Write API specs as versioned, decision-recording iteration docs |
| [`data-model`](plugins/data-model) | data-model-mssql ✅, data-model-postgres ✅ | Write data-layer specs (schema, indexes, migrations) as versioned iteration docs |
| [`postgres-ops`](plugins/postgres-ops) | postgres-setup, postgres-up, postgres-down, postgres-status, postgres-logs, postgres-reset, postgres-query, postgres-backup | Scaffold a project-local Dockerized Postgres and operate it day-to-day |
| [`kafka-ops`](plugins/kafka-ops) | kafka-setup, kafka-up, kafka-down, kafka-status, kafka-logs, kafka-reset, kafka-topics | Scaffold a project-local Dockerized Kafka (KRaft) and operate it day-to-day |
| [`react-standards`](plugins/react-standards) | app-scaffold, forms, theming, component-design, data-fetching, state-management, error-handling, lazy-routes, lint-format | Opinionated standards for React + TypeScript apps, from project scaffold to lint/format |

`api-spec` and `data-model` were extracted from the spec-writing conventions in
[`adamm931/todoly`](https://github.com/adamm931/todoly)'s `docs/specs/` — one API spec and one
data-layer spec per feature/iteration (`docs/specs/<NN>-<feature>/<feature>.api.md` +
`<feature>.data-layer.md`), generalized so any project can reuse the same methodology.

`postgres-ops` and `kafka-ops` were adapted from [`adamm931/dev-stack`](https://github.com/adamm931/dev-stack)'s
proven Docker Compose patterns (Kafka's dual-listener setup, healthchecks, `.env` conventions) and its
atomic-skill design (one operation per skill) — but scaffold a **project-local** compose file rather
than assuming `dev-stack`'s shared, always-running instance, so they work in any repo on their own.

## Roadmap

Placeholder folders (marked with `.gitkeep`) reserve the name for planned plugins so the tree can
grow without reshuffling. Not yet installable — no `plugin.json` yet.

```
plugins/
├── dotnet-ddd/                         ✅ shipped
├── node-ddd/                           ✅ shipped
├── react-standards/                    ✅ shipped
├── api-spec/                           ✅ shipped
│   └── skills/
│       ├── api-spec-rest/              ✅ shipped
│       └── api-spec-graphql/           # planned — same doc shape, GraphQL SDL notation
└── data-model/                         ✅ shipped
    └── skills/
        ├── data-model-mssql/           ✅ shipped
        └── data-model-postgres/        ✅ shipped
```

See [`docs/create-plugin.md`](docs/create-plugin.md#one-plugin-per-topic-dialects-are-skills) for why
`api-spec` and `data-model` are each one plugin with REST/GraphQL and Postgres/MSSQL as skills inside
them, rather than four separate plugins.

## Adding a new plugin

See [`docs/create-plugin.md`](docs/create-plugin.md) for the naming convention
(`{stack}-{topic}`), required layout, and the steps to register a new plugin in this marketplace.
