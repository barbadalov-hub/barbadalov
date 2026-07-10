# LifeOS 🌌

**The operating system for your life.** Finance, health, food, habits, goals,
mood and an AI life coach — unified by a single event-based core.

> "You are not using an app — you are using a system that manages your life."

A cross-platform Flutter app that runs **fully offline, plugin-free** (builds for
Windows desktop, Web and Android from the same code, no Developer Mode needed).

---

## ✨ Highlights

**Core pillars**
- **MoneyOS** — income/expenses, categories, live balance, automatic 10–20%
  reserve, budgets, spending analytics, receipt parser, CSV import/export,
  recurring transactions, category limits.
- **HealthOS** — water/steps/sleep/weight/stress/vitals with goal rings, weekly
  charts, body measurements, workouts (live wger catalog) + a training guide.
- **FoodOS + Dietitian** — pantry & expiry, shopping list, meal planner, a
  calorie/macro dietitian with a manual food log and live UA store prices.
- **MindOS** — habits (streaks + heatmap), tasks, a Pomodoro timer, books, and a
  mood journal.
- **GoalsOS** — long-term goals with milestones and a savings-based forecast.
- **Wellness** — a Flo-style cycle tracker (women) / vitality tracker (men).

**Intelligence & delight**
- **Today** — a customizable home screen (show/hide + drag-reorder every card),
  the four-pillar **Life Score**, a proactive **AI coach tip**, quick actions,
  habit/task check-off, and teasers.
- **AI Coach** — a rule-based chat that answers from your real data (finances,
  sleep, steps, water, habits, goals, mood, patterns).
- **Insights** — honest cross-pillar correlations (mood vs sleep/steps/water/
  spending/stress), mood patterns (happiest weekday, trend, activity impact).
- **Achievements** — a 16-badge trophy wall with unlock notifications.
- **LifeOS Wrapped** — a shareable, Spotify-Wrapped-style year recap (any year),
  plus shareable Insights and weekly-report cards.
- **Long-term history** — a monthly archive so you can look back a year (or five).
- Reminders (real phone notifications), a notification center, a command palette
  (global fuzzy search + quick actions), theme personalization (6 cosmos accents
  + light/dark), i18n in **EN / RU / UK**, offline backup & restore, PIN app-lock,
  cosmos branding (launcher icon, onboarding, splash, glassmorphism).

---

## 🚀 Getting started

```bash
flutter pub get
flutter analyze     # → No issues found
flutter test        # → ~194 tests passing
flutter run -d chrome        # or -d windows / an Android device
```

**Build:**

```bash
flutter build web --release      # build/web
flutter build apk --release      # Android
flutter build windows --release  # Windows host only (needs VS C++ toolchain)
```

Status: `flutter analyze` clean · **~194 tests passing** · Web, Android APK and
Windows desktop all build.

> **Windows note:** the Dart analyzer LSP crashes on non-ASCII project paths, so
> on a machine whose path contains non-ASCII characters, run tooling from an
> ASCII junction/copy (e.g. `C:\src\lifeos`). Not an issue on macOS/Linux.

See [`CLAUDE.md`](CLAUDE.md) for conventions and constraints before contributing.

---

## 🏗️ Architecture

Strict Clean Architecture — **the UI never contains business logic**; it emits
events and observes repositories.

```
Presentation (Flutter widgets · Riverpod providers, no codegen)
      │  emits events / watches state
Application (UseCases: AddTransaction, ComputeBudget, …)
      │
Domain (pure Dart entities: Transaction, Budget, Money — no Flutter)
      │
Data (repository impls; local-first, Firebase-ready behind interfaces)
      │
Core (EventBus · LifeCoreEngine · services · Life Score)
```

Every action becomes a `LifeEvent` → `EventBus` → `LifeCoreEngine` → handlers
(event log, notifications, AI). See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

### Key design choices

- **Plugin-free.** Platform features (notifications, OCR, file save, URL open,
  storage, image share) sit behind conditional-export seams with no-op fallbacks,
  so the Windows build stays plugin-free.
- **Local-first.** Persistence is a `KeyValueStore` seam (JSON file on desktop,
  `localStorage` on web) behind repository interfaces; a REST Firebase sync layer
  exists for optional cloud backup (see `docs/FIREBASE.md`).
- **Money as integer minor units** — exact arithmetic, never `double`.
- **Custom i18n** (EN/RU/UK) — one string table, completeness enforced by a test.

```
lib/
  core/        constants · events (LifeEvent/EventBus) · engine · services · i18n · utils
  features/    money · health · food · mind · goals · wellness · home(Today) · ai ·
               coach · insights · achievements · wrapped · history · reminders ·
               notifications · reports · backup · security · appearance · search ·
               onboarding · profile · lifeweeks   (each: domain/application/data/presentation)
  shared/      models(money) · providers(core_providers) · theme · widgets
  app.dart · main.dart
```

---

## 🔌 Optional integrations (need your own accounts)

- **Firebase** cloud sync — plugin-free REST layer is built; provide a project
  (`docs/FIREBASE.md`).
- **Real device health data** — port + mock in place; add the `health` package on
  a phone (`docs/DEVICES.md`).
- **Live UA grocery prices** — deployable Cloudflare Worker in `backend/`
  (`backend/README.md`); the app degrades to an offline catalog without it.

---

## 🧪 Quality bar

- `flutter analyze` clean and `flutter test` green are the definition of done.
- `analysis_options.yaml` promotes `dead_code` / `unawaited_futures` to errors.
- Pure use cases and engines are unit-tested without any I/O; there's a full-app
  boot smoke test and widget tests for the key screens.
