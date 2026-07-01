// Registration success confirmation screen.

import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/placeholder_data.dart';
import '../../shared/widgets/mobile_page.dart';
import '../../shared/widgets/primary_action_button.dart';
import '../../shared/widgets/summary_table.dart';

/// Final confirmation screen shown after submitting registration.
class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  /// Builds the success message, summary table, and return actions.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = (MediaQuery.sizeOf(context).height * 0.06).clamp(
      28.0,
      52.0,
    );

    return Scaffold(
      body: SafeArea(
        child: MobilePage(
          maxWidth: 520,
          padding: EdgeInsets.fromLTRB(22, topPadding, 22, 24),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 48,
                backgroundColor: AppTheme.successSoft,
                child: Icon(Icons.check, color: AppTheme.success, size: 46),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.success,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.deviceRegisteredSuccessfully,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 30),
              // Summary rows use placeholder data until backend responses are connected.
              SummaryTable(
                rows: [
                  SummaryRow(l10n.tagNumber, PlaceholderDeviceData.tagNumber),
                  SummaryRow(
                    l10n.serialNumber,
                    PlaceholderDeviceData.serialNumber,
                  ),
                  SummaryRow(l10n.brand, PlaceholderDeviceData.brand),
                  SummaryRow(l10n.deviceType, PlaceholderDeviceData.type),
                  SummaryRow(l10n.employeeId, PlaceholderEmployeeData.id),
                  SummaryRow(l10n.employeeName, PlaceholderEmployeeData.name),
                ],
              ),
              const SizedBox(height: 28),
              PrimaryActionButton(
                label: l10n.backToDeviceRegistration,
                icon: Icons.assignment_outlined,
                // Preserve Home below the stack so users can continue registering devices.
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.registration,
                  (route) => route.settings.name == AppRoutes.home,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                // Home is the stable reset point for the completed workflow.
                onPressed: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
                icon: const Icon(Icons.home_outlined),
                label: Text(l10n.backToHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
