---
name: mock-data-layer
description: >
  Stand up a spec-driven mock API (MSW) plus an adapter layer that simplifies raw wire responses
  into clean UI types, so the frontend can be built before the backend endpoints exist. Use when
  the backend/API isn't ready yet, when the user has an API spec (a `*.api.md` / OpenAPI doc) and
  wants to develop the React UI against it, or asks to mock/stub/fake API calls, add MSW, or seed
  fake data.
---

# Mock data layer (MSW + adapter)

The phase this is for: the API is specified but the backend team is still building the endpoints.
The UI shouldn't wait. Build against a mock that implements the spec, then flip endpoints over to
the real backend one at a time as they land — with **zero changes to hooks or components**.

Two distinct layers, and this skill sets up both:

1. **Adapter layer** (`features/*/api/`) — turns raw wire DTOs (snake_case, envelopes, prefixed
   ids) into clean domain types the UI consumes. This is "simplify the API response." It runs for
   **both** the mock and the real backend, so switching between them is invisible above `api/`.
2. **Mock layer** (`src/mocks/`) — [MSW](https://mswjs.io) intercepts requests at the network
   boundary and answers them from an in-memory store seeded from the spec. Because interception is
   at the network level, the real fetchers, mappers, query keys, and error handling all run for
   real — nothing app-side knows it's talking to a mock.

## Why MSW, not swapped fetcher modules

Do **not** build `tasksApi.real.ts` / `tasksApi.mock.ts` and branch on an env flag. That leaves the
mock code path untested against reality and litters app code with `if (useMocks)`. MSW intercepts
`fetch` instead, so:

- The `api/` fetchers are written once, against the real endpoints, and never change.
- `onUnhandledRequest: "bypass"` lets **un-mocked endpoints fall through to the real backend** —
  exactly the "three endpoints done, the rest still in progress" reality. Delete a handler and that
  route is instantly live against the real API.
- The same handlers run in Vitest (`msw/node`), so tests get the API for free with no running server.

## Setup

1. Install and generate the service worker:

   ```bash
   npm install -D msw
   npx msw init public/ --save    # writes public/mockServiceWorker.js
   ```

2. Copy the boilerplate templates into `src/mocks/` (they're spec-independent):
   - `templates/mock-config.ts.template`  → `src/mocks/config.ts`
   - `templates/mock-browser.ts.template` → `src/mocks/browser.ts`
   - `templates/mock-server.ts.template`  → `src/mocks/server.ts`
   - `templates/collection.ts.template`   → `src/mocks/db/collection.ts`

3. Layout under `src/mocks/`:

   ```
   src/mocks/
   ├── config.ts              # env-driven latency / error-rate / on-off
   ├── browser.ts             # setupWorker — started from main.tsx
   ├── server.ts              # setupServer — imported by test setup
   ├── db/
   │   ├── collection.ts      # generic in-memory store (template)
   │   ├── seed/              # STARTING DATA as JSON — one file per resource, lifted from the spec
   │   │   ├── projects.json
   │   │   ├── tasks.json
   │   │   └── tags.json
   │   ├── seed.ts            # loads the JSON above into fresh (cloned) rows
   │   └── index.ts           # one Collection per resource + resetDb()
   └── handlers/              # BEHAVIOUR — every endpoint is a coded handler backed by db
       ├── index.ts           # export const handlers = [...projects, ...tasks, ...tags]
       ├── projects.ts
       ├── tasks.ts
       └── tags.ts
   ```

   The split to keep in your head: **JSON files are only the starting data**; **all endpoints are
   coded handlers** that read/write the in-memory `db`. That's what gives real POST→GET→PATCH→DELETE
   behaviour (a created task shows up in the next list) while the seed rows stay declarative and easy
   to edit without touching code.

4. Start the worker lazily in `src/main.tsx` so MSW and seed data never ship in a mocks-off build:

   ```ts
   async function enableMocking() {
     const { mockConfig } = await import("./mocks/config");
     if (!mockConfig.enabled) return;
     const { worker } = await import("./mocks/browser");
     await worker.start({ onUnhandledRequest: "bypass" });
   }

   enableMocking().then(() => {
     ReactDOM.createRoot(document.getElementById("root")!).render(<App />);
   });
   ```

5. Add env flags (`.env.development` / `.env.local`), e.g. `VITE_ENABLE_MOCKS=true`,
   `VITE_MOCK_LATENCY_MS=300`, `VITE_MOCK_ERROR_RATE=0`.

## Driving it from an API spec

Given a spec (a `*.api.md`, OpenAPI, or similar), extract in this order:

- **Resources + representations** (the spec's "Representations" / schema section) → the wire **DTO**
  types (exact field names and casing) and the **domain** types the UI wants. Seed rows are lifted
  straight from the example JSON.
- **Endpoints table** (method + path + body) → one MSW handler each.
- **List envelope + pagination** (`{ data, next_cursor }`, `?cursor=&limit=`) → `collection.paginate`.
- **Design-decision / rules section** → the behaviour handlers must reproduce: status transition
  tables, cascade deletes, idempotent attach/detach, nested-route parent inference, filter semantics.
- **Errors table** → the status codes and error bodies handlers return for the not-found / invalid
  / conflict cases.

Reproduce the rules that the UI can observe (validation errors, transition rejections, cascades,
pagination). Skip server-only concerns the UI can't see (storage, auth internals not yet in the spec).

## Rules

- **DTOs mirror the wire exactly; domain types are what the UI uses.** Keep `dto.ts` (snake_case,
  envelopes, `prj_`/`tsk_` ids — copied verbatim from the spec) separate from the feature's domain
  `types.ts` (camelCase, envelope unwrapped). Never let a raw DTO shape leak past `api/`.
- **Mappers are the only place the two shapes meet**, and they run for real and mock alike. A
  component or hook that renders `task.dueDate` must never see `due_date`.
- **The mock store holds wire-shaped rows**, so handlers return them unchanged and the app's mappers
  do the simplifying — the mock exercises the exact same mapping code the real backend will.
- **Every endpoint is a coded handler backed by `db`** — not a static JSON response. That's what
  makes writes stick: a POST inserts into `db`, and the next GET reads the same store. Handlers
  implement observable spec behaviour — pagination, the status transition table, cascade deletes,
  idempotent tag attach/detach, and the spec's error responses.
- **JSON files are seed data only, never wired to routes directly.** Starting rows live in
  `db/seed/*.json` (one file per resource, copied from the spec's example representations) so data
  is editable without touching code; `seed.ts` clones them into the collections. A handler never
  returns a JSON file — it returns whatever is currently in `db`.
- **Un-mocked endpoints must bypass, not 404.** `onUnhandledRequest: "bypass"` in the browser (so
  live endpoints reach the real backend); `"error"` in tests (so an unmocked call is a loud bug).
- **Retiring a mock = deleting its handler.** When the real endpoint ships, remove that one handler;
  everything above `api/` is untouched because it only ever spoke to the mapper/domain layer.
- **Seed data lives in `db/seed.ts` and is re-applied by `resetDb()`** between tests, so each test
  starts from a known state.

## Worked example (todoly spec)

`features/tasks/api/dto.ts` — verbatim from the spec's Task representation and list envelope:

```ts
export interface TaskDto {
  id: string;
  project_id: string;
  parent_id: string | null;
  title: string;
  description: string | null;
  due_date: string | null;
  status: "todo" | "in_progress" | "blocked" | "done";
  completed_at: string | null;
  tags: { id: string; name: string; color: string | null }[];
  created_at: string;
  updated_at: string;
}

export interface ListDto<T> {
  data: T[];
  next_cursor: string | null;
}
```

`features/tasks/types.ts` — the simplified shape the UI actually renders:

```ts
export type TaskStatus = "todo" | "in_progress" | "blocked" | "done";

export interface Task {
  id: string;
  projectId: string;
  parentId: string | null;
  title: string;
  description: string | null;
  dueDate: string | null;
  status: TaskStatus;
  completedAt: string | null;
  tags: Tag[];
}

export interface Page<T> {
  items: T[];
  nextCursor: string | null;
}
```

`features/tasks/api/mappers.ts` — the adapter; the only crossing point:

```ts
import type { TaskDto, ListDto } from "./dto";
import type { Task, Page } from "../types";

export const toTask = (dto: TaskDto): Task => ({
  id: dto.id,
  projectId: dto.project_id,
  parentId: dto.parent_id,
  title: dto.title,
  description: dto.description,
  dueDate: dto.due_date,
  status: dto.status,
  completedAt: dto.completed_at,
  tags: dto.tags.map((t) => ({ id: t.id, name: t.name, color: t.color })),
});

export const toPage = <D, T>(dto: ListDto<D>, map: (d: D) => T): Page<T> => ({
  items: dto.data.map(map),
  nextCursor: dto.next_cursor,
});
```

`features/tasks/api/tasksApi.ts` — the real fetcher (unchanged whether mock or backend answers):

```ts
import { apiClient } from "@/lib/apiClient";       // thin fetch wrapper, base URL from env
import type { TaskDto, ListDto } from "./dto";
import { toTask, toPage } from "./mappers";

export const listTasks = async (params: { projectId?: string; cursor?: string; limit?: number }) => {
  const dto = await apiClient.get<ListDto<TaskDto>>("/v1/tasks", { params });
  return toPage(dto, toTask);                       // hooks receive clean domain types
};

export const patchTask = async (id: string, body: Partial<Pick<TaskDto, "title" | "status">>) => {
  const dto = await apiClient.patch<TaskDto>(`/v1/tasks/${id}`, body);
  return toTask(dto);
};
```

Hooks then wrap these per the `data-fetching` skill — they never see a DTO.

`src/mocks/handlers/tasks.ts` — MSW handlers implementing the spec's observable rules:

```ts
import { http, HttpResponse, delay } from "msw";
import { db } from "../db";
import { mockConfig } from "../config";

// From spec 5.6 — the status transition table.
const ALLOWED: Record<string, string[]> = {
  todo: ["in_progress", "blocked"],
  in_progress: ["todo", "blocked", "done"],
  blocked: ["todo", "in_progress"],
  done: ["todo"],
};

export const taskHandlers = [
  http.get("/v1/tasks", async ({ request }) => {
    await delay(mockConfig.latencyMs);
    const url = new URL(request.url);
    const projectId = url.searchParams.get("project_id");
    const rows = db.tasks
      .where((t) => t.parent_id === null && (!projectId || t.project_id === projectId));
    const page = db.tasks.paginate(rows, {
      limit: Number(url.searchParams.get("limit") ?? 20),
      cursor: url.searchParams.get("cursor"),
    });
    return HttpResponse.json(page);
  }),

  http.patch("/v1/tasks/:id", async ({ params, request }) => {
    await delay(mockConfig.latencyMs);
    const task = db.tasks.get(params.id as string);
    if (!task) {
      return HttpResponse.json(
        { error: { code: "task_not_found", message: `No task with id ${params.id}` } },
        { status: 404 },
      );
    }
    const body = (await request.json()) as { status?: string };
    if (body.status && !ALLOWED[task.status]?.includes(body.status)) {
      return HttpResponse.json(
        { error: { code: "invalid_transition", message: `${task.status} → ${body.status} not allowed` } },
        { status: 422 },
      );
    }
    const completed_at =
      body.status === "done" ? new Date().toISOString() : body.status ? null : task.completed_at;
    return HttpResponse.json(db.tasks.update(task.id, { ...body, completed_at }));
  }),
];
```

A write handler inserts into the store, so the next list GET returns it — `src/mocks/handlers/tasks.ts`:

```ts
http.post("/v1/tasks", async ({ request }) => {
  await delay(mockConfig.latencyMs);
  const body = (await request.json()) as { project_id: string; title: string };
  const now = new Date().toISOString();
  const task = db.tasks.insert({
    id: `tsk_${crypto.randomUUID().slice(0, 8)}`,
    parent_id: null,
    status: "todo",
    description: null,
    due_date: null,
    completed_at: null,
    tags: [],
    created_at: now,
    updated_at: now,
    ...body,                                       // project_id + title from the request
  });
  return HttpResponse.json(task, { status: 201 }); // wire-shaped; the app's mapper simplifies it
}),
```

**Seed data as JSON** — `src/mocks/db/seed/tasks.json`, copied straight from the spec's example
representations (wire-shaped: snake_case, `tsk_` ids):

```json
[
  {
    "id": "tsk_5d0e7f11",
    "project_id": "prj_a13e9b02",
    "parent_id": null,
    "title": "Choose countertop material",
    "description": null,
    "due_date": "2026-08-01",
    "status": "in_progress",
    "completed_at": null,
    "tags": [{ "id": "tag_3f9c2b10", "name": "urgent", "color": "#e5484d" }],
    "created_at": "2026-07-21T14:40:00Z",
    "updated_at": "2026-07-21T14:40:00Z"
  }
]
```

`src/mocks/db/seed.ts` — loads the JSON, returning fresh clones each call so tests can't mutate the
shared array:

```ts
import type { TaskDto } from "@/features/tasks/api/dto";
import tasks from "./seed/tasks.json";
// import projects from "./seed/projects.json";
// import tags from "./seed/tags.json";

export const seedTasks = (): TaskDto[] => structuredClone(tasks) as TaskDto[];
```

(JSON imports need `"resolveJsonModule": true` in `tsconfig.json` — Vite's `react-ts` template
already sets it.)

`src/mocks/db/index.ts` — one collection per resource, seeded, resettable:

```ts
import { Collection } from "./collection";
import type { TaskDto } from "@/features/tasks/api/dto";
import { seedTasks /* , seedProjects, seedTags */ } from "./seed";

export const db = {
  tasks: new Collection<TaskDto>(),
  // projects: new Collection<ProjectDto>(),
  // tags: new Collection<TagDto>(),
};

export function resetDb() {
  db.tasks.seed(seedTasks());                      // re-applied between tests for a clean start
}

resetDb();
```

As real endpoints ship, delete the matching handler from `handlers/*.ts` — the fetcher, mapper,
hook, and components already speak the domain shape and don't change. Edit a `seed/*.json` file to
change the starting data; no code touched.
