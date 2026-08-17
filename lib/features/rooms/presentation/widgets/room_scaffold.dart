import 'package:flutter/material.dart';
import 'package:lifeos/features/rooms/domain/life_room.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';

/// A quick action offered at the top of a room (the three chips).
class RoomAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const RoomAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

/// One tile on the room's tool shelf — the rare-but-needed screens. They are
/// shrunk, never hidden: reachable in one tap while taking a tenth of the room.
class RoomTool {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const RoomTool({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

/// The shared anatomy of every room, so all four feel like one app:
///
/// 1. [hero] — the single number that matters right now
/// 2. [voice] — one sentence that draws a conclusion, not more data
/// 3. [actions] — what you do here every day
/// 4. [children] — the room's own live content
/// 5. [tools] — the shelf of everything rare
class RoomScaffold extends StatelessWidget {
  final LifeRoom room;
  final String title;
  final Widget? hero;
  final String? voice;
  final List<RoomAction> actions;
  final List<Widget> children;
  final List<RoomTool> tools;
  final List<Widget> appBarActions;
  final Widget? floatingActionButton;

  const RoomScaffold({
    required this.room,
    required this.title,
    this.hero,
    this.voice,
    this.actions = const [],
    this.children = const [],
    this.tools = const [],
    this.appBarActions = const [],
    this.floatingActionButton,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final accent = room.colorFor(brightness);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            // Flexible, not bare: the title shares a 360px bar with up to three
            // actions, and a Russian room name plus those buttons overflows.
            Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: appBarActions,
      ),
      floatingActionButton: floatingActionButton,
      body: AnimatedBackdrop(
        style: BackdropStyle.galaxy,
        color: accent,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              16, 8, 16, floatingActionButton == null ? 28 : 96),
          children: [
            if (hero != null) ...[hero!, const SizedBox(height: 14)],
            if (voice != null) ...[
              RoomVoice(text: voice!),
              const SizedBox(height: 14),
            ],
            if (actions.isNotEmpty) ...[
              _ActionChips(actions: actions, accent: accent),
              const SizedBox(height: 14),
            ],
            ...children,
            if (tools.isNotEmpty) ...[
              const SizedBox(height: 16),
              _ToolShelf(tools: tools, accent: accent),
            ],
          ],
        ),
      ),
    );
  }
}

/// The room's one sentence. Larger and airier than body copy so it reads as a
/// conclusion rather than another label.
class RoomVoice extends StatelessWidget {
  final String text;
  const RoomVoice({required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        // A serif when the platform has one; the size and leading carry the
        // voice either way, so the fallback still reads as a sentence.
        fontFamily: 'serif',
        fontSize: 16,
        height: 1.5,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.88),
      ),
    );
  }
}

class _ActionChips extends StatelessWidget {
  final List<RoomAction> actions;
  final Color accent;
  const _ActionChips({required this.actions, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final a in actions)
          ActionChip(
            avatar: Icon(a.icon, size: 17, color: accent),
            label: Text(a.label),
            onPressed: a.onTap,
          ),
      ],
    );
  }
}

class _ToolShelf extends StatelessWidget {
  final List<RoomTool> tools;
  final Color accent;
  const _ToolShelf({required this.tools, required this.accent});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const perRow = 4;
    const gap = 8.0;
    // Wraps past four so a room can own more tools without any of them being
    // dropped — shrinking rare features is the point, losing them is not.
    return LayoutBuilder(
      builder: (context, c) {
        final itemW = (c.maxWidth - gap * (perRow - 1)) / perRow;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final t in tools)
              SizedBox(
                width: itemW,
                child: Material(
              color: scheme.surfaceContainerHighest.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.4
                      : 1),
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: t.onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      Icon(t.icon, size: 19, color: accent),
                      const SizedBox(height: 5),
                      Text(
                        t.label,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: scheme.outline),
                      ),
                    ],
                  ),
                ),
              ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The room's headline figure: a label, the number, an optional progress line
/// and a caption under it.
class RoomHero extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final double? progress;
  final String? caption;

  const RoomHero({
    required this.label,
    required this.value,
    required this.accent,
    this.progress,
    this.caption,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 12, color: scheme.outline)),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: accent,
                ),
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 11),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress!.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: scheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              ),
            ],
            if (caption != null) ...[
              const SizedBox(height: 7),
              Text(caption!,
                  style: TextStyle(fontSize: 12, color: scheme.outline)),
            ],
          ],
        ),
      ),
    );
  }
}
