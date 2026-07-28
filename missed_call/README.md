# Пропущенный вызов

An anime **visual novel** built in Flutter. A first-person mystery that lives
entirely inside a phone: an insomniac wakes at **03:14** to a call and, through
his own device, pieces together what happened to his brother that night — while
a night-long **timer** counts down and each failure loops him back.

> This is a standalone game prototype **staged inside the LifeOS repo** (like
> `native/`). It has its own `pubspec.yaml` and is **excluded from the LifeOS
> app's analysis and tests** (see the root `analysis_options.yaml`). It does not
> touch or depend on the LifeOS app.

## Status

Playable **vertical slice of the Act I prologue**: wake → first contact with
«М.» → a branching first choice → a warm memory insert → loop. Two branches are
lethal **horror dead-ends** (sleep paralysis, "the one on the line") that loop
the night back to 03:14 while keeping your knowledge — with a **safe mode**
toggle. CG art is mood-tinted placeholders + art briefs until real anime
illustrations are produced from the character sheets.

## Run

```bash
cd missed_call
flutter pub get
flutter run            # web / android / desktop
flutter analyze        # analyzed as its own package
flutter test
```

Zero third-party dependencies — the whole novel is a data-driven scene graph
rendered with the Flutter SDK only, so the build stays **plugin-free** (no
native Windows code), consistent with the LifeOS rule.

## Structure

```
lib/
  main.dart                 entry
  app.dart                  MaterialApp
  engine/
    models.dart             Mood, Speaker, CgSpec, VnLine, VnChoice, VnNode
    vn_controller.dart      ChangeNotifier: current node, advance, choose, restart
    script_act1.dart        Act I prologue as data (the single source of truth)
  ui/
    mood_palette.dart       atmosphere-as-a-system: colours per Mood
    vn_screen.dart          the player (CG stage + dialogue box + choices)
docs/
  story.md                  the tangled plot, 5 layers, 14 endings
  characters.md             Дан · Артём · «М.» · Ирина (+ AI art prompts)
  design.md                 loop, 33-min timer, anchors, 7 fragments, art direction
  horror.md                 dead-end = death = loop, 6 death beats, safe mode
```

## How to add content

- **New scene:** add a `VnNode` to `script_act1.dart`. Wire it with `next:` (linear)
  or `choices:` (branch). No engine changes needed.
- **New CG:** set the node's `CgSpec` (`id`, `mood`, `brief`). Drop the real image
  under `assets/cg/<id>` later and enable the asset in `pubspec.yaml`.
- **Localization:** lines are plain strings today; they map cleanly onto the LifeOS
  i18n table (en/ru/uk) when the game moves in-repo.

## Roadmap

1. Act I prologue slice — **done**.
2. Horror dead-ends + death loop + safe mode — **done** (`docs/horror.md`).
3. Night timer + loop + anchors (see `docs/design.md`).
4. Memory screen with progressive room reveal (7 fragments).
5. Full Act I dialogue + remaining death beats + first endings.
6. Real anime CGs from the character/scene briefs.
