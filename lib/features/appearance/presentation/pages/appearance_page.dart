import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/shared/theme/theme_controller.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/shared/widgets/gradient_card.dart';

/// Appearance settings: pick a cosmos accent palette and the light/dark mode.
/// Changes apply live because the root [MaterialApp] watches the theme provider.
class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider);
    final controller = ref.read(themeSettingsProvider.notifier);
    final accent = settings.accent;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('theme.title'))),
      body: AnimatedBackdrop(
        style: BackdropStyle.galaxy,
        color: accent.seed,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Live preview.
            GradientCard(
              colors: accent.gradient,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🌌 ${context.tr('theme.previewTitle')}',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(context.tr(accent.nameKey),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9))),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: accent.gradient.last,
                        ),
                        onPressed: () {},
                        child: Text(context.tr('theme.sample')),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.favorite, color: Colors.white),
                      const SizedBox(width: 8),
                      Switch(value: true, onChanged: (_) {}),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Mode. The cosmos design is dark-only (dark galaxy backdrops), so
            // there is no light/system option — just a note.
            Text(context.tr('theme.mode'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.dark_mode, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(context.tr('theme.darkOnly'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          )),
                ),
              ],
            ),
            const SizedBox(height: 26),

            // Accent swatches.
            Text(context.tr('theme.accent'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final a in kAccents)
                  _Swatch(
                    palette: a,
                    selected: a.id == settings.accentId,
                    onTap: () => controller.setAccent(a.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final AccentPalette palette;
  final bool selected;
  final VoidCallback onTap;
  const _Swatch(
      {required this.palette, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: palette.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.white : Colors.white24,
                width: selected ? 3 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: palette.seed.withValues(alpha: 0.6),
                        blurRadius: 16,
                      )
                    ]
                  : null,
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.white, size: 28)
                : null,
          ),
          const SizedBox(height: 6),
          Text(context.tr(palette.nameKey),
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
