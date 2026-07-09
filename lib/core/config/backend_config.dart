/// Configuration for the optional self-hosted **price scraper** backend.
///
/// АТБ and Сільпо publish no public price API, so live prices for those two
/// chains come from a tiny scraper you deploy yourself (a Cloudflare Worker or
/// any host — see `backend/price_scraper_worker.js` and docs/STORES.md). Paste
/// its URL here and rebuild; while it's empty АТБ/Сільпо stay on the curated
/// offline catalog and everything else is unchanged.
class BackendConfig {
  const BackendConfig._();

  /// e.g. 'https://lifeos-prices.<your-subdomain>.workers.dev'
  static const String pricesBackendUrl = '';

  static bool get pricesEnabled => pricesBackendUrl.isNotEmpty;
}
