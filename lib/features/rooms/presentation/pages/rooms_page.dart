import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/home/presentation/providers/today_providers.dart';
import 'package:lifeos/features/profile/presentation/providers/profile_providers.dart';
import 'package:lifeos/features/rooms/domain/life_room.dart';
import 'package:lifeos/features/rooms/presentation/providers/rooms_providers.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';

/// Home: the four rooms of your life as a 2×2 grid, with the Life Score sitting
/// exactly where they meet — because it is computed from those four pillars.
/// Tapping a room opens everything that belongs to it.
class RoomsPage extends ConsumerWidget {
  /// Called with the tapped room, so navigation stays the caller's business.
  final void Function(RoomId room)? onOpenRoom;
  final VoidCallback? onOpenProfile;

  const RoomsPage({this.onOpenRoom, this.onOpenProfile, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = ref.watch(roomSummariesProvider);
    final score = ref.watch(lifeScoreProvider).total;
    final name = ref.watch(profileProvider)?.name.trim() ?? '';
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;

    final hour = DateTime.now().hour;
    final part = hour < 12
        ? context.tr('today.morning')
        : hour < 18
            ? context.tr('today.afternoon')
            : context.tr('today.evening');
    final lang = Localizations.localeOf(context).languageCode;
    var date = DateFormat.yMMMMEEEEd(lang).format(DateTime.now());
    if (date.isNotEmpty) date = date[0].toUpperCase() + date.substring(1);

    return Scaffold(
      body: AnimatedBackdrop(
        style: BackdropStyle.galaxy,
        color: const Color(0xFF7B5CFF),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isEmpty ? part : '$part, $name',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(date,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: scheme.outline)),
                        ],
                      ),
                    ),
                    if (onOpenProfile != null)
                      IconButton(
                        icon: const Icon(Icons.person_outline),
                        tooltip: context.tr('profile.title'),
                        onPressed: onOpenProfile,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, outer) {
                      // Take the height that's going, but never let a tile grow
                      // so tall that its hero number is stranded at the bottom
                      // of an empty box. Short screens shrink, tall ones cap.
                      const gap = 10.0;
                      final tileW = (outer.maxWidth - gap) / 2;
                      final tileH =
                          ((outer.maxHeight - gap) / 2).clamp(0.0, tileW * 1.12);
                      // Align is load-bearing: Expanded hands down a *tight*
                      // height, so without it the SizedBox is stretched, and
                      // the score badge — positioned at half the stack height —
                      // drifts below the seam it is supposed to sit on.
                      return Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                        width: outer.maxWidth,
                        height: tileH * 2 + gap,
                        child: LayoutBuilder(
                    builder: (context, c) {
                      // The score badge is centred on the seam between the four
                      // tiles, so it visibly belongs to all of them at once.
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Column(
                            children: [
                              Row(children: [
                                _RoomTile(
                                    room: kLifeRooms[0],
                                    summary: summaries[0],
                                    width: tileW,
                                    height: tileH,
                                    brightness: brightness,
                                    onTap: onOpenRoom),
                                const SizedBox(width: gap),
                                _RoomTile(
                                    room: kLifeRooms[1],
                                    summary: summaries[1],
                                    width: tileW,
                                    height: tileH,
                                    brightness: brightness,
                                    onTap: onOpenRoom),
                              ]),
                              const SizedBox(height: gap),
                              Row(children: [
                                _RoomTile(
                                    room: kLifeRooms[2],
                                    summary: summaries[2],
                                    width: tileW,
                                    height: tileH,
                                    brightness: brightness,
                                    onTap: onOpenRoom),
                                const SizedBox(width: gap),
                                _RoomTile(
                                    room: kLifeRooms[3],
                                    summary: summaries[3],
                                    width: tileW,
                                    height: tileH,
                                    brightness: brightness,
                                    onTap: onOpenRoom),
                              ]),
                            ],
                          ),
                          Positioned(
                            left: c.maxWidth / 2 - 33,
                            top: c.maxHeight / 2 - 33,
                            child: _ScoreBadge(score: score),
                          ),
                        ],
                      );
                    },
                        ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  final LifeRoom room;
  final RoomSummary summary;
  final double width;
  final double height;
  final Brightness brightness;
  final void Function(RoomId room)? onTap;

  const _RoomTile({
    required this.room,
    required this.summary,
    required this.width,
    required this.height,
    required this.brightness,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = room.colorFor(brightness);
    final dark = brightness == Brightness.dark;
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: dark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.4)
            : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap == null ? null : () => onTap!(room.id),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: dark
                  ? null
                  : Border.all(color: scheme.outlineVariant, width: 0.5),
            ),
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(room.icon, size: 20, color: accent),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        summary.hero,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.trp(summary.subtitleKey, summary.params),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.outline, height: 1.25),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The Life Score, parked on the seam between the four rooms.
class _ScoreBadge extends StatelessWidget {
  final int score;
  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant, width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$score',
              style: const TextStyle(
                  fontSize: 21, fontWeight: FontWeight.w800, height: 1)),
          const SizedBox(height: 1),
          Text(context.tr('room.score'),
              style: TextStyle(fontSize: 9, color: scheme.outline)),
        ],
      ),
    );
  }
}
