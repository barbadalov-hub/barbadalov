# CLAUDE.md — project guide for Claude Code

LifeOS is an event-based "operating system for your life" built in **Flutter**
(finance, health, food, habits, goals, mood, an AI coach, insights, achievements,
a Wrapped year-recap, and more). This file is the durable project context — read
it before making changes.

## Commands (run from the project root)

```bash
flutter pub get
flutter analyze          # MUST be clean ("No issues found") before you're done
flutter test             # MUST stay green (currently ~194 tests)
flutter build web --release       # Linux/cloud + desktop OK
flutter build apk --release       # Android (needs Android SDK)
# flutter build windows --release # only on a Windows host with VS C++ toolchain
```

**Definition of done for any change:** `flutter analyze` is clean **and**
`flutter test` passes. Add/adjust tests for the code you touch.

## Non-negotiable constraints

- **Plugin-free is a hard rule.** The app must build for Windows desktop without
  Developer Mode, so avoid Flutter plugins with native Windows code. Platform
  capabilities (notifications, OCR, file save, URL open, storage) go behind a
  **conditional-export seam**: a `foo.dart` that does
  `export 'foo_web.dart' if (dart.library.io) 'foo_io.dart';` with a no-op
  fallback. See `core/services/*_gateway.dart`, `core/utils/{open_url,download_file,share_image}.dart`.
  Packages that ship for phones only (flutter_local_notifications, ML Kit,
  image_picker_android/ios) are fine **as long as they have no Windows impl**.
- **Money is integer minor units** (`shared/models/money.dart`), never `double`.
- **Everything flows through the event core.** UI has no business logic: it emits
  a `LifeEvent` → `EventBus` → `LifeCoreEngine` → handlers (log / notifications /
  AI). Use cases live in `application/`, entities (pure Dart) in `domain/`.
- `analysis_options.yaml` promotes `dead_code` / `unawaited_futures` to errors.

## Architecture

Clean Architecture per feature: `domain/` (pure entities) · `application/`
(use cases) · `data/` (repositories) · `presentation/` (pages + Riverpod
providers). Riverpod is used **without codegen**. Composition root is
`shared/providers/core_providers.dart`.

## Persistence (plugin-free)

`KeyValueStore` seam: `InMemoryKeyValueStore` for tests; a JSON file in
`%APPDATA%`/app-docs on desktop (`dart:io`) and `localStorage` on web
(`package:web`), selected by conditional export. `JsonCollectionStore` wraps it
for lists/objects. Persisted controllers are `Notifier`s that read
`keyValueStoreProvider` / `jsonStoreProvider`.
**Gotcha:** `loadList` returns a `const []` fallback when empty — copy before
sorting (`[...loadList()]..sort()`), a plain `.sort()` throws "unmodifiable list".

## Localization (custom, plugin-free)

One table in `lib/core/i18n/app_localizations.dart`, keyed by a dotted id with
`en`/`ru`/`uk` variants. Use `context.tr('key')` / `context.trp('key', {params})`.
**Every new UI string needs a key with all three languages** — `test/i18n_integrity_test.dart`
fails the build if any language is missing or placeholder tokens (`{n}`) differ
across languages. Keep each language pure (no mixing).

## Testing conventions

- Pure logic (engines, calculators, aggregators) → fast unit tests.
- `test/app_smoke_test.dart` boots the whole app; it overrides
  `keyValueStoreProvider` (seed `onboarding.done:'true'`) and
  `splashDurationProvider` (`Duration.zero`) to reach the Today screen.
- Widget tests live in `test/smart_pages_test.dart` (`_wrap(page, {overrides})`
  helper, English locale). Animated backdrops run forever → use fixed
  `pump(Duration(...))`, never `pumpAndSettle`.
- Staggered `FadeSlideIn` entrance timers: the smoke test drains them with a
  final `pump(Duration(seconds: 1))`; delay is clamped at index 10 (~600ms).

## Platform / environment notes

- **Cloud (Linux) or macOS:** analyze, test, `build web`, `build apk` all work.
  Windows `.exe` can only be built on a Windows host, so skip it there.
- **Windows host gotcha (does NOT apply on Linux):** the analyzer LSP crashes on
  non-ASCII project paths, so on the original Windows machine the tooling is run
  from an ASCII junction `C:\src\lifeos`. Irrelevant in the cloud.

## Handy pointers

- Today screen is a **data-driven, user-customizable** list of sections
  (`home/presentation/providers/today_layout_provider.dart` — `kTodaySections`
  is the single source of truth for order + labels; the customize sheet reorders
  and shows/hides them). Add a section = add to `kTodaySections`, a
  `_sectionWidget` case, and a `tsec.*` i18n key.
- Signature/media features: **Wrapped** (`features/wrapped`), **Insights**
  (`features/insights`, cross-pillar mood correlations), **Achievements**
  (`features/achievements`), **AI Coach** (`features/coach`, rule-based chat).
  Three shareable cards use `shared/widgets/share_card.dart` (`ShareCard` +
  `shareBoundaryPng`).
- Firebase config in code is **public-by-design** (web apiKey etc.); safe to
  commit. Real secrets/keystores are git-ignored.
