import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/i18n/locale_controller.dart';
import 'package:lifeos/features/ai/presentation/pages/ai_page.dart';
import 'package:lifeos/features/backup/presentation/pages/backup_page.dart';
import 'package:lifeos/features/cloud/presentation/pages/account_page.dart';
import 'package:lifeos/features/cloud/presentation/providers/cloud_providers.dart';
import 'package:lifeos/features/food/presentation/pages/diet_page.dart';
import 'package:lifeos/features/food/presentation/pages/food_page.dart';
import 'package:lifeos/features/food/presentation/providers/expiry_alert_provider.dart';
import 'package:lifeos/features/money/presentation/providers/budget_limits_providers.dart';
import 'package:lifeos/features/money/presentation/providers/recurring_providers.dart';
import 'package:lifeos/features/history/presentation/pages/history_page.dart';
import 'package:lifeos/features/history/presentation/providers/history_providers.dart';
import 'package:lifeos/features/lifeweeks/presentation/pages/life_weeks_page.dart';
import 'package:lifeos/features/achievements/domain/achievement.dart';
import 'package:lifeos/features/achievements/presentation/pages/achievements_page.dart';
import 'package:lifeos/features/achievements/presentation/providers/achievements_providers.dart';
import 'package:lifeos/features/appearance/presentation/pages/appearance_page.dart';
import 'package:lifeos/features/coach/presentation/pages/coach_page.dart';
import 'package:lifeos/features/insights/presentation/pages/insights_page.dart';
import 'package:lifeos/features/wrapped/presentation/pages/wrapped_page.dart';
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
import 'package:lifeos/features/monetization/presentation/providers/pro_providers.dart';
import 'package:lifeos/features/money/presentation/pages/money_page.dart';
import 'package:lifeos/features/notifications/presentation/pages/notifications_page.dart';
import 'package:lifeos/features/notifications/presentation/providers/notification_providers.dart';
import 'package:lifeos/features/reminders/presentation/pages/reminders_page.dart';
import 'package:lifeos/features/security/presentation/pages/security_settings_page.dart';
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
    return Scaffold(
      body: IndexedStack(index: index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(homeTabProvider.notifier).state = i,
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

/// Hub for the remaining modules (Food, Mind, AI, Notifications) + settings.
class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
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
        color: const Color(0xFF7B5CFF),
        child: ListView(
        padding: const EdgeInsets.only(top: 10, bottom: 24),
        children: [
          _tile(context, '👤', context.tr('profile.title'),
              context.tr('more.profileSub'), const ProfilePage()),
          Builder(builder: (context) {
            final sex = ref.watch(profileProvider)?.sex;
            final isFemale = sex == Sex.female;
            return _tile(
              context,
              isFemale ? '🌸' : '⚡',
              context.tr(sex == null
                  ? 'wellness.title'
                  : isFemale
                      ? 'cycle.title'
                      : 'vitality.title'),
              context.tr('wellness.moreSub'),
              const WellnessPage(),
            );
          }),
          _tile(context, '🥦', context.tr('diet.title'),
              context.tr('more.dietSub'), const DietPage()),
          _tile(context, '🥗', context.tr('more.food'),
              context.tr('more.foodSub'), const FoodPage()),
          _tile(context, '🧠', context.tr('mind.title'),
              context.tr('more.mindSub'), const MindPage()),
          _tile(context, '📔', context.tr('mood.title'),
              context.tr('mood.moreSub'), const MoodJournalPage()),
          _tile(context, '🤖', context.tr('ai.title'),
              context.tr('more.aiSub'), const AiPage()),
          _tile(context, '💬', context.tr('coach.title'),
              context.tr('coach.moreSub'), const CoachPage()),
          _tile(
            context,
            '🔔',
            context.tr('notif.title'),
            unread > 0
                ? context.trp('more.notifUnread', {'n': unread})
                : context.tr('more.notifAllRead'),
            const NotificationsPage(),
            trailing: unread > 0
                ? Badge(label: Text('$unread'))
                : const Icon(Icons.chevron_right),
          ),
          _tile(context, '⏰', context.tr('reminder.title'),
              context.tr('reminder.moreSub'), const RemindersPage()),
          _tile(context, '📊', context.tr('report.title'),
              context.tr('report.moreSub'), const ReportPage()),
          _tile(context, '📜', context.tr('hist.title'),
              context.tr('hist.moreSub'), const HistoryPage()),
          _tile(context, '⏳', context.tr('weeks.title'),
              context.tr('weeks.moreSub'), const LifeWeeksPage()),
          _tile(context, '✨', context.tr('wrapped.title'),
              context.tr('wrapped.moreSub'), const WrappedPage()),
          _tile(context, '🔮', context.tr('insight.title'),
              context.tr('insight.moreSub'), const InsightsPage()),
          _tile(
            context,
            '🏅',
            context.tr('ach.title'),
            context.trp('ach.unlockedOf', {
              'n': ref.watch(achievementsUnlockedProvider),
              'total': const AchievementEngine().total,
            }),
            const AchievementsPage(),
          ),
          const SizedBox(height: 6),
          _glass(Builder(builder: (context) {
            final status = ref.watch(cloudSyncStatusProvider);
            final email = ref.watch(accountEmailProvider);
            return ListTile(
              leading: Icon(
                status.configured ? Icons.cloud_done : Icons.cloud_off,
                size: 26,
              ),
              title: Text(context.tr('cloud.title')),
              subtitle: Text(
                !status.configured
                    ? context.tr('cloud.notConfigured')
                    : email ??
                        context.trp('cloud.status', {
                          'ok': status.synced,
                          'fail': status.failed,
                        }),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AccountPage()),
              ),
            );
          })),
          _tile(context, '💾', context.tr('backup.title'),
              context.tr('backup.moreSub'), const BackupPage()),
          _tile(context, '🔒', context.tr('sec.title'),
              context.tr('sec.moreSub'), const SecuritySettingsPage()),
          _glass(ListTile(
            leading: const Text('⭐', style: TextStyle(fontSize: 26)),
            title: Text(context.tr('pro.title')),
            subtitle: Text(ref.watch(isProProvider)
                ? context.tr('more.proActive')
                : context.tr('more.proFree')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProPage()),
            ),
          )),
          _tile(context, '🎨', context.tr('theme.title'),
              context.tr('theme.moreSub'), const AppearancePage()),
          _glass(ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, size: 26),
            title: Text(context.tr('privacy.title')),
            subtitle: Text(context.tr('privacy.moreSub')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPrivacySheet(context),
          )),
          _glass(ListTile(
            leading: const Icon(Icons.description_outlined, size: 26),
            title: Text(context.tr('oss.title')),
            subtitle: Text(context.tr('oss.moreSub')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Lumo',
              applicationVersion: '0.1.0',
            ),
          )),
          _glass(ListTile(
            leading: const Icon(Icons.language),
            title: Text(context.tr('more.language')),
            subtitle: Text(_currentLanguageLabel(context, ref)),
            onTap: () => _pickLanguage(context, ref),
          )),
        ],
        ),
      ),
    );
  }

  String _currentLanguageLabel(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    if (locale == null) return context.tr('lang.system');
    return context.tr('lang.${locale.languageCode}');
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

  Widget _tile(
    BuildContext context,
    String emoji,
    String title,
    String subtitle,
    Widget page, {
    Widget? trailing,
  }) {
    return GlassCard(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: EdgeInsets.zero,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => page),
      ),
      child: ListTile(
        leading: Text(emoji, style: const TextStyle(fontSize: 26)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing ?? const Icon(Icons.chevron_right),
      ),
    );
  }

  /// Frames an arbitrary settings [tile] in the same glass card the module
  /// tiles use, so the whole hub reads as one consistent surface.
  Widget _glass(Widget tile) => GlassCard(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        padding: EdgeInsets.zero,
        child: tile,
      );
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
