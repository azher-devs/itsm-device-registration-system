// Shared information card for device and employee details.

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Displays validated or empty device and employee information.
class InfoCard extends StatelessWidget {
  /// Creates a populated information card.
  const InfoCard({
    required this.title,
    required this.icon,
    required this.rows,
    super.key,
    this.isValidated = true,
  }) : _emptyMessage = null;

  /// Creates an empty-state card before validation data exists.
  const InfoCard.empty({
    required this.title,
    required this.icon,
    required String message,
    super.key,
  }) : rows = const [],
       isValidated = false,
       _emptyMessage = message;

  /// Section title shown at the top of the card.
  final String title;

  /// Icon that identifies the information category.
  final IconData icon;

  /// Label/value pairs displayed after validation.
  final List<InfoRow> rows;

  /// Controls whether row data or an empty message is shown.
  final bool isValidated;

  /// Empty-state copy shown before validation.
  final String? _emptyMessage;

  /// Builds the card using the same layout for device and employee details.
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isValidated
        ? (isDark ? AppTheme.darkSurfaceVariant : AppTheme.lightBlue)
        : colorScheme.surface;
    final iconBackground = isDark ? AppTheme.darkSurface : Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: iconBackground,
                child: Icon(icon, color: AppTheme.primaryBlue, size: 25),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // The same card supports both a validated and pre-validation state.
                    if (isValidated)
                      ...rows.map(
                        (row) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _InfoLine(row: row),
                        ),
                      )
                    else
                      Text(
                        _emptyMessage ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                  ],
                ),
              ),
              if (isValidated)
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: AppTheme.successSoft,
                  child: Icon(Icons.check, color: AppTheme.success, size: 16),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Label/value model rendered by [InfoCard].
class InfoRow {
  const InfoRow(this.label, this.value);

  /// Small label that describes the value.
  final String label;

  /// Display value shown under the label.
  final String value;
}

/// Renders one label/value pair inside an information card.
class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.row});

  /// Row data displayed by this line.
  final InfoRow row;

  /// Builds a compact vertical label/value pair.
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          row.label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          row.value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
