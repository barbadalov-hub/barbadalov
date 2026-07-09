import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/core/constants/app_constants.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/mind/domain/mood.dart';
import 'package:lifeos/features/wrapped/domain/wrapped_stats.dart';
import 'package:lifeos/features/wrapped/presentation/providers/wrapped_providers.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/widgets/gradient_card.dart';
import 'package:lifeos/shared/widgets/motion.dart';
import 'package:lifeos/shared/widgets/share_card.dart';

/// "LifeOS Wrapped" — a full-screen, swipeable year-in-review (à la Spotify
/// Wrapped) that ends on a single shareable card. Bold gradient story cards,
/// tap or swipe to advance.
class WrappedPage extends ConsumerStatefulWidget {
  const WrappedPage({super.key});

  @override
  ConsumerState<WrappedPage> createState() => _WrappedPageState();
}

class _WrappedPageState extends ConsumerState<WrappedPage> {
  final _controller = PageController();
  final _shareKey = GlobalKey();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(wrappedProvider);
    final pages = _buildPages(stats);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0518),
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            children: pages,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                children: [
                  for (var i = 0; i < pages.length; i++)
                    Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withValues(alpha: i <= _page ? 1 : 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPages(WrappedStats s) {
    if (!s.hasData) {
      return [
        const _IntroCard(),
        _StatCard(
          gradient: const [Color(0xFF7B5CFF), Color(0xFF2A1A5E)],
          emoji: '🌌',
          label: context.tr('wrapped.emptyTitle'),
          headline: Text('${s.year}', style: _bigStyle),
          sub: context.tr('wrapped.empty'),
        ),
      ];
    }

    // 1 — Intro (with the year picker).
    final pages = <Widget>[const _IntroCard()];

    // 2 — Money.
    if (s.incomeMinor > 0 || s.spentMinor > 0) {
      pages.add(_tap(_StatCard(
        gradient: LifeGradients.finance,
        emoji: s.netMinor >= 0 ? '💚' : '💸',
        label: context.tr(
            s.netMinor >= 0 ? 'wrapped.netSaved' : 'wrapped.netSpent'),
        headline: Text(_money(s.netMinor.abs()), style: _bigStyle),
        sub: '${context.trp('wrapped.earned', {
              'v': _money(s.incomeMinor)
            })}\n${context.trp('wrapped.spent', {'v': _money(s.spentMinor)})}',
      )));
    }

    // 3 — Top category.
    if (s.topCategoryId != null) {
      final cat = DefaultCategories.byId(s.topCategoryId!);
      pages.add(_tap(_StatCard(
        gradient: const [Color(0xFFF7971E), Color(0xFFFFD200)],
        emoji: cat.emoji,
        label: context.tr('wrapped.topCat'),
        headline: Text(context.tr('cat.${cat.id}'), style: _midStyle),
      )));
    }

    // 4 — Steps.
    if (s.totalSteps > 0) {
      final km = (s.totalSteps * 0.762 / 1000);
      pages.add(_tap(_StatCard(
        gradient: LifeGradients.health,
        emoji: '👟',
        label: context.tr('wrapped.stepsTitle'),
        headline: AnimatedCounter(
          value: s.totalSteps.toDouble(),
          format: (v) => _grouped(v),
          style: _bigStyle,
        ),
        sub: '${context.trp('wrapped.stepsKm', {
              'km': km.toStringAsFixed(0)
            })}\n${context.trp('wrapped.stepsPerDay', {
              'n': _grouped(s.avgSteps.toDouble())
            })}',
      )));
    }

    // 5 — Sleep.
    if (s.avgSleep > 0) {
      pages.add(_tap(_StatCard(
        gradient: LifeGradients.mind,
        emoji: '😴',
        label: context.tr('wrapped.sleepTitle'),
        headline: Text(
            context.trp('wrapped.hours', {'n': s.avgSleep.toStringAsFixed(1)}),
            style: _bigStyle),
      )));
    }

    // 6 — Mood.
    if (s.moodMonths > 0) {
      pages.add(_tap(_StatCard(
        gradient: const [Color(0xFFFF6CAB), Color(0xFF7366FF)],
        emoji: moodFace(s.avgMood.round()),
        label: context.tr('wrapped.moodTitle'),
        headline: Text(
            context.trp('wrapped.moodVal', {'v': s.avgMood.toStringAsFixed(1)}),
            style: _midStyle),
      )));
    }

    // 7 — Best streak.
    if (s.bestStreak > 0) {
      pages.add(_tap(_StatCard(
        gradient: const [Color(0xFFF83600), Color(0xFFFE8C00)],
        emoji: '🔥',
        label: context.tr('wrapped.streakTitle'),
        headline: AnimatedCounter(
          value: s.bestStreak.toDouble(),
          format: (v) => context.trp('wrapped.days', {'n': v.round()}),
          style: _bigStyle,
        ),
      )));
    }

    // 8 — Goals.
    if (s.goalsSavedMinor > 0 || s.goalsCompleted > 0) {
      pages.add(_tap(_StatCard(
        gradient: LifeGradients.goals,
        emoji: '🎯',
        label: context.tr('wrapped.goalsTitle'),
        headline: Text(_money(s.goalsSavedMinor), style: _bigStyle),
        sub: s.goalsCompleted > 0
            ? context.trp('wrapped.goalsDone', {'n': s.goalsCompleted})
            : null,
      )));
    }

    // 9 — Weight change.
    if (s.weightDeltaKg != null && s.weightDeltaKg!.abs() >= 0.5) {
      final d = s.weightDeltaKg!;
      pages.add(_tap(_StatCard(
        gradient: const [Color(0xFF11998E), Color(0xFF38EF7D)],
        emoji: d < 0 ? '📉' : '📈',
        label: context.tr('wrapped.weightTitle'),
        headline: Text(
            context.trp(d < 0 ? 'wrapped.weightLost' : 'wrapped.weightGained',
                {'n': d.abs().toStringAsFixed(1)}),
            style: _midStyle),
      )));
    }

    // 10 — Life Score.
    pages.add(_tap(_StatCard(
      gradient: LifeGradients.money,
      emoji: '⭐',
      label: context.tr('wrapped.scoreTitle'),
      headline: GradientRing(
        progress: s.lifeScore / 100,
        size: 150,
        strokeWidth: 14,
        colors: const [Color(0xFF7BF7FF), Color(0xFF7B5CFF)],
        center: Text('${s.lifeScore}',
            style: const TextStyle(
                fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white)),
      ),
    )));

    // 11 — Life in weeks.
    if (s.percentLived > 0) {
      pages.add(_tap(_StatCard(
        gradient: const [Color(0xFF5B247A), Color(0xFF1BCEDF)],
        emoji: '⏳',
        label: context.tr('wrapped.weeksTitle'),
        headline: AnimatedCounter(
          value: s.percentLived.toDouble(),
          format: (v) => context.trp('wrapped.percent', {'n': v.round()}),
          style: _bigStyle,
        ),
      )));
    }

    // 12 — Shareable summary.
    pages.add(_summaryPage(s));
    return pages;
  }

  /// Wraps a story card so a tap advances to the next page.
  Widget _tap(Widget child) => GestureDetector(onTap: _next, child: child);

  Widget _summaryPage(WrappedStats s) {
    final rows = <(String, String, String)>[
      if (s.incomeMinor > 0 || s.spentMinor > 0)
        (s.netMinor >= 0 ? '💚' : '💸', context.tr('wrapped.lblNet'),
            _money(s.netMinor)),
      if (s.totalSteps > 0)
        ('👟', context.tr('wrapped.lblSteps'), _grouped(s.totalSteps.toDouble())),
      if (s.bestStreak > 0)
        ('🔥', context.tr('wrapped.lblStreak'),
            context.trp('wrapped.days', {'n': s.bestStreak})),
      if (s.moodMonths > 0)
        (moodFace(s.avgMood.round()), context.tr('wrapped.lblMood'),
            s.avgMood.toStringAsFixed(1)),
      ('⭐', context.tr('wrapped.lblScore'), '${s.lifeScore}'),
      if (s.percentLived > 0)
        ('⏳', context.tr('wrapped.lblLived'), '${s.percentLived}%'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: RepaintBoundary(
                key: _shareKey,
                child: ShareCard(
                  emoji: '🌌',
                  kicker: 'LifeOS Wrapped',
                  title: '${s.year}',
                  titleSize: 40,
                  rows: rows,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => shareBoundaryPng(
                      context, _shareKey, 'lifeos_wrapped_${s.year}.png'),
                  icon: const Icon(Icons.ios_share),
                  label: Text(context.tr('wrapped.share')),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(context.tr('wrapped.done'),
                    style: const TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _money(int minor) =>
      Money(minor, currency: AppConstants.defaultCurrency).format();

  String _grouped(double n) => NumberFormat.decimalPattern().format(n.round());
}

const _bigStyle = TextStyle(
  fontSize: 56,
  fontWeight: FontWeight.w900,
  color: Colors.white,
  letterSpacing: -1,
  height: 1.05,
);
const _midStyle = TextStyle(
  fontSize: 34,
  fontWeight: FontWeight.w900,
  color: Colors.white,
  height: 1.1,
);

/// One full-screen bold gradient story card.
/// The first Wrapped page: the year, the tagline, and — when the archive holds
/// more than one year — pills to switch which year you're recapping.
class _IntroCard extends ConsumerWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final years = ref.watch(wrappedAvailableYearsProvider);
    final year = ref.watch(wrappedYearProvider);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7B5CFF), Color(0xFF2A1A5E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌌', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 28),
            Text(
              context.tr('wrapped.introTop').toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 14),
            Text('$year', style: _bigStyle),
            const SizedBox(height: 18),
            Text(
              context.tr('wrapped.introHint'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            if (years.length > 1) ...[
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final y in years)
                    GestureDetector(
                      onTap: () =>
                          ref.read(wrappedYearProvider.notifier).state = y,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: y == year
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$y',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: y == year
                                ? const Color(0xFF2A1A5E)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final List<Color> gradient;
  final String emoji;
  final String label;
  final Widget headline;
  final String? sub;

  const _StatCard({
    required this.gradient,
    required this.emoji,
    required this.label,
    required this.headline,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 28),
            Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 14),
            DefaultTextStyle.merge(
              textAlign: TextAlign.center,
              child: headline,
            ),
            if (sub != null) ...[
              const SizedBox(height: 18),
              Text(
                sub!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

