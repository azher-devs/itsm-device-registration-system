// Splash screen shown during startup.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/mobile_page.dart';

/// Initial loading screen shown before the login screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Creates state so the screen can navigate after a short delay.
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// Handles the splash timer and startup navigation.
class _SplashScreenState extends State<SplashScreen> {
  /// Starts the splash delay once the widget is inserted into the tree.
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1200), () {
      // Avoid navigating if the splash screen was disposed early.
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    });
  }

  /// Builds the centered logo and loading indicator.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final logoWidth = (MediaQuery.sizeOf(context).width - 48).clamp(
      260.0,
      460.0,
    );
    final logoHeight = logoWidth / 1.85;

    return Scaffold(
      body: MobilePage(
        maxWidth: 520,
        scrollable: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppLogo(width: logoWidth, height: logoHeight),
            const SizedBox(height: 84),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.initializingWorkspace,
              style: const TextStyle(
                color: AppTheme.mutedText,
                fontSize: 12,
                letterSpacing: 0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
