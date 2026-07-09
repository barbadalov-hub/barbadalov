import 'package:flutter/material.dart';

/// A GitHub-style contribution grid of habit completions: one column per week
/// (oldest→newest), one cell per weekday. Filled cells = completed days.
class HabitHeatmap extends StatelessWidget {
  final List<DateTime> completedDates;
  final DateTime now;
  final Color color;
  final int weeks;

  const HabitHeatmap({
    required this.completedDates,
    required this.now,
    required this.color,
    this.weeks = 15,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final done = {for (final d in completedDates) _dateOnly(d)};
    final today = _dateOnly(now);
    final thisMonday = today.subtract(Duration(days: now.weekday - 1));
    final startMonday = thisMonday.subtract(Duration(days: (weeks - 1) * 7));
    final empty = Theme.of(context).colorScheme.surfaceContainerHighest;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var w = 0; w < weeks; w++)
            Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Column(
                children: [
                  for (var d = 0; d < 7; d++)
                    Builder(builder: (_) {
                      final date =
                          startMonday.add(Duration(days: w * 7 + d));
                      final future = date.isAfter(today);
                      final filled = !future && done.contains(date);
                      return Container(
                        width: 13,
                        height: 13,
                        margin: const EdgeInsets.only(bottom: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: future
                              ? Colors.transparent
                              : filled
                                  ? color
                                  : empty.withValues(alpha: 0.5),
                        ),
                      );
                    }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
