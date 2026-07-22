---
name: list-queries
description: >
  How list endpoints do pagination, sorting, and filtering safely: schema.json validates the raw
  `?page=&pageSize=&sort=&filter[field]=`, then `parseListQuery` applies the sort/filter WHITELIST and
  the repository builds a parameterized query via `buildListQuery`. Use when adding a list endpoint or
  its filtering/sorting/pagination.
---

# List queries (pagination + sorting + filtering)

Two steps: JSON Schema validates the raw query shape/types; `parseListQuery` applies the business rules
JSON Schema can't express (the sort/filter field whitelist). Both helpers live in
`src/lib/query-params.js`. Sort/filter fields are WHITELISTED — user input never becomes a SQL
identifier, and values always go through `$params`.

## 1. Route: `schema.json` validates raw params

```json
// src/api/customers/get/schema.json
{
  "query": {
    "type": "object",
    "properties": {
      "page": { "type": "integer", "minimum": 1, "default": 1 },
      "pageSize": { "type": "integer", "minimum": 1, "maximum": 100, "default": 20 },
      "sort": { "type": "string" },
      "filter": { "type": "object" }
    },
    "additionalProperties": true
  }
}
```

Ajv coerces `page`/`pageSize` from strings and applies defaults. (`app.js` sets the `extended` query
parser so `?filter[status]=active` parses into `req.query.filter`.)

## 2. Route: `parseListQuery` whitelists + builds the spec

```js
// src/api/customers/get/route.js
import { parseListQuery } from '../../../lib/query-params.js';

export default async (req, res) => {
  const spec = parseListQuery(req.valid.query, {
    sortable: ['id', 'name', 'createdAt'],   // only these may appear in ?sort=
    filterable: ['status', 'name'],          // only these may appear in ?filter[...]
  });
  const { rows, total } = await customersService.list(spec);
  res.page(rows, { page: spec.page, pageSize: spec.pageSize, total });
};
```

`spec` = `{ page, pageSize, sort: [{field,dir}], filters: [{field,value}] }`. A sort/filter field not
on the whitelist throws `400`. `?sort=name,-createdAt` — comma list, `-` prefix = descending.

## 3. Repository: `buildListQuery` (safe SQL)

```js
import { buildListQuery } from '../lib/query-params.js';

const COLUMNS = { id: 'id', name: 'name', createdAt: 'created_at', status: 'status' };

export const findMany = async (spec) => {
  const { sql, params, countSql, countParams } = buildListQuery('customers', COLUMNS, spec);
  const rows = await query(sql, params);
  const [{ total }] = await query(countSql, countParams);
  return { rows, total };
};
```

`COLUMNS` maps each public field to its real column — the only names allowed into `WHERE`/`ORDER BY`.
`res.page(rows, { page, pageSize, total })` returns the list envelope (see the `responses` skill).
