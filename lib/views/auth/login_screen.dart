// Login screen UI for entering the app.

import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/itsm_text_field.dart';
import '../../shared/widgets/keyboard_dismiss_area.dart';
import '../../shared/widgets/mobile_page.dart';
import '../../shared/widgets/primary_action_button.dart';

/// Login screen that collects credentials before entering the app shell.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  /// Builds the Figma-aligned login UI with localized labels.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final logoWidth = (MediaQuery.sizeOf(context).width - 48).clamp(
      260.0,
      430.0,
    );
    final logoHeight = logoWidth / 1.85;

    return Scaffold(
      bottomNavigationBar: const SafeArea(
        minimum: EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: _LoginFooter(),
      ),
      body: KeyboardDismissArea(
        child: SafeArea(
          child: MobilePage(
            maxWidth: 460,
            child: Column(
              children: [
                const SizedBox(height: 52),
                AppLogo(width: logoWidth, height: logoHeight),
                const SizedBox(height: 34),
                Text(
                  l10n.welcomeBack,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.pleaseLoginToContinue,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 34),
                ItsmTextField(
                  label: '',
                  hint: l10n.username,
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                ItsmTextField(
                  label: '',
                  hint: l10n.password,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: Icon(Icons.visibility_outlined),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                PrimaryActionButton(
                  label: l10n.login,
                  // UI-only login: move to Home without backend validation for Week 3.
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Footer placed outside the login form so it never overlays input fields.
class _LoginFooter extends StatelessWidget {
  const _LoginFooter();

  /// Builds the subtle bottom-centered copyright label.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      l10n.loginFooter,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.74),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
    );
  }
}
