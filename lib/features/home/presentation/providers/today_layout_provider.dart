import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// A toggleable Today section: its stable [id] (used for ordering + persistence)
/// and the i18n [labelKey] shown in the customize sheet.
class TodaySection {
  final String id;
  final String labelKey;
  const TodaySection(this.id, this.labelKey);
}

/// The ordered catalog of Today sections. This is the single source of truth for
/// both the on-screen order and the customize sheet. The greeting is fixed and
/// not part of this list.
const kTodaySections = <TodaySection>[
  TodaySection('quickActions', 'tsec.quickActions'),
  TodaySection('streak', 'tsec.streak'),
  TodaySection('coachTip', 'tsec.coachTip'),
  TodaySection('safeToSpend', 'tsec.safeToSpend'),
  TodaySection('lifeScore', 'tsec.lifeScore'),
  TodaySection('budget', 'tsec.budget'),
  TodaySection('diet', 'tsec.diet'),
  TodaySection('health', 'tsec.health'),
  TodaySection('habits', 'tsec.habits'),
  TodaySection('tasks', 'tsec.tasks'),
  TodaySection('goal', 'tsec.goal'),
  TodaySection('backup', 'tsec.backup'),
  TodaySection('ai', 'tsec.ai'),
  TodaySection('quote', 'tsec.quote'),
  TodaySection('flashback', 'tsec.flashback'),
  TodaySection('lifeWeeks', 'tsec.lifeWeeks'),
  TodaySection('achievements', 'tsec.achievements'),
];

/// The i18n label key for a section id (falls back to '' for unknown ids).
String labelForSection(String id) {
  for (final s in kTodaySections) {
    if (s.id == id) return s.labelKey;
  }
  return '';
}

/// A life area the user can choose to focus on during onboarding.
class FocusArea {
  final String id;
  final String emoji;
  final String labelKey;
  const FocusArea(this.id, this.emoji, this.labelKey);
}

const kFocusAreas = <FocusArea>[
  FocusArea('money', '💰', 'onb.area.money'),
  FocusArea('health', '❤️', 'onb.area.health'),
  FocusArea('food', '🥗', 'onb.area.food'),
  FocusArea('habits', '✅', 'onb.area.habits'),
  FocusArea('goals', '🎯', 'onb.area.goals'),
  FocusArea('mood', '📔', 'onb.area.mood'),
];

/// Which Today cards each focus area brings forward.
const _areaCards = <String, List<String>>{
  'money': ['safeToSpend', 'budget', 'ai'],
  'health': ['health'],
  'food': ['diet'],
  'habits': ['habits', 'tasks', 'achievements', 'streak'],
  'goals': ['goal', 'lifeWeeks'],
  'mood': ['coachTip', 'flashback', 'quote'],
};

/// Turns a set of chosen focus areas into a full Today layout: a complete order
/// (focused cards first, the rest appended) and the hidden set. An empty focus
/// leaves the default layout untouched. Pure — unit-tested.
({List<String> order, Set<String> hidden}) focusLayout(Set<String> focus) {
  final catalog = [for (final s in kTodaySections) s.id];
  if (focus.isEmpty) return (order: catalog, hidden: <String>{});

  const core = ['quickActions', 'lifeScore'];
  final wanted = <String>{...core};
  for (final a in focus) {
    wanted.addAll(_areaCards[a] ?? const []);
  }
  final visible = [
    ...core.where(catalog.contains),
    for (final id in catalog)
      if (wanted.contains(id) && !core.contains(id)) id,
  ];
  final hidden = [for (final id in catalog) if (!wanted.contains(id)) id];
  return (order: [...visible, ...hidden], hidden: hidden.toSet());
}

/// The user's Today section order (list of ids). Persisted as a comma-joined
/// string and reconciled against [kTodaySections] on load so newly-shipped
/// sections appear (appended) and removed ones drop out.
class TodayOrderController extends Notifier<List<String>> {
  static const _key = 'today.order';

  @override
  List<String> build() {
    final raw = ref.watch(keyValueStoreProvider).getString(_key);
    final stored = (raw == null || raw.isEmpty)
        ? <String>[]
        : raw.split(',').where((s) => s.isNotEmpty).toList();
    final catalog = [for (final s in kTodaySections) s.id];
    final ordered = [
      for (final id in stored)
        if (catalog.contains(id)) id
    ];
    for (final id in catalog) {
      if (!ordered.contains(id)) ordered.add(id);
    }
    return ordered;
  }

  /// Moves the section at [oldIndex] to [newIndex]. Uses `onReorderItem`
  /// semantics: [newIndex] is already the target index after the item is removed,
  /// so no off-by-one adjustment is needed.
  void reorder(int oldIndex, int newIndex) {
    final next = [...state];
    final item = next.removeAt(oldIndex);
    next.insert(newIndex, item);
    ref.read(keyValueStoreProvider).setString(_key, next.join(','));
    state = next;
  }

  /// Replaces the whole order (e.g. from an onboarding focus choice).
  void setOrder(List<String> order) {
    ref.read(keyValueStoreProvider).setString(_key, order.join(','));
    state = [...order];
  }
}

final todayOrderProvider =
    NotifierProvider<TodayOrderController, List<String>>(
        TodayOrderController.new);

/// The set of Today section ids the user has hidden. Persisted as a comma-joined
/// string; empty means everything is shown (the default).
class TodayLayoutController extends Notifier<Set<String>> {
  static const _key = 'today.hidden';

  @override
  Set<String> build() {
    final raw = ref.watch(keyValueStoreProvider).getString(_key);
    if (raw == null || raw.isEmpty) return <String>{};
    return raw.split(',').where((s) => s.isNotEmpty).toSet();
  }

  void setVisible(String id, bool visible) {
    final next = {...state};
    if (visible) {
      next.remove(id);
    } else {
      next.add(id);
    }
    ref.read(keyValueStoreProvider).setString(_key, next.join(','));
    state = next;
  }

  /// Replaces the whole hidden set (e.g. from an onboarding focus choice).
  void setHidden(Set<String> ids) {
    ref.read(keyValueStoreProvider).setString(_key, ids.join(','));
    state = {...ids};
  }
}

final todayHiddenProvider =
    NotifierProvider<TodayLayoutController, Set<String>>(
        TodayLayoutController.new);
