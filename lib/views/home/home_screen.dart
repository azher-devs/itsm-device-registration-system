// Home screen, drawer, and language selection UI.

import 'package:flutter/material.dart';

import '../../controllers/locale_controller.dart';
import '../../controllers/locale_controller_provider.dart';
import '../../controllers/theme_controller.dart';
import '../../controllers/theme_controller_provider.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/mobile_page.dart';
import '../../shared/widgets/primary_action_button.dart';

/// Home screen with the main registration entry point and app drawer.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Builds the welcome area, registration card, and drawer-enabled app bar.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final verticalGap = (MediaQuery.sizeOf(context).height * 0.15).clamp(
      72.0,
      132.0,
    );

    return Scaffold(
      drawer: const _HomeDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) {
            return IconButton(
              tooltip: l10n.menu,
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        title: Text(
          l10n.home,
          style: const TextStyle(color: AppTheme.primaryBlue),
        ),
        actions: [
          IconButton(
            tooltip: l10n.notifications,
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: MobilePage(
          maxWidth: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 22),
              Text(
                l10n.welcomeUser,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  height: 0.94,
                ),
              ),
              SizedBox(height: verticalGap),
              _RegisterDeviceCard(
                title: l10n.registerDevice,
                description: l10n.registerDeviceDescription,
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.registration),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card that starts the device registration workflow.
class _RegisterDeviceCard extends StatelessWidget {
  const _RegisterDeviceCard({
    required this.title,
    required this.description,
    required this.onPressed,
  });

  /// Localized title used for the card heading and button.
  final String title;

  /// Short description explaining the registration action.
  final String description;

  /// Called when the user starts a new registration.
  final VoidCallback onPressed;

  /// Builds the centered icon, description, and primary action button.
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
        children: [
          const CircleAvatar(
            radius: 48,
            backgroundColor: AppTheme.lightBlue,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.devices_other_outlined,
                  color: AppTheme.primaryBlue,
                  size: 44,
                ),
                Positioned(
                  right: 13,
                  bottom: 15,
                  child: Icon(Icons.add, color: AppTheme.primaryBlue, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 22),
          PrimaryActionButton(
            label: title,
            icon: Icons.add_circle_outline,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

/// Drawer that exposes language selection and logout actions.
class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer();

  /// Builds drawer content and keeps the active language visible.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeController = LocaleControllerProvider.of(context);
    final themeController = ThemeControllerProvider.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final drawerWidth = (MediaQuery.sizeOf(context).width * 0.82).clamp(
      300.0,
      420.0,
    );
    final logoWidth = (drawerWidth - 48).clamp(252.0, 372.0);
    final logoHeight = logoWidth / 1.85;

    return Drawer(
      width: drawerWidth,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.horizontal(
          end: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 42, 24, 24),
            child: Column(
              children: [
                AppLogo(width: logoWidth, height: logoHeight),
                const SizedBox(height: 46),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.language,
                    color: AppTheme.mutedText,
                  ),
                  title: Text(
                    l10n.language,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Show the active language without changing it from the drawer row.
                      Text(
                        localeController.isArabic ? l10n.arabic : l10n.english,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  onTap: () => _showLanguageDialog(context, localeController),
                ),
                const Divider(height: 32, color: AppTheme.border),
                _AppearanceSection(
                  l10n: l10n,
                  themeController: themeController,
                ),
                const Divider(height: 32, color: AppTheme.border),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout, color: AppTheme.danger),
                  title: Text(
                    l10n.logout,
                    style: const TextStyle(
                      color: AppTheme.danger,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the language picker without changing the current locale.
  void _showLanguageDialog(
    BuildContext context,
    LocaleController localeController,
  ) {
    // The language row opens a selector first; language changes only after selection.
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext);
        final colorScheme = Theme.of(dialogContext).colorScheme;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: Text(
                            l10n.language,
                            style: Theme.of(dialogContext).textTheme.titleLarge
                                ?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            tooltip: l10n.close,
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _LanguageOptionRow(
                      languageName: l10n.languageOptionEnglish,
                      languageCode: l10n.languageCodeEnglish,
                      isSelected: !localeController.isArabic,
                      onTap: () => _selectLanguage(
                        dialogContext,
                        localeController,
                        const Locale('en'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _LanguageOptionRow(
                      languageName: l10n.languageOptionArabic,
                      languageCode: l10n.languageCodeArabic,
                      isSelected: localeController.isArabic,
                      onTap: () => _selectLanguage(
                        dialogContext,
                        localeController,
                        const Locale('ar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Applies the selected locale, persists it, and closes the dialog.
  Future<void> _selectLanguage(
    BuildContext dialogContext,
    LocaleController localeController,
    Locale locale,
  ) async {
    // Persist before closing so the selected language is restored on restart.
    await localeController.setLocale(locale);

    if (dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }
  }
}

/// Appearance menu section that switches between light and dark themes.
class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection({required this.l10n, required this.themeController});

  /// Localized labels used by the menu rows.
  final AppLocalizations l10n;

  /// Controller that applies and persists the selected appearance.
  final ThemeController themeController;

  /// Builds the title row and the two selectable appearance rows.
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.brightness_6_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
          title: Text(
            l10n.appearance,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _AppearanceOptionRow(
          icon: Icons.wb_sunny_outlined,
          label: l10n.lightMode,
          isSelected: !themeController.isDarkMode,
          onTap: () => themeController.setThemeMode(ThemeMode.light),
        ),
        _AppearanceOptionRow(
          icon: Icons.dark_mode_outlined,
          label: l10n.darkMode,
          isSelected: themeController.isDarkMode,
          onTap: () => themeController.setThemeMode(ThemeMode.dark),
        ),
      ],
    );
  }
}

/// Selectable appearance row used for Light Mode and Dark Mode.
class _AppearanceOptionRow extends StatelessWidget {
  const _AppearanceOptionRow({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  /// Sun or moon icon shown beside the option.
  final IconData icon;

  /// Localized option label.
  final String label;

  /// Controls the check mark and selected color.
  final bool isSelected;

  /// Applies the selected theme mode.
  final VoidCallback onTap;

  /// Builds a compact menu option matching the reference drawer style.
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedColor = Theme.of(context).colorScheme.primary;
    final rowColor = isSelected ? selectedColor : colorScheme.onSurface;

    return ListTile(
      contentPadding: const EdgeInsetsDirectional.only(start: 18),
      leading: Icon(icon, color: rowColor),
      title: Text(
        label,
        style: TextStyle(
          color: rowColor,
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: selectedColor, size: 22)
          : const SizedBox(width: 22),
      onTap: onTap,
    );
  }
}

/// Selectable row used inside the language picker dialog.
class _LanguageOptionRow extends StatelessWidget {
  const _LanguageOptionRow({
    required this.languageName,
    required this.languageCode,
    required this.isSelected,
    required this.onTap,
  });

  /// Display name for the language option.
  final String languageName;

  /// Short language code displayed on the trailing side of the row.
  final String languageCode;

  /// Shows the selected styling and check mark for the active locale.
  final bool isSelected;

  /// Called when the user chooses this language.
  final VoidCallback onTap;

  /// Builds a fixed LTR row so EN/AR codes stay visually consistent.
  @override
  Widget build(BuildContext context) {
    // Keep the dialog row anatomy stable: icon left, code and check at right.
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBackground = isDark
        ? AppTheme.darkSurface
        : AppTheme.lightBlue;
    final rowBackground = isSelected ? selectedBackground : colorScheme.surface;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: rowBackground,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: selectedBackground,
                  child: Icon(
                    Icons.language,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    languageName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  languageCode,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 22,
                  child: isSelected
                      ? const Icon(
                          Icons.check_circle,
                          color: AppTheme.success,
                          size: 22,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
