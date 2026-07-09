import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// A toggleable notification category.
class NotifCategory {
  final String id;
  final String emoji;
  final String labelKey;
  const NotifCategory(this.id, this.emoji, this.labelKey);
}

const notifCategories = <NotifCategory>[
  NotifCategory('expiry', '🥫', 'nprefs.expiry'),
  NotifCategory('budget', '🎯', 'nprefs.budget'),
  NotifCategory('period', '🌸', 'nprefs.period'),
  NotifCategory('weekly', '📊', 'nprefs.weekly'),
  NotifCategory('achievement', '🏅', 'nprefs.achievement'),
];

/// User control over which notifications fire and a quiet-hours window during
/// which the phone push is suppressed (the in-app feed still records them).
class NotificationPrefs {
  final Map<String, bool> categories;
  final bool quietEnabled;
  final int quietStart; // hour 0–23
  final int quietEnd;

  const NotificationPrefs({
    this.categories = const {},
    this.quietEnabled = false,
    this.quietStart = 22,
    this.quietEnd = 7,
  });

  bool enabled(String category) => categories[category] ?? true;

  bool quietAt(int hour) {
    if (!quietEnabled || quietStart == quietEnd) return false;
    return quietStart < quietEnd
        ? hour >= quietStart && hour < quietEnd
        : hour >= quietStart || hour < quietEnd;
  }

  NotificationPrefs copyWith({
    Map<String, bool>? categories,
    bool? quietEnabled,
    int? quietStart,
    int? quietEnd,
  }) =>
      NotificationPrefs(
        categories: categories ?? this.categories,
        quietEnabled: quietEnabled ?? this.quietEnabled,
        quietStart: quietStart ?? this.quietStart,
        quietEnd: quietEnd ?? this.quietEnd,
      );

  Map<String, dynamic> toJson() => {
        'categories': categories,
        'quietEnabled': quietEnabled,
        'quietStart': quietStart,
        'quietEnd': quietEnd,
      };

  factory NotificationPrefs.fromJson(Map<String, dynamic> j) =>
      NotificationPrefs(
        categories: {
          for (final e in (j['categories'] as Map<String, dynamic>? ?? {}).entries)
            e.key: e.value as bool,
        },
        quietEnabled: (j['quietEnabled'] as bool?) ?? false,
        quietStart: (j['quietStart'] as num?)?.toInt() ?? 22,
        quietEnd: (j['quietEnd'] as num?)?.toInt() ?? 7,
      );
}

class NotificationPrefsController extends Notifier<NotificationPrefs> {
  static const _key = 'notif.prefs';

  @override
  NotificationPrefs build() {
    final raw = ref.watch(keyValueStoreProvider).getString(_key);
    if (raw == null) return const NotificationPrefs();
    try {
      return NotificationPrefs.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const NotificationPrefs();
    }
  }

  void _save(NotificationPrefs prefs) {
    ref.read(keyValueStoreProvider).setString(_key, jsonEncode(prefs.toJson()));
    state = prefs;
  }

  void setCategory(String category, bool on) =>
      _save(state.copyWith(categories: {...state.categories, category: on}));

  void setQuiet({bool? enabled, int? start, int? end}) => _save(state.copyWith(
        quietEnabled: enabled,
        quietStart: start,
        quietEnd: end,
      ));
}

final notificationPrefsProvider =
    NotifierProvider<NotificationPrefsController, NotificationPrefs>(
        NotificationPrefsController.new);
