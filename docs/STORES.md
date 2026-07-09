# Ukrainian store prices — how it works and how to make it live

The dietitian prices every dish's shopping basket across **АТБ, Сільпо and
Novus** through one port:

```
lib/features/food/domain/repositories/store_price_source.dart   ← the port
lib/features/food/data/ua_store_price_catalog.dart              ← launch impl
```

`UaStorePriceCatalog` is a curated catalog of realistic UAH shelf prices per
standard pack (eggs — 10 шт, milk — 1 л, ...). The UI labels totals as
approximate. Swapping in live prices touches **one provider**
(`storePriceSourceProvider` in `diet_providers.dart`) — nothing else.

## Why not live prices from day one

Research (see DOU write-ups and freelance briefs) shows АТБ/Сільпо have **no
public price API**; existing projects reverse-engineer the sites:

- **Сільпо** — internal GraphQL/REST endpoints used by silpo.ua; store id is
  passed per request.
- **АТБ** — store binding via cookies; catalog pages are scrapeable
  (HTML/JSON), needs an anti-bot-friendly backend scraper.
- **zakaz.ua** — aggregates several chains (Novus, Metro, Auchan) and has
  a comparatively stable JSON API used by delivery apps.

Scraping from the *client* is the wrong place (CORS on web, IP bans, ToS), so
the intended production shape is:

```
[cron scraper / zakaz.ua adapter]  →  Firestore `prices/{productId}`  →
FirestorePriceSource implements StorePriceSource  →  same UI
```

## Adding a live adapter later

1. Implement `StorePriceSource.quotesFor(productId)` against your backend.
2. Map catalog `productId`s (`eggs`, `milk`, ...) to store SKUs once.
3. Override `storePriceSourceProvider` with the new source.

Product ids and pack sizes are already normalized in `ua_store_price_catalog.dart`.
