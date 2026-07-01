// Shared summary table for completed workflows.

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Displays final registration details in a compact summary table.
class SummaryTable extends StatelessWidget {
  const SummaryTable({required this.rows, super.key});

  /// Ordered rows shown in the summary.
  final List<SummaryRow> rows;

  /// Builds bordered rows that match the success screen design.
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tableColor = isDark
        ? AppTheme.darkSurfaceVariant
        : AppTheme.lightBlue;
    final borderColor = colorScheme.outlineVariant;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tableColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            for (final row in rows)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: borderColor)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 15,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          row.label,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          row.value,
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Label/value model used by the success summary table.
class SummaryRow {
  const SummaryRow(this.label, this.value);

  /// Text shown in the left column.
  final String label;

  /// Text shown in the right column.
  final String value;
}
