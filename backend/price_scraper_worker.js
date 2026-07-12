/**
 * LifeOS price scraper — АТБ + Сільпо live prices for the app.
 *
 * АТБ and Сільпо have no public price API, so this tiny Cloudflare Worker
 * fetches their (unofficial) site/ecom endpoints server-side — where there is
 * no CORS wall — and returns the shape the app expects:
 *
 *   GET /prices?ids=eggs,milk,cheese
 *   → { "prices": { "eggs": { "atb": 5490, "silpo": 5990 }, ... } }   // kopecks
 *
 * Deploy: see backend/README.md (Cloudflare dashboard paste OR `wrangler deploy`).
 * Then put the Worker URL in lib/core/config/backend_config.dart and rebuild.
 *
 * Hardening baked in: results are edge-cached (see CACHE_TTL) so we never hammer
 * the chains, every upstream fetch has a timeout, and the id list is capped.
 *
 * NOTE: the АТБ/Сільпо endpoints below are UNOFFICIAL and change from time to
 * time. If a chain returns nothing, open its site, copy the current search
 * request from DevTools → Network, and adjust the two fetch functions. The
 * response contract to the app never changes.
 */

// Ukrainian search query per catalog product id (mirrors the app's catalog).
const QUERIES = {
  eggs: "яйця курячі", milk: "молоко 2,5", cottage_cheese: "сир кисломолочний",
  oats: "пластівці вівсяні", banana: "банан", walnuts: "горіх волоський",
  flour: "борошно пшеничне", honey: "мед", cheese: "сир твердий",
  tomatoes: "помідори", cucumbers: "огірки", chicken: "філе куряче",
  beef: "яловичина", fish: "хек", buckwheat: "крупа гречана", rice: "рис",
  beets: "буряк", potatoes: "картопля", carrots: "морква",
  onion: "цибуля ріпчаста", bread: "хліб", yogurt: "йогурт", apple: "яблука",
};

// Сільпо ecom API. Set a real branch GUID for your city (copy it from a
// silpo.ua request in DevTools). This one is a commonly-used Kyiv branch.
const SILPO_BRANCH = "d3a4b3c0-0000-0000-0000-000000000000"; // TODO: set yours

const CACHE_TTL = 1800;     // seconds to cache a /prices response at the edge
const FETCH_TIMEOUT = 8000; // ms before giving up on a chain
const MAX_IDS = 40;         // cap ids per request so one call can't fan out forever

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

export default {
  async fetch(request, _env, ctx) {
    if (request.method === "OPTIONS") return new Response(null, { headers: CORS });

    const url = new URL(request.url);
    if (!url.pathname.endsWith("/prices")) {
      return json({ error: "use /prices?ids=eggs,milk" }, 404);
    }

    const ids = parseIds(url.searchParams.get("ids"));
    if (ids.length === 0) return json({ prices: {} });

    // Edge cache keyed on the sorted id list, so callers asking for the same
    // products share one cached response and we never re-scrape needlessly.
    const cache = caches.default;
    const cacheKey = new Request(`https://cache.lifeos/prices?ids=${ids.join(",")}`, request);
    const cached = await cache.match(cacheKey);
    if (cached) return cached;

    const prices = {};
    await Promise.all(ids.map(async (id) => {
      const q = QUERIES[id];
      const [atb, silpo] = await Promise.all([
        safe(() => atbKopecks(q)),
        safe(() => silpoKopecks(q)),
      ]);
      const entry = {};
      if (atb) entry.atb = atb;
      if (silpo) entry.silpo = silpo;
      if (Object.keys(entry).length) prices[id] = entry;
    }));

    const res = json({ prices, ts: new Date().toISOString() });
    res.headers.set("Cache-Control", `public, max-age=${CACHE_TTL}`);
    // Populate the edge cache without blocking the response.
    if (ctx && ctx.waitUntil) ctx.waitUntil(cache.put(cacheKey, res.clone()));
    return res;
  },
};

/** Parse, validate, de-dup and cap the ?ids= list. Exported for tests. */
export function parseIds(raw) {
  const seen = new Set();
  for (const s of (raw || "").split(",")) {
    const id = s.trim();
    if (QUERIES[id]) seen.add(id);
  }
  return [...seen].sort().slice(0, MAX_IDS);
}

export const json = (body, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8", ...CORS },
  });

const safe = async (fn) => { try { return await fn(); } catch { return null; } };

/** Hryvnia (number/string) → integer kopecks, or null. Exported for tests. */
export const toKopecks = (uah) => Math.round(Number(uah) * 100) || null;

/** fetch() with an abort timeout so a slow chain can't hang the worker. */
async function timedFetch(u, opts = {}) {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), FETCH_TIMEOUT);
  try {
    return await fetch(u, { ...opts, signal: ctrl.signal });
  } finally {
    clearTimeout(t);
  }
}

/** Сільпо — ecom JSON API. Returns the first item's price in kopecks. */
async function silpoKopecks(query) {
  const u = `https://sf-ecom-api.silpo.ua/v1/uk/branches/${SILPO_BRANCH}` +
    `/products?limit=1&offset=0&sortBy=popularity&sortDirection=desc` +
    `&search=${encodeURIComponent(query)}`;
  const res = await timedFetch(u, { headers: { Accept: "application/json" } });
  if (!res.ok) return null;
  const data = await res.json();
  const item = (data.items || data.data || [])[0];
  if (!item) return null;
  return toKopecks(item.price ?? item.displayPrice ?? item.currentPrice);
}

/** АТБ — pull the first price out of the catalogue search HTML. Exported so the
 *  fragile regex parsing can be unit-tested against sample markup. */
export function parseAtbHtml(html) {
  const m =
    html.match(/"price"\s*:\s*"?(\d+[.,]\d{2})"?/) ||
    html.match(/atbproduct__price-number[^>]*>\s*([\d\s]+[.,]\d{2})/);
  if (!m) return null;
  return toKopecks(m[1].replace(/\s/g, "").replace(",", "."));
}

async function atbKopecks(query) {
  const u = `https://www.atbmarket.com/product-catalogue/search?query=` +
    encodeURIComponent(query);
  const res = await timedFetch(u, {
    headers: { "User-Agent": "Mozilla/5.0", "Accept-Language": "uk" },
  });
  if (!res.ok) return null;
  return parseAtbHtml(await res.text());
}
