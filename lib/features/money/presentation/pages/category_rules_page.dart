import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/presentation/providers/category_rules_providers.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/shared/widgets/section_card.dart';

/// Manage keyword → category rules used to auto-categorize receipts & imports.
class CategoryRulesPage extends ConsumerStatefulWidget {
  const CategoryRulesPage({super.key});

  @override
  ConsumerState<CategoryRulesPage> createState() => _CategoryRulesPageState();
}

class _CategoryRulesPageState extends ConsumerState<CategoryRulesPage> {
  final _keyword = TextEditingController();
  String _categoryId = DefaultCategories.food.id;

  @override
  void dispose() {
    _keyword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rules = ref.watch(categoryRulesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('rules.title'))),
      body: AnimatedBackdrop(
        style: BackdropStyle.coins,
        color: LifeColors.finance,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(context.tr('rules.intro'),
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _keyword,
                    decoration: InputDecoration(
                      labelText: context.tr('rules.keyword'),
                      hintText: 'Groceries, Netflix, Uber…',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _categoryId,
                    decoration: InputDecoration(
                      labelText: context.tr('money.category'),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      for (final c in DefaultCategories.all)
                        DropdownMenuItem(
                            value: c.id,
                            child: Text('${c.emoji} ${context.tr('cat.${c.id}')}')),
                    ],
                    onChanged: (v) => setState(() => _categoryId = v ?? _categoryId),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(context.tr('rules.add')),
                      onPressed: () {
                        ref
                            .read(categoryRulesProvider.notifier)
                            .add(_keyword.text, _categoryId);
                        _keyword.clear();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (rules.isEmpty)
              Center(child: Text(context.tr('rules.empty')))
            else
              for (final r in rules)
                Card(
                  child: ListTile(
                    leading: Text(DefaultCategories.byId(r.categoryId).emoji,
                        style: const TextStyle(fontSize: 24)),
                    title: Text('"${r.keyword}"'),
                    subtitle: Text('→ ${context.tr('cat.${r.categoryId}')}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () =>
                          ref.read(categoryRulesProvider.notifier).remove(r.id),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
