import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/i18n/locale_controller.dart';
import 'package:lifeos/features/ai/presentation/pages/ai_page.dart';
import 'package:lifeos/features/backup/presentation/pages/backup_page.dart';
import 'package:lifeos/features/cloud/presentation/pages/account_page.dart';
import 'package:lifeos/features/food/presentation/pages/diet_page.dart';
import 'package:lifeos/features/food/presentation/pages/food_page.dart';
import 'package:lifeos/features/food/presentation/providers/expiry_alert_provider.dart';
import 'package:lifeos/features/money/presentation/providers/budget_limits_providers.dart';
import 'package:lifeos/features/money/presentation/providers/recurring_providers.dart';
import 'package:lifeos/features/history/presentation/pages/history_page.dart';
import 'package:lifeos/features/history/presentation/providers/history_providers.dart';
import 'package:lifeos/features/lifeweeks/presentation/pages/life_weeks_page.dart';
import 'package:lifeos/features/achievements/presentation/pages/achievements_page.dart';
import 'package:lifeos/features/achievements/presentation/providers/achievements_providers.dart';
import 'package:lifeos/features/appearance/presentation/pages/appearance_page.dart';
import 'package:lifeos/features/coach/presentation/pages/coach_page.dart';
import 'package:lifeos/features/insights/presentation/pages/insights_page.dart';
import 'package:lifeos/features/wrapped/presentation/pages/wrapped_page.dart';
import 'package:lifeos/features/reports/presentation/pages/forecast_page.dart';
import 'package:lifeos/features/reports/presentation/pages/report_page.dart';
import 'package:lifeos/features/reports/presentation/providers/report_providers.dart';
import 'package:lifeos/features/profile/domain/entities/user_profile.dart';
import 'package:lifeos/features/profile/presentation/pages/profile_page.dart';
import 'package:lifeos/features/profile/presentation/providers/profile_providers.dart';
import 'package:lifeos/features/wellness/presentation/pages/wellness_page.dart';
import 'package:lifeos/features/wellness/presentation/providers/wellness_providers.dart';
import 'package:lifeos/features/goals/presentation/pages/goals_page.dart';
import 'package:lifeos/features/health/presentation/pages/health_page.dart';
import 'package:lifeos/features/home/presentation/pages/today_page.dart';
import 'package:lifeos/features/home/presentation/providers/home_tab_provider.dart';
import 'package:lifeos/features/search/presentation/pages/command_palette.dart';
import 'package:lifeos/features/mind/presentation/pages/mind_page.dart';
import 'package:lifeos/features/mind/presentation/pages/mood_journal_page.dart';
import 'package:lifeos/features/monetization/presentation/pages/pro_page.dart';
import 'package:lifeos/features/money/presentation/pages/money_page.dart';
import 'package:lifeos/features/notifications/presentation/pages/notifications_page.dart';
import 'package:lifeos/features/notifications/presentation/providers/notification_providers.dart';
import 'package:lifeos/features/onboarding/presentation/pages/guide_page.dart';
import 'package:lifeos/features/reminders/presentation/pages/reminders_page.dart';
import 'package:lifeos/features/security/presentation/pages/security_settings_page.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/shared/widgets/glass_card.dart';

/// Root navigation. Five primary destinations; the "More" hub reaches the rest.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  static const _pages = [
    TodayPage(),
    MoneyPage(),
    HealthPage(),
    GoalsPage(),
    MorePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(homeTabProvider);
    // Keep the background services alive for the whole session: pantry-expiry
    // alerts, category over-limit alerts, recurring-transaction posting, and the
    // weekend weekly-report push.
    ref.watch(expiryAlertServiceProvider);
    ref.watch(budgetAlertServiceProvider);
    ref.watch(recurringMaterializerProvider);
    ref.watch(weeklyReportServiceProvider);
    ref.watch(cyclePeriodAlertServiceProvider);
    // Archive each completed month so the life timeline grows over the years.
    ref.watch(historyArchiveServiceProvider);
    // Celebrate newly earned achievements with a push + feed entry.
    ref.watch(achievementAlertServiceProvider);
    // App-level unread badge (Telegram-style): visible from any tab so you
    // never miss that "something arrived", even away from the notifications hub.
    final unread = ref.watch(unreadCountProvider);
    // Each tab tints the selection pill with its screen's pillar colour, so the
    // nav bar feels tied to wherever you are.
    const pillars = [
      Color(0xFF3BA7FF), // Today
      LifeColors.finance, // Money
      LifeColors.health, // Health
      LifeColors.goals, // Goals
      LifeColors.mind, // More
    ];
    final accent = pillars[index];
    return Scaffold(
      body: IndexedStack(index: index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(homeTabProvider.notifier).state = i,
        indicatorColor: accent.withValues(alpha: 0.20),
        surfaceTintColor: Colors.transparent,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.today_outlined),
            selectedIcon: const Icon(Icons.today),
            label: context.tr('nav.today'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet),
            label: context.tr('nav.money'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_outline),
            selectedIcon: const Icon(Icons.favorite),
            label: context.tr('nav.health'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.flag_outlined),
            selectedIcon: const Icon(Icons.flag),
            label: context.tr('nav.goals'),
          ),
          NavigationDestination(
            icon: _maybeBadge(unread, const Icon(Icons.grid_view_outlined)),
            selectedIcon: _maybeBadge(unread, const Icon(Icons.grid_view)),
            label: context.tr('nav.more'),
          ),
        ],
      ),
    );
  }

  /// Wraps [icon] in a count badge when there are unread notifications; caps the
  /// label at 99+ so it stays readable.
  Widget _maybeBadge(int unread, Widget icon) {
    if (unread <= 0) return icon;
    return Badge(
      label: Text(unread > 99 ? '99+' : '$unread'),
      child: icon,
    );
  }
}

/// Hub for everything outside the four primary tabs. Kept compact: the ~20
/// modules are grouped into a handful of categories, each opening a bottom
/// sheet — so the hub reads as a short, scannable list instead of a long wall
/// of tiles. The tutorial sits on top as its own card.
class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    final sex = ref.watch(profileProvider)?.sex;
    final wellnessEmoji = sex == Sex.female ? '🌸' : '⚡';
    final wellnessTitle = context.tr(sex == null
        ? 'wellness.title'
        : sex == Sex.female
            ? 'cycle.title'
            : 'vitality.title');

    // Push a full page from a More entry.
    _MoreEntry page(String emoji, String title, Widget target,
            {Widget? trailing}) =>
        _MoreEntry(
          emoji: emoji,
          title: title,
          trailing: trailing,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => target),
          ),
        );

    final cats = <_MoreCat>[
      _MoreCat('🧑', context.tr('moreCat.you'), [
        page('👤', context.tr('profile.title'), const ProfilePage()),
        page(wellnessEmoji, wellnessTitle, const WellnessPage()),
      ]),
      _MoreCat('🥗', context.tr('moreCat.body'), [
        page('🥦', context.tr('diet.title'), const DietPage()),
        page('🍎', context.tr('more.food'), const FoodPage()),
        page('🧠', context.tr('mind.title'), const MindPage()),
        page('📔', context.tr('mood.title'), const MoodJournalPage()),
      ]),
      _MoreCat('🤖', context.tr('moreCat.ai'), [
        page('🤖', context.tr('ai.title'), const AiPage()),
        page('💬', context.tr('coach.title'), const CoachPage()),
      ]),
      _MoreCat('🔔', context.tr('moreCat.signals'), [
        page('🔔', context.tr('notif.title'), const NotificationsPage(),
            trailing: unread > 0 ? Badge(label: Text('$unread')) : null),
        page('⏰', context.tr('reminder.title'), const RemindersPage()),
      ], badge: unread),
      _MoreCat('📊', context.tr('moreCat.progress'), [
        page('🔮', context.tr('forecast.title'), const ForecastPage()),
        page('📊', context.tr('report.title'), const ReportPage()),
        page('📜', context.tr('hist.title'), const HistoryPage()),
        page('⏳', context.tr('weeks.title'), const LifeWeeksPage()),
        page('✨', context.tr('wrapped.title'), const WrappedPage()),
        page('🔮', context.tr('insight.title'), const InsightsPage()),
        page('🏅', context.tr('ach.title'), const AchievementsPage()),
      ]),
      _MoreCat('🔐', context.tr('moreCat.account'), [
        page('☁️', context.tr('cloud.title'), const AccountPage()),
        page('💾', context.tr('backup.title'), const BackupPage()),
        page('🔒', context.tr('sec.title'), const SecuritySettingsPage()),
        page('⭐', context.tr('pro.title'), const ProPage()),
      ]),
      _MoreCat('⚙️', context.tr('moreCat.settings'), [
        page('🎨', context.tr('theme.title'), const AppearancePage()),
        _MoreEntry(
          emoji: '🌐',
          title: context.tr('more.language'),
          onTap: () => _pickLanguage(context, ref),
        ),
        _MoreEntry(
          emoji: '🔏',
          title: context.tr('privacy.title'),
          onTap: () => _showPrivacySheet(context),
        ),
        _MoreEntry(
          emoji: '📄',
          title: context.tr('oss.title'),
          onTap: () => showLicensePage(
            context: context,
            applicationName: 'Lumo',
            applicationVersion: '0.1.0',
          ),
        ),
      ]),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('nav.more')),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: context.tr('search.title'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CommandPalette()),
            ),
          ),
        ],
      ),
      body: AnimatedBackdrop(
        style: BackdropStyle.galaxy,
        color: const Color(0xFF4E63E6),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            const _GuideCard(),
            const SizedBox(height: 10),
            for (final cat in cats) _CategoryCard(cat: cat),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(localeProvider.notifier);
    await showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(ctx.tr('more.chooseLanguage')),
        children: [
          _langOption(ctx, controller, null, ctx.tr('lang.system')),
          _langOption(ctx, controller, const Locale('en'), ctx.tr('lang.en')),
          _langOption(ctx, controller, const Locale('ru'), ctx.tr('lang.ru')),
          _langOption(ctx, controller, const Locale('uk'), ctx.tr('lang.uk')),
        ],
      ),
    );
  }

  Widget _langOption(
    BuildContext context,
    LocaleController controller,
    Locale? locale,
    String label,
  ) {
    return SimpleDialogOption(
      onPressed: () {
        controller.setLocale(locale);
        Navigator.pop(context);
      },
      child: Text(label),
    );
  }
}

/// One selectable module inside a category sheet.
class _MoreEntry {
  final String emoji;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;
  const _MoreEntry({
    required this.emoji,
    required this.title,
    required this.onTap,
    this.trailing,
  });
}

/// A group of related modules, surfaced as a single card that opens a sheet.
class _MoreCat {
  final String emoji;
  final String title;
  final List<_MoreEntry> items;
  final int badge;
  const _MoreCat(this.emoji, this.title, this.items, {this.badge = 0});
}

/// Prominent, always-first entry that opens the full app tutorial.
class _GuideCard extends StatelessWidget {
  const _GuideCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      padding: EdgeInsets.zero,
      onTap: () => GuidePage.open(context),
      child: ListTile(
        leading: const Text('🎓', style: TextStyle(fontSize: 26)),
        title: Text(context.tr('tour.title')),
        subtitle: Text(context.tr('tour.moreSub')),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

/// A category row. Tapping it opens a compact bottom sheet with the modules
/// inside — so the hub stays short and each group is one tap away.
class _CategoryCard extends StatelessWidget {
  final _MoreCat cat;
  const _CategoryCard({required this.cat});

  @override
  Widget build(BuildContext context) {
    final subtitle = cat.items.map((e) => e.title).join(' · ');
    Widget leading = Text(cat.emoji, style: const TextStyle(fontSize: 26));
    if (cat.badge > 0) {
      leading = Badge(label: Text('${cat.badge}'), child: leading);
    }
    return GlassCard(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      padding: EdgeInsets.zero,
      onTap: () => _open(context),
      child: ListTile(
        leading: leading,
        title: Text(cat.title),
        subtitle:
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  void _open(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Text(cat.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Text(cat.title,
                      style: Theme.of(sheetCtx).textTheme.titleLarge),
                ],
              ),
            ),
            for (final e in cat.items)
              ListTile(
                leading: Text(e.emoji, style: const TextStyle(fontSize: 24)),
                title: Text(e.title),
                trailing: e.trailing ?? const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  e.onTap();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Compact privacy summary shown as a draggable bottom sheet (no full page),
/// keeping the settings hub uncluttered. The full policy also ships in
/// docs/PRIVACY.md for the store listing.
void _showPrivacySheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.68,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (ctx, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
        children: [
          Text(ctx.tr('privacy.title'),
              style: Theme.of(ctx).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(ctx.tr('privacy.body'),
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.5)),
        ],
      ),
    ),
  );
}
