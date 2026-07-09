import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/locale_controller.dart';
import 'package:lifeos/features/health/data/wger_catalog_service.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

final wgerServiceProvider =
    Provider<WgerCatalogService>((ref) => WgerCatalogService());

/// wger language priority follows the app language (ru→5, uk→15, en→2).
final wgerLangPriorityProvider = Provider<List<int>>((ref) {
  final code = ref.watch(localeProvider)?.languageCode ?? 'en';
  final primary = WgerCatalogService.languageIds[code] ?? 2;
  return [primary, 2];
});

/// The full live wger catalog with a 7-day persisted cache: cached copy shows
/// instantly, a fresh fetch replaces it when stale or missing.
class WgerCatalogController extends AsyncNotifier<List<WgerExercise>> {
  static const _key = 'wger.catalog';

  @override
  Future<List<WgerExercise>> build() async {
    final store = ref.watch(jsonStoreProvider);
    final lang = ref.watch(wgerLangPriorityProvider);
    final cacheKey = '$_key.${lang.first}';

    final cached = store.loadObject<Map<String, dynamic>>(
      cacheKey,
      (j) => j,
      fallback: const {},
    );
    final ts = DateTime.tryParse((cached['ts'] as String?) ?? '');
    final items = ((cached['items'] as List<dynamic>?) ?? const [])
        .map((e) => WgerExercise.fromJson(e as Map<String, dynamic>))
        .toList();
    final fresh = ts != null &&
        ref.read(clockProvider).now().difference(ts).inDays < 7;
    if (items.isNotEmpty && fresh) return items;

    final live = await ref.read(wgerServiceProvider).fetchAll(lang);
    if (live.isEmpty) return items; // offline → keep whatever cache we had
    store.saveObject<Map<String, dynamic>>(
      cacheKey,
      {
        'ts': ref.read(clockProvider).now().toIso8601String(),
        'items': [for (final e in live) e.toJson()],
      },
      (m) => m,
    );
    return live;
  }
}

final wgerCatalogProvider =
    AsyncNotifierProvider<WgerCatalogController, List<WgerExercise>>(
        WgerCatalogController.new);

final workoutSearchProvider = StateProvider<String>((ref) => '');

/// Show only exercises that have a real wger technique video.
final videoOnlyProvider = StateProvider<bool>((ref) => false);

/// Show only favorited exercises.
final favoritesOnlyProvider = StateProvider<bool>((ref) => false);

/// Selected muscle-group/category filter (null = all).
final workoutCategoryProvider = StateProvider<String?>((ref) => null);

/// Favorited exercise ids (`wger-<id>`), persisted.
class FavoriteWorkoutsController extends Notifier<Set<String>> {
  static const _key = 'workouts.favorites';

  @override
  Set<String> build() {
    final raw = ref.watch(keyValueStoreProvider).getString(_key);
    if (raw == null) return {};
    try {
      return {for (final e in jsonDecode(raw) as List) e as String};
    } catch (_) {
      return {};
    }
  }

  void toggle(String id) {
    final next = {...state};
    next.contains(id) ? next.remove(id) : next.add(id);
    ref.read(keyValueStoreProvider).setString(_key, jsonEncode(next.toList()));
    state = next;
  }

  bool contains(String id) => state.contains(id);
}

final favoriteWorkoutsProvider =
    NotifierProvider<FavoriteWorkoutsController, Set<String>>(
        FavoriteWorkoutsController.new);

/// Distinct exercise categories present in the catalog (for filter chips).
final wgerCategoriesProvider = Provider<List<String>>((ref) {
  final all = ref.watch(wgerCatalogProvider).valueOrNull ?? const [];
  final set = <String>{for (final e in all) if (e.category.isNotEmpty) e.category};
  final list = set.toList()..sort();
  return list;
});

/// Catalog filtered by search, video, favorites and category.
final filteredWgerProvider = Provider<List<WgerExercise>>((ref) {
  final all = ref.watch(wgerCatalogProvider).valueOrNull ?? const [];
  final query = ref.watch(workoutSearchProvider).trim().toLowerCase();
  final videoOnly = ref.watch(videoOnlyProvider);
  final favOnly = ref.watch(favoritesOnlyProvider);
  final favs = ref.watch(favoriteWorkoutsProvider);
  final category = ref.watch(workoutCategoryProvider);
  return [
    for (final e in all)
      if ((!videoOnly || e.videoUrl != null) &&
          (!favOnly || favs.contains('wger-${e.id}')) &&
          (category == null || e.category == category) &&
          (query.isEmpty ||
              e.name.toLowerCase().contains(query) ||
              e.category.toLowerCase().contains(query)))
        e,
  ];
});
