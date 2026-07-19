import 'package:flutter/material.dart';

/// A section that collapses to just its title, keeping busy screens short by
/// default. Optional [onAdd] shows a filled-tonal + on the header. Secondary or
/// advanced content typically starts collapsed ([initiallyExpanded] = false).
class CollapsibleSection extends StatelessWidget {
  final String title;
  final VoidCallback? onAdd;
  final List<Widget> children;
  final bool initiallyExpanded;
  const CollapsibleSection({
    super.key,
    required this.title,
    required this.children,
    this.onAdd,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      // Drop the default divider lines ExpansionTile draws.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        controlAffinity: ListTileControlAffinity.leading,
        initiallyExpanded: initiallyExpanded,
        title: Text(title, style: Theme.of(context).textTheme.titleLarge),
        trailing: onAdd != null
            ? IconButton.filledTonal(
                onPressed: onAdd, icon: const Icon(Icons.add))
            : null,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
