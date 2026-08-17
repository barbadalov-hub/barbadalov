import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/health/domain/entities/health_day.dart';
import 'package:lifeos/features/health/presentation/providers/health_providers.dart';
import 'package:lifeos/features/home/presentation/providers/today_providers.dart';
import 'package:lifeos/features/mind/presentation/providers/mind_providers.dart';
import 'package:lifeos/features/profile/presentation/providers/profile_providers.dart';
import 'package:lifeos/features/rooms/domain/life_room.dart';
import 'package:lifeos/features/rooms/domain/room_attention.dart';
import 'package:lifeos/features/rooms/presentation/providers/rooms_providers.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';

/// Home, laid out like a magazine front page.
///
/// One room can be running a lead story — a full-bleed cover in its own colour,
/// with the headline and a single thing to do about it. The other three sit
/// underneath as quiet spines. When no room needs anything, there is no lead at
/// all: the Life Score takes the top and all four rooms stay spines. That empty
/// headline is the point, not a gap — it means today you owe nobody anything.
class RoomsPage extends ConsumerWidget {
  /// Called with the tapped room, so navigation stays the caller's business.
  final void Function(RoomId room)? onOpenRoom;
  final VoidCallback? onOpenProfile;

  const RoomsPage({this.onOpenRoom, this.onOpenProfile, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = ref.watch(roomSummariesProvider);
    final attention = ref.watch(roomAttentionProvider);
    final score = ref.watch(lifeScoreProvider).total;
    final name = ref.watch(profileProvider)?.name.trim() ?? '';
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

    RoomSummary summaryFor(RoomId id) =>
        summaries.firstWhere((s) => s.id == id);

    // Reading order is never rearranged — only the lead is lifted out of it.
    final spines = kLifeRooms
        .where((r) => attention == null || r.id != attention.room)
        .toList();

    return Scaffold(
      body: AnimatedBackdrop(
        style: BackdropStyle.galaxy,
        // The backdrop takes the leading room's colour, so the whole page is
        // tinted by the story it is running. A fixed violet under the paper
        // skin just read as a bruise across the top.
        color: attention == null
            ? scheme.primary
            : roomById(attention.room).colorFor(Theme.of(context).brightness),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(date,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: scheme.outline)),
                        ],
                      ),
                    ),
                    // With a lead cover on top there is no seam left to park
                    // the score on, so it rides in the header instead.
                    if (attention != null) _ScorePill(score: score),
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
                  child: Column(
                    children: [
                      // Proportions carry the hierarchy: with a story running,
                      // the cover takes most of the page and the three spines
                      // are a footer. On a calm day nothing outranks anything,
                      // so the four rooms get the room instead.
                      Expanded(
                        flex: attention == null ? 2 : 4,
                        child: attention == null
                            ? _CalmCover(score: score)
                            : _LeadCover(
                                attention: attention,
                                summary: summaryFor(attention.room),
                                onOpen: onOpenRoom,
                                onAct: () => _act(context, ref, attention),
                              ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        flex: attention == null ? 3 : 1,
                        child: _SpineRack(
                          rooms: spines,
                          summaryFor: summaryFor,
                          onOpenRoom: onOpenRoom,
                          twoRows: attention == null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Runs the cover's offer. Only the fixes that genuinely take one tap happen
  /// in place; everything else opens the room, where the real controls live.
  void _act(BuildContext context, WidgetRef ref, RoomAttention attention) {
    switch (attention.action) {
      case AttentionAction.drinkGlass:
        ref.read(logHealthProvider).addWaterMl(HealthDay.mlPerGlass);
        _toast(context, context.tr('rooms.watered'));
      case AttentionAction.tickLastHabit:
        final habits = ref.read(habitsProvider).valueOrNull ?? const [];
        final open = habits.where((h) => !h.doneToday).toList();
        // The habit may have been ticked elsewhere between build and tap.
        if (open.length == 1) {
          ref.read(toggleHabitProvider).call(open.first);
          _toast(context, context.tr('rooms.habitDone'));
        } else {
          onOpenRoom?.call(attention.room);
        }
      case AttentionAction.openRoom:
        onOpenRoom?.call(attention.room);
    }
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// The cover always uses the room's *paper* colour, in both skins.
///
/// Those four are the ink-strength versions, picked to carry white type, so
/// contrast is guaranteed by construction rather than tuned per colour. Using
/// the night accents instead would mean a 600px slab of bright salmon glowing
/// in a dark room — striking in a screenshot, glare at 2am. A deep panel keeps
/// the drama without the flashlight.
const _coverInk = Colors.white;

/// The lead story: one room, full-bleed in its colour.
class _LeadCover extends StatelessWidget {
  final RoomAttention attention;
  final RoomSummary summary;
  final void Function(RoomId room)? onOpen;
  final VoidCallback onAct;

  const _LeadCover({
    required this.attention,
    required this.summary,
    required this.onOpen,
    required this.onAct,
  });

  @override
  Widget build(BuildContext context) {
    final room = roomById(attention.room);
    final ground = room.paper;
    const ink = _coverInk;

    return Material(
      color: ground,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen == null ? null : () => onOpen!(room.id),
        child: LayoutBuilder(builder: (context, box) {
          // The numeral is sized from the cover, not fixed: a tall cover with a
          // small number is a lot of empty colour, which reads as a mistake
          // rather than as space.
          final heroSize = (box.maxHeight * 0.19).clamp(34.0, 86.0);
          final watermark = box.maxHeight * 0.66;
          return Stack(
          children: [
            // The room's own icon, blown up until it works as the cover's
            // illustration. A cover this tall is mostly flat colour otherwise,
            // and flat colour reads as an empty box rather than as space.
            Positioned(
              // Upper right: the headline block sits along the bottom edge, so
              // that is where the empty colour actually is.
              top: -watermark * 0.08,
              right: -watermark * 0.18,
              child: Icon(room.icon,
                  size: watermark, color: ink.withValues(alpha: 0.11)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(room.titleKey).toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w600,
                      color: ink.withValues(alpha: 0.85),
                    ),
                  ),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      attention.heroKey == null
                          ? summary.hero
                          : context.trp(
                              attention.heroKey!, attention.heroParams),
                      style: TextStyle(
                        fontSize: heroSize,
                        height: 1.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.2,
                        color: ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Not Flexible: a flexible child divides the leftover space
                  // with the Spacer above it and then declines most of its
                  // share, which left a band of dead colour under the chip.
                  // maxLines already bounds the height.
                  Text(
                    context.trp(attention.reasonKey, attention.params),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: ink.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CoverChip(
                    label: context.tr(attention.actionKey),
                    ink: ink,
                    onTap: onAct,
                  ),
                ],
              ),
            ),
          ],
          );
        }),
      ),
    );
  }
}

/// The cover's single offer. Deliberately one, not a row: two chips on a
/// headline turn a clear instruction back into a decision.
class _CoverChip extends StatelessWidget {
  final String label;
  final Color ink;
  final VoidCallback onTap;

  const _CoverChip({
    required this.label,
    required this.ink,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: ink.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What runs on the front page when nothing is wrong.
class _CalmCover extends StatelessWidget {
  final int score;
  const _CalmCover({required this.score});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, box) {
      final scoreSize = (box.maxHeight * 0.26).clamp(40.0, 104.0);
      return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant, width: 0.5),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            context.tr('rooms.scoreLabel').toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
              color: scheme.outline,
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '$score',
              style: TextStyle(
                fontSize: scoreSize,
                height: 1.0,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.6,
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              context.tr('rooms.calm'),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: scheme.outline,
              ),
            ),
          ),
        ],
      ),
      );
    });
  }
}

/// The rooms that are not leading today, in permanent reading order.
class _SpineRack extends StatelessWidget {
  final List<LifeRoom> rooms;
  final RoomSummary Function(RoomId id) summaryFor;
  final void Function(RoomId room)? onOpenRoom;

  /// Four spines need two rows; three fit across one.
  final bool twoRows;

  const _SpineRack({
    required this.rooms,
    required this.summaryFor,
    required this.onOpenRoom,
    required this.twoRows,
  });

  @override
  Widget build(BuildContext context) {
    Widget spine(LifeRoom room) => Expanded(
          child: _Spine(
            room: room,
            summary: summaryFor(room.id),
            onTap: onOpenRoom,
            roomy: twoRows,
          ),
        );

    if (!twoRows) {
      return Row(
        children: [
          for (var i = 0; i < rooms.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            spine(rooms[i]),
          ],
        ],
      );
    }
    return Column(
      children: [
        Expanded(
          child: Row(children: [
            spine(rooms[0]),
            const SizedBox(width: 10),
            spine(rooms[1]),
          ]),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Row(children: [
            spine(rooms[2]),
            const SizedBox(width: 10),
            spine(rooms[3]),
          ]),
        ),
      ],
    );
  }
}

class _Spine extends StatelessWidget {
  final LifeRoom room;
  final RoomSummary summary;
  final void Function(RoomId room)? onTap;

  /// A two-row rack has width to spare, so the context line is worth printing.
  final bool roomy;

  const _Spine({
    required this.room,
    required this.summary,
    required this.onTap,
    required this.roomy,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final accent = room.colorFor(brightness);
    // A whisper of the room's colour, so a spine is recognisably the quiet
    // form of the same cover rather than a different kind of object.
    final ground = Color.lerp(accent, scheme.surfaceContainerLowest, 0.9)!;

    return Material(
      color: ground,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap == null ? null : () => onTap!(room.id),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: Color.lerp(accent, scheme.surface, 0.72)!, width: 0.5),
          ),
          padding: EdgeInsets.fromLTRB(roomy ? 13 : 10, 10, roomy ? 13 : 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr(room.titleKey).toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
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
                        fontSize: roomy ? 24 : 19,
                        height: 1.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  if (roomy) ...[
                    const SizedBox(height: 5),
                    Text(
                      context.trp(summary.subtitleKey, summary.params),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.outline, height: 1.2),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Life Score, small, in the header — visible on lead days too.
class _ScorePill extends StatelessWidget {
  final int score;
  const _ScorePill({required this.score});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A bare number beside the greeting is a riddle; the tooltip answers it on
    // long-press and, more importantly, names it for screen readers.
    return Tooltip(
      message: context.tr('rooms.scoreLabel'),
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: scheme.outlineVariant, width: 0.5),
        ),
        child: Text(
          '$score',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
