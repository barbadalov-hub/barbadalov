import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/ai/presentation/pages/ai_page.dart';
import 'package:lifeos/features/appearance/presentation/pages/appearance_page.dart';
import 'package:lifeos/features/achievements/presentation/pages/achievements_page.dart';
import 'package:lifeos/features/backup/presentation/pages/backup_page.dart';
import 'package:lifeos/features/coach/presentation/pages/coach_page.dart';
import 'package:lifeos/features/food/presentation/pages/diet_page.dart';
import 'package:lifeos/features/food/presentation/pages/food_page.dart';
import 'package:lifeos/features/health/presentation/pages/workouts_page.dart';
import 'package:lifeos/features/health/presentation/providers/health_providers.dart';
import 'package:lifeos/features/history/presentation/pages/history_page.dart';
import 'package:lifeos/features/home/presentation/providers/home_tab_provider.dart';
import 'package:lifeos/features/insights/presentation/pages/insights_page.dart';
import 'package:lifeos/features/lifeweeks/presentation/pages/life_weeks_page.dart';
import 'package:lifeos/features/mind/presentation/pages/mind_page.dart';
import 'package:lifeos/features/mind/presentation/pages/mood_journal_page.dart';
import 'package:lifeos/features/money/presentation/widgets/add_transaction_sheet.dart';
import 'package:lifeos/features/notifications/presentation/pages/notifications_page.dart';
import 'package:lifeos/features/profile/presentation/pages/profile_page.dart';
import 'package:lifeos/features/reminders/presentation/pages/reminders_page.dart';
import 'package:lifeos/features/reports/presentation/pages/report_page.dart';
import 'package:lifeos/features/search/domain/command_catalog.dart';
import 'package:lifeos/features/security/presentation/pages/security_settings_page.dart';
import 'package:lifeos/features/wrapped/presentation/pages/wrapped_page.dart';

/// Command palette: type to fuzzily jump to any section or run a quick action.
class CommandPalette extends ConsumerStatefulWidget {
  const CommandPalette({super.key});

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  MaterialPageRoute<void> _route(Widget page) =>
      MaterialPageRoute<void>(builder: (_) => page);

  void _openTab(NavigatorState nav, int index) {
    ref.read(homeTabProvider.notifier).state = index;
    nav.pop();
  }

  Widget? _pageFor(String id) => switch (id) {
        'food' => const FoodPage(),
        'diet' => const DietPage(),
        'mind' => const MindPage(),
        'mood' || 'act_mood' => const MoodJournalPage(),
        'workouts' => const WorkoutsPage(),
        'ai' => const AiPage(),
        'coach' => const CoachPage(),
        'insights' => const InsightsPage(),
        'achievements' => const AchievementsPage(),
        'wrapped' => const WrappedPage(),
        'lifeweeks' => const LifeWeeksPage(),
        'history' => const HistoryPage(),
        'reminders' => const RemindersPage(),
        'report' => const ReportPage(),
        'notifications' => const NotificationsPage(),
        'profile' => const ProfilePage(),
        'appearance' => const AppearancePage(),
        'backup' => const BackupPage(),
        'security' => const SecuritySettingsPage(),
        _ => null,
      };

  void _run(Command c) {
    final nav = Navigator.of(context);
    switch (c.id) {
      case 'act_water':
        ref.read(logHealthProvider).addWater();
        final msg = context.tr('search.doneWater');
        nav.pop();
        ScaffoldMessenger.of(nav.context)
            .showSnackBar(SnackBar(content: Text(msg)));
        return;
      case 'act_expense':
        nav.pop();
        AddTransactionSheet.show(nav.context);
        return;
      case 'nav_today':
        _openTab(nav, 0);
        return;
      case 'nav_money':
        _openTab(nav, 1);
        return;
      case 'nav_health':
        _openTab(nav, 2);
        return;
      case 'nav_goals':
        _openTab(nav, 3);
        return;
      case 'nav_more':
        _openTab(nav, 4);
        return;
    }
    final page = _pageFor(c.id);
    if (page != null) nav.pushReplacement(_route(page));
  }

  List<Command> _results() {
    final scored = <(Command, int, int)>[];
    for (var i = 0; i < kCommands.length; i++) {
      final c = kCommands[i];
      final s = commandScore(_query, context.tr(c.titleKey), c.keywords);
      if (s > 0) scored.add((c, s, i));
    }
    scored.sort((a, b) {
      final byScore = b.$2.compareTo(a.$2);
      return byScore != 0 ? byScore : a.$3.compareTo(b.$3);
    });
    return [for (final e in scored) e.$1];
  }

  @override
  Widget build(BuildContext context) {
    final results = _results();
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: context.tr('search.hint'),
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _query = v),
          onSubmitted: (_) {
            if (results.isNotEmpty) _run(results.first);
          },
        ),
      ),
      body: results.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(context.tr('search.empty'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge),
              ),
            )
          : ListView.builder(
              itemCount: results.length,
              itemBuilder: (_, i) {
                final c = results[i];
                final isAction = c.kind == CommandKind.action;
                return ListTile(
                  leading: Text(c.emoji, style: const TextStyle(fontSize: 24)),
                  title: Text(context.tr(c.titleKey)),
                  subtitle: isAction ? Text(context.tr('search.action')) : null,
                  trailing: Icon(
                    isAction ? Icons.bolt : Icons.north_east,
                    size: 18,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  onTap: () => _run(c),
                );
              },
            ),
    );
  }
}
