import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/utils/open_url.dart';
import 'package:lifeos/features/health/data/wger_catalog_service.dart';
import 'package:lifeos/features/health/domain/entities/workout.dart';
import 'package:lifeos/features/health/domain/entities/workout_program.dart';
import 'package:lifeos/features/health/presentation/pages/workout_guide_page.dart';
import 'package:lifeos/features/health/presentation/pages/workout_programs_page.dart';
import 'package:lifeos/features/health/presentation/providers/health_providers.dart';
import 'package:lifeos/features/health/presentation/providers/workout_providers.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:lifeos/shared/widgets/section_card.dart';
import 'package:lifeos/shared/widgets/video_player.dart';

/// Workouts: a curated "program of the day" with step-by-step technique, plus
/// the **entire live wger catalog (~800+ exercises)** with search — names come
/// localized from wger itself, images stream lazily, and exercises with a real
/// wger technique video play it on demand.
class WorkoutsPage extends ConsumerWidget {
  const WorkoutsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(wgerCatalogProvider);
    final filtered = ref.watch(filteredWgerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('wo.title'))),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionCard(
                    color: LifeColors.goals.withValues(alpha: 0.12),
                    padding: const EdgeInsets.all(14),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => const WorkoutGuidePage()),
                    ),
                    child: Row(
                      children: [
                        const Text('⚠️', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.tr('guide.title'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium),
                              Text(context.tr('guide.banner'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline,
                                      )),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _ProgramsSection(),
                  const SizedBox(height: 16),
                  Text(context.tr('wo.program'),
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  for (final w in WorkoutCatalog.all)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CuratedWorkoutCard(workout: w),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(context.tr('wo.catalogTitle'),
                            style: Theme.of(context).textTheme.titleLarge),
                      ),
                      catalog.when(
                        loading: () => const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        error: (_, __) => const Icon(Icons.cloud_off, size: 18),
                        data: (list) => Chip(
                          visualDensity: VisualDensity.compact,
                          side: BorderSide.none,
                          label: Text(context
                              .trp('wo.catalogCount', {'n': list.length})),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (v) =>
                        ref.read(workoutSearchProvider.notifier).state = v,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: context.tr('wo.search'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        avatar: const Icon(Icons.play_circle_outline, size: 18),
                        label: Text(context.tr('wo.withVideo')),
                        selected: ref.watch(videoOnlyProvider),
                        onSelected: (v) =>
                            ref.read(videoOnlyProvider.notifier).state = v,
                      ),
                      FilterChip(
                        avatar: const Icon(Icons.star, size: 18),
                        label: Text(context.tr('wo.favorites')),
                        selected: ref.watch(favoritesOnlyProvider),
                        onSelected: (v) =>
                            ref.read(favoritesOnlyProvider.notifier).state = v,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const _CategoryChips(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          if (catalog.isLoading && filtered.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: Text(context.tr('wo.loading'))),
              ),
            ),
          SliverList.builder(
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final e = filtered[i];
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _WgerCard(exercise: e),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ready-made programs strip.
// ---------------------------------------------------------------------------
class _ProgramsSection extends StatelessWidget {
  const _ProgramsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('prog.title'),
            style: Theme.of(context).textTheme.titleLarge),
        Text(context.tr('prog.sub'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                )),
        const SizedBox(height: 10),
        SizedBox(
          height: 162,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: WorkoutProgramCatalog.all.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) =>
                _ProgramCard(program: WorkoutProgramCatalog.all[i]),
          ),
        ),
      ],
    );
  }
}

/// Muscle-group / category filter chips for the catalog.
class _CategoryChips extends ConsumerWidget {
  const _CategoryChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(wgerCategoriesProvider);
    if (categories.isEmpty) return const SizedBox.shrink();
    final selected = ref.watch(workoutCategoryProvider);
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(context.tr('wo.allMuscles')),
              selected: selected == null,
              onSelected: (_) =>
                  ref.read(workoutCategoryProvider.notifier).state = null,
            ),
          ),
          for (final c in categories)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(c),
                selected: selected == c,
                onSelected: (_) =>
                    ref.read(workoutCategoryProvider.notifier).state = c,
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final WorkoutProgram program;
  const _ProgramCard({required this.program});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: SectionCard(
        padding: const EdgeInsets.all(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
              builder: (_) => ProgramDetailPage(program: program)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(program.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(context.tr(program.nameKey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              '${context.tr('prog.level.${program.level}')} · '
              '${program.durationMin} ${context.tr('prog.min')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            Text(
              '${program.exerciseIds.length} ${context.tr('prog.exCount')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Curated program cards (step-by-step technique, sets×reps).
// ---------------------------------------------------------------------------
class CuratedWorkoutCard extends ConsumerWidget {
  final Workout workout;
  const CuratedWorkoutCard({required this.workout, super.key});

  String? get _image =>
      workout.imageUrl.isEmpty
          ? null
          : WgerCatalogService.corsSafeImage(workout.imageUrl);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SectionCard(
      padding: EdgeInsets.zero,
      onTap: () => _openDetails(context, ref),
      child: Row(
        children: [
          WorkoutThumb(
            url: _image,
            fallbackEmoji: workout.emoji,
            size: 88,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr(workout.nameKey),
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(context.tr(workout.musclesKey),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          )),
                  const SizedBox(height: 4),
                  Text(workout.setsReps,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  void _openDetails(BuildContext context, WidgetRef ref) {
    showWorkoutSheet(
      context: context,
      ref: ref,
      workoutId: workout.id,
      title: context.tr(workout.nameKey),
      subtitle: '${context.tr(workout.musclesKey)} · ${workout.setsReps}',
      imageUrl: _image,
      fallbackEmoji: workout.emoji,
      steps: [for (final k in workout.stepKeys) context.tr(k)],
      videoUrl: null,
      videoQuery: context.tr(workout.nameKey),
    );
  }
}

// ---------------------------------------------------------------------------
// Live wger catalog cards.
// ---------------------------------------------------------------------------
class _WgerCard extends ConsumerWidget {
  final WgerExercise exercise;
  const _WgerCard({required this.exercise});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SectionCard(
      padding: EdgeInsets.zero,
      onTap: () => showWorkoutSheet(
        context: context,
        ref: ref,
        workoutId: 'wger-${exercise.id}',
        title: exercise.name,
        subtitle: [
          if (exercise.category.isNotEmpty) exercise.category,
          if (exercise.muscles.isNotEmpty) exercise.muscles.join(', '),
        ].join(' · '),
        imageUrl: exercise.imageUrl == null
            ? null
            : WgerCatalogService.corsSafeImage(exercise.imageUrl!),
        fallbackEmoji: '🏋️',
        steps: exercise.description.isEmpty
            ? [context.tr('wo.noDesc')]
            : [exercise.description],
        videoUrl: exercise.videoUrl,
        videoQuery: exercise.name,
      ),
      child: Row(
        children: [
          WorkoutThumb(
            url: exercise.imageUrl == null
                ? null
                : WgerCatalogService.corsSafeImage(exercise.imageUrl!),
            fallbackEmoji: '🏋️',
            size: 64,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exercise.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall),
                  Text(
                    [
                      if (exercise.category.isNotEmpty) exercise.category,
                      if (exercise.muscles.isNotEmpty)
                        exercise.muscles.take(2).join(', '),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),
          ),
          Builder(builder: (_) {
            final fav = ref
                .watch(favoriteWorkoutsProvider)
                .contains('wger-${exercise.id}');
            return IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(fav ? Icons.star : Icons.star_border,
                  size: 20, color: fav ? LifeColors.goals : null),
              onPressed: () => ref
                  .read(favoriteWorkoutsProvider.notifier)
                  .toggle('wger-${exercise.id}'),
            );
          }),
          if (exercise.videoUrl != null)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.play_circle_outline,
                  size: 20, color: LifeColors.health),
            ),
          const Padding(
            padding: EdgeInsets.only(right: 10),
            child: Icon(Icons.chevron_right, size: 20),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared detail sheet + lazy image.
// ---------------------------------------------------------------------------
void showWorkoutSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String workoutId,
  required String title,
  required String subtitle,
  required String? imageUrl,
  required String fallbackEmoji,
  required List<String> steps,
  required String? videoUrl,
  required String videoQuery,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      builder: (ctx, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Center(
            child: WorkoutThumb(
                url: imageUrl, fallbackEmoji: fallbackEmoji, size: 180),
          ),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(ctx).textTheme.headlineSmall),
          if (subtitle.isNotEmpty)
            Text(subtitle,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(ctx).colorScheme.outline,
                    )),
          const SizedBox(height: 12),
          if (steps.length > 1)
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                        radius: 11,
                        child: Text('${i + 1}',
                            style: const TextStyle(fontSize: 12))),
                    const SizedBox(width: 10),
                    Expanded(child: Text(steps[i])),
                  ],
                ),
              )
          else
            Text(steps.first),
          const SizedBox(height: 10),
          Text(
            ctx.tr('guide.sheetWarn'),
            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  color: LifeColors.goals,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.play_circle_outline),
                  label: Text(ctx.tr(
                      videoUrl != null ? 'wo.videoWger' : 'wo.video')),
                  onPressed: () => videoUrl != null
                      // Real wger technique clip → plays inside the app.
                      ? playVideo(ctx, videoUrl, title)
                      // No clip in the database → YouTube search in browser.
                      : openUrl(
                          'https://www.youtube.com/results?search_query='
                          '${Uri.encodeQueryComponent('${ctx.tr('wo.videoQuery')} $videoQuery')}',
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: Text(ctx.tr('wo.done')),
                  onPressed: () {
                    ref.read(logHealthProvider).completeWorkout(workoutId);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                          SnackBar(content: Text(context.tr('wo.logged'))));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class WorkoutThumb extends StatelessWidget {
  final String? url;
  final String fallbackEmoji;
  final double size;
  const WorkoutThumb({
    required this.url,
    required this.fallbackEmoji,
    required this.size,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Center(
      child: Text(fallbackEmoji, style: TextStyle(fontSize: size * 0.4)),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: size,
        height: size,
        color: Colors.white,
        child: url == null
            ? placeholder
            : Image.network(
                url!,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : placeholder,
                errorBuilder: (_, __, ___) => placeholder,
              ),
      ),
    );
  }
}
