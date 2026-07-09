import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/profile/domain/entities/user_profile.dart';
import 'package:lifeos/features/profile/presentation/pages/profile_page.dart';
import 'package:lifeos/features/profile/presentation/providers/profile_providers.dart';
import 'package:lifeos/features/wellness/presentation/pages/cycle_page.dart';
import 'package:lifeos/features/wellness/presentation/pages/vitality_page.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';

/// Routes to the right personal tracker based on the profile's sex: a menstrual
/// cycle tracker for women, a daily "vitality" tracker for men. If there's no
/// profile yet, it asks the user to create one first (that's where sex is set).
class WellnessPage extends ConsumerWidget {
  const WellnessPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    if (profile == null) return const _NeedsProfile();
    return profile.sex == Sex.female ? const CyclePage() : const VitalityPage();
  }
}

class _NeedsProfile extends StatelessWidget {
  const _NeedsProfile();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('wellness.title'))),
      body: AnimatedBackdrop(
        style: BackdropStyle.orbs,
        color: const Color(0xFFF5576C),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🌸', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(context.tr('wellness.needsProfile'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(context.tr('wellness.needsProfileSub'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const ProfilePage()),
                  ),
                  icon: const Icon(Icons.person),
                  label: Text(context.tr('wellness.fillProfile')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
