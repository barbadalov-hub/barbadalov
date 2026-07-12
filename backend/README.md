# LifeOS price scraper (АТБ + Сільпо)

Novus / METRO / Auchan are already live in the app via the public zakaz.ua API.
АТБ and Сільпо have **no public API**, so this tiny backend fetches their
(unofficial) endpoints server-side and returns live prices to the app.

Contract:

```
GET /prices?ids=eggs,milk,cheese
→ { "prices": { "eggs": { "atb": 5490, "silpo": 5990 } } }   // prices in kopecks
```

Built-in hardening: `/prices` responses are **edge-cached** for 30 min (so we
never hammer the chains), every upstream fetch has an **8 s timeout**, and the
`ids` list is de-duped and capped. The pure parsers are unit-tested:

```bash
cd backend && node --test        # or: npm test
```

## Deploy (Cloudflare Workers — free, no server)

**Option A — dashboard (no tools):**
1. https://dash.cloudflare.com → *Workers & Pages* → *Create* → *Worker*.
2. Replace the code with `price_scraper_worker.js`, click *Deploy*.
3. Copy the URL, e.g. `https://lifeos-prices.<you>.workers.dev`.

**Option B — CLI:**
```bash
npm i -g wrangler
wrangler deploy backend/price_scraper_worker.js --name lifeos-prices
```

## Wire it into the app
1. Put the URL in `lib/core/config/backend_config.dart`:
   ```dart
   static const String pricesBackendUrl = 'https://lifeos-prices.<you>.workers.dev';
   ```
2. Rebuild. On the Diet page, *Refresh prices* now also pulls АТБ/Сільпо.

## Tuning the endpoints (important)
The АТБ/Сільпо endpoints in the worker are **unofficial** and change over time:

- **Сільпо:** set `SILPO_BRANCH` to a real branch GUID for your city — copy it
  from any request to `sf-ecom-api.silpo.ua` in the browser DevTools → Network.
- **АТБ:** parses the search page HTML; if the markup changes, update the two
  regexes in `atbKopecks()`.

If a chain returns nothing, the app silently keeps its curated offline price —
nothing breaks. The response contract to the app never changes, so you only ever
edit the two fetch functions.

Any host works (Render, Fly, Deno Deploy, a VPS) — it's a standard
`fetch(request)` handler; adapt the export wrapper if not using Workers.
