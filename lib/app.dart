import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/constants/app_constants.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/i18n/locale_controller.dart';
import 'package:lifeos/features/home/presentation/pages/home_shell.dart';
import 'package:lifeos/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:lifeos/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:lifeos/features/security/presentation/pages/lock_screen.dart';
import 'package:lifeos/features/security/presentation/providers/security_providers.dart';
import 'package:lifeos/shared/providers/core_providers.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:lifeos/shared/theme/theme_controller.dart';
import 'package:lifeos/shared/widgets/splash_screen.dart';

/// How long the cosmos splash is held at boot. Overridden to [Duration.zero] in
/// widget tests so they reach the app without waiting.
final splashDurationProvider =
    Provider<Duration>((_) => const Duration(milliseconds: 1500));

/// Root widget. Reading [coreEngineProvider] here boots the event pipeline for
/// the whole app lifetime before any screen can emit an event.
class LifeOsApp extends ConsumerWidget {
  const LifeOsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Bring the LifeCoreEngine online at startup.
    ref.watch(coreEngineProvider);
    final locale = ref.watch(localeProvider);
    final theme = ref.watch(themeSettingsProvider);
    final seed = theme.accent.seed;

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(seed),
      darkTheme: AppTheme.dark(seed),
      themeMode: theme.mode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: _SplashGate(
        child: ref.watch(onboardingDoneProvider)
            ? const _AppLock(child: HomeShell())
            : const OnboardingPage(),
      ),
    );
  }
}

/// Holds the cosmos [SplashScreen] for [splashDurationProvider], then cross-
/// fades to the app. The duration is a provider so tests can zero it out.
class _SplashGate extends ConsumerStatefulWidget {
  final Widget child;
  const _SplashGate({required this.child});

  @override
  ConsumerState<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends ConsumerState<_SplashGate> {
  bool _ready = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(ref.read(splashDurationProvider), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: _ready
          ? KeyedSubtree(key: const ValueKey('app'), child: widget.child)
          : const SplashScreen(key: ValueKey('splash')),
    );
  }
}

/// Gates the app behind the PIN when app-lock is on. Re-locks whenever the app
/// goes to the background.
class _AppLock extends ConsumerStatefulWidget {
  final Widget child;
  const _AppLock({required this.child});

  @override
  ConsumerState<_AppLock> createState() => _AppLockState();
}

class _AppLockState extends ConsumerState<_AppLock>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused &&
        ref.read(pinEnabledProvider)) {
      ref.read(appLockedProvider.notifier).state = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = ref.watch(pinEnabledProvider) && ref.watch(appLockedProvider);
    if (locked) {
      return LockScreen(
        onUnlock: () => ref.read(appLockedProvider.notifier).state = false,
      );
    }
    return widget.child;
  }
}
