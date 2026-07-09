# LifeOS Architecture

## Principles

1. **Everything is an event.** Every user action becomes a `LifeEvent`
   (`expense_added`, `water_logged`, `sleep_logged`, ...). No exceptions.
2. **The UI has no business logic.** Widgets emit events and observe
   repositories/providers. Calculations live in use cases and the core engine.
3. **Depend on abstractions.** The domain depends on repository *interfaces*;
   concrete data sources (in-memory now, Firestore later) are injected.
4. **No quick hacks.** Every concern is an isolated, testable unit.

## Layers

| Layer | Contains | May depend on |
|-------|----------|---------------|
| Presentation | Widgets, Riverpod providers | Application, Domain, Core |
| Application | Use cases (one action each) | Domain, Core |
| Domain | Entities, value objects, repo interfaces | *(pure Dart only)* |
| Data | Repository impls, data sources, DTOs | Domain, Core |
| Core | EventBus, LifeCoreEngine, services | *(nothing feature-specific)* |

`core` must **never** import a `feature`. Concrete events live inside the feature
that owns them (MoneyOS owns `ExpenseAddedEvent`); `core` only defines the
abstract `LifeEvent`, `EventBus`, `EventHandler` and `LifeCoreEngine`.

## Event flow

```
Widget → UseCase.call()
              │ 1. validate
              │ 2. repository.write()   (persist)
              │ 3. eventBus.publish(event)
              ▼
        LifeCoreEngine (single subscriber)
              │ fan-out to handlers that canHandle(event)
              ├─ EventLogHandler      → append to events/ log
              ├─ (Phase 6) NotificationHandler → budget / health alerts
              └─ (Phase 9) AiHandler          → analysis & forecasts
```

A failing handler is isolated by the engine and can never break the pipeline or
sibling handlers.

## State & reactivity

- Repositories expose `Stream`s (`watchAll`).
- `transactionsProvider` (StreamProvider) exposes the live list.
- `currentBudgetProvider` derives the `Budget` from that stream via
  `ComputeBudget`.
- `lifeScoreProvider` / `todaySnapshotProvider` derive from the budget.

When a transaction is added, the write path publishes an event *and* the data
source emits a new snapshot, so every derived provider — balance, budget, Life
Score, Today — updates automatically.

## Adding a new module (recipe)

Example: HealthOS `water_logged`.

1. **Domain** — `features/health/domain/entities/water_entry.dart`,
   `repositories/health_repository.dart`, and
   `domain/events/health_events.dart` (`WaterLoggedEvent extends LifeEvent`).
2. **Application** — `application/log_water.dart`: validate → persist →
   `eventBus.publish(WaterLoggedEvent(...))`.
3. **Data** — a data source + `HealthRepositoryImpl`.
4. **Presentation** — providers + widgets. No business logic in widgets.
5. **Core wiring** — register any new `EventHandler` in `coreEngineProvider`.

Nothing in MoneyOS or the UI shell needs to change.

## Testing strategy

- **Pure use cases** (`ComputeBudget`) and value objects (`Money`) are unit
  tested with no I/O and an injectable `Clock`.
- **Repositories** get fake/in-memory data sources.
- **Widgets** get `ProviderScope` overrides for their providers.
