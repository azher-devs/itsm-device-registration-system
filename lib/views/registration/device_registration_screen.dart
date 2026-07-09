// Device registration form and after-scan state UI.

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/placeholder_data.dart';
import '../../shared/widgets/info_card.dart';
import '../../shared/widgets/itsm_text_field.dart';
import '../../shared/widgets/keyboard_dismiss_area.dart';
import '../../shared/widgets/mobile_page.dart';
import '../../shared/widgets/primary_action_button.dart';

/// Arguments used to prefill registration after barcode scanning.
class RegistrationScreenArgs {
  const RegistrationScreenArgs({
    this.tagNumber,
    this.serialNumber,
    this.employeeId,
    this.showValidatedData = false,
  });

  /// Prefilled tag number when coming from the scanner.
  final String? tagNumber;

  /// Prefilled serial number when coming from the scanner.
  final String? serialNumber;

  /// Prefilled employee ID when coming from the scanner.
  final String? employeeId;

  /// Controls whether placeholder validation cards are shown.
  final bool showValidatedData;
}

/// Main screen responsible for registering an employee device assignment.
class DeviceRegistrationScreen extends StatefulWidget {
  const DeviceRegistrationScreen({required this.args, super.key});

  /// Optional values that distinguish empty and after-scan states.
  final RegistrationScreenArgs args;

  /// Creates state for text controllers and form prefill behavior.
  @override
  State<DeviceRegistrationScreen> createState() =>
      _DeviceRegistrationScreenState();
}

/// Owns text controllers for the registration form fields.
class _DeviceRegistrationScreenState extends State<DeviceRegistrationScreen> {
  /// Controller for the device tag number field.
  late final TextEditingController _tagController;

  /// Controller for the device serial number field.
  late final TextEditingController _serialController;

  /// Controller for the employee ID field.
  late final TextEditingController _employeeController;

  /// Indicates whether placeholder device and employee data should be visible.
  late bool _showDeviceData;

  /// Indicates whether placeholder employee data should be visible.
  late bool _showEmployeeData;

  /// Shows the tag number validation message when input does not match the placeholder format.
  bool _hasTagError = false;

  /// Shows the serial number validation message when input does not match the placeholder format.
  bool _hasSerialError = false;

  /// Shows the employee ID validation message when input does not match the placeholder format.
  bool _hasEmployeeError = false;

  /// Initializes form fields with scanner-provided values when available.
  @override
  void initState() {
    super.initState();
    _tagController = TextEditingController(text: widget.args.tagNumber ?? '');
    _showDeviceData = widget.args.showValidatedData;
    _showEmployeeData = widget.args.showValidatedData;
    _serialController = TextEditingController(
      text:
          widget.args.serialNumber ??
          (_showDeviceData ? PlaceholderDeviceData.serialNumber : ''),
    );
    _employeeController = TextEditingController(
      text:
          widget.args.employeeId ??
          (_showEmployeeData ? PlaceholderEmployeeData.id : ''),
    );
  }

  /// Disposes controllers created by this state object.
  @override
  void dispose() {
    _tagController.dispose();
    _serialController.dispose();
    _employeeController.dispose();
    super.dispose();
  }

  /// Builds the registration form and its empty or populated information cards.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final metrics = _RegistrationLayoutMetrics.fromWidth(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: metrics.toolbarHeight,
        leadingWidth: metrics.headerSideWidth,
        leading: IconButton(
          tooltip: l10n.back,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(l10n.deviceRegistration),
        ),
        actions: [
          SizedBox(
            width: metrics.headerSideWidth,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: EdgeInsetsDirectional.only(end: metrics.endMargin),
                child: _ScannerFloatingButton(
                  tooltip: l10n.scanBarcode,
                  size: metrics.fabSize,
                  iconSize: metrics.iconSize,
                  onPressed: _openScanner,
                ),
              ),
            ),
          ),
        ],
      ),
      body: KeyboardDismissArea(
        child: SafeArea(
          child: MobilePage(
            maxWidth: 520,
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ItsmTextField(
                  label: l10n.tagNumber,
                  hint: l10n.enterOrSearchTagNumber,
                  controller: _tagController,
                  suffixIcon: IconButton(
                    tooltip: l10n.searchTagNumber,
                    icon: const Icon(Icons.search),
                    onPressed: _searchTagNumber,
                  ),
                  errorText: _hasTagError ? l10n.invalidTagNumber : null,
                  onChanged: (_) => _clearTagError(),
                ),
                const SizedBox(height: 16),
                // After scan, show validated placeholder data instead of an empty card.
                _showDeviceData
                    ? InfoCard(
                        title: l10n.deviceInformation,
                        icon: Icons.laptop_mac,
                        rows: [
                          InfoRow(l10n.brand, PlaceholderDeviceData.brand),
                          InfoRow(l10n.deviceType, PlaceholderDeviceData.type),
                          InfoRow(l10n.status, l10n.assigned),
                        ],
                      )
                    : InfoCard.empty(
                        title: l10n.deviceInformation,
                        icon: Icons.laptop_mac,
                        message: l10n.deviceInformationEmpty,
                      ),
                const _SectionDivider(),
                ItsmTextField(
                  label: l10n.serialNumber,
                  hint: l10n.enterSerialNumber,
                  controller: _serialController,
                  errorText: _hasSerialError ? l10n.invalidSerialNumber : null,
                  onChanged: (_) => _clearSerialError(),
                ),
                const _SectionDivider(),
                ItsmTextField(
                  label: l10n.employeeId,
                  hint: l10n.enterEmployeeId,
                  controller: _employeeController,
                  suffixIcon: IconButton(
                    tooltip: l10n.searchEmployeeId,
                    icon: const Icon(Icons.search),
                    onPressed: _searchEmployeeId,
                  ),
                  errorText: _hasEmployeeError ? l10n.invalidEmployeeId : null,
                  onChanged: (_) => _clearEmployeeError(),
                ),
                const SizedBox(height: 16),
                // Employee details follow the same empty/populated pattern as device data.
                _showEmployeeData
                    ? InfoCard(
                        title: l10n.employeeInformation,
                        icon: Icons.badge_outlined,
                        rows: [
                          InfoRow(
                            l10n.employeeName,
                            PlaceholderEmployeeData.name,
                          ),
                          InfoRow(
                            l10n.department,
                            PlaceholderEmployeeData.department,
                          ),
                          InfoRow(
                            l10n.location,
                            PlaceholderEmployeeData.location,
                          ),
                        ],
                      )
                    : InfoCard.empty(
                        title: l10n.employeeInformation,
                        icon: Icons.badge_outlined,
                        message: l10n.employeeInformationEmpty,
                      ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        // Submit is UI-only and confirms before showing success.
                        onPressed: _submitRegistration,
                        child: Text(l10n.submit),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                PrimaryActionButton(
                  label: l10n.scanBarcode,
                  icon: Icons.qr_code_scanner,
                  onPressed: _openScanner,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the scanner and applies the returned tag using the existing lookup flow.
  Future<void> _openScanner() async {
    final scannedTag = await Navigator.of(context).pushNamed(AppRoutes.scanner);

    if (!mounted || scannedTag is! String || scannedTag.trim().isEmpty) {
      return;
    }

    _applyTagLookup(scannedTag.trim());
  }

  /// Fills and validates placeholder device data until real lookup is connected.
  void _searchTagNumber() {
    _applyTagLookup(PlaceholderDeviceData.tagNumber);
  }

  /// Applies a scanned or searched tag and fills placeholder device details.
  void _applyTagLookup(String tagNumber) {
    setState(() {
      _tagController.text = tagNumber;
      _serialController.text = PlaceholderDeviceData.serialNumber;
      _showDeviceData = true;
      _hasTagError = false;
      _hasSerialError = false;
    });
  }

  /// Fills and validates placeholder employee data until real lookup is connected.
  void _searchEmployeeId() {
    setState(() {
      _employeeController.text = PlaceholderEmployeeData.id;
      _showEmployeeData = true;
      _hasEmployeeError = false;
    });
  }

  /// Validates the visible UI fields before showing the success screen.
  void _submitRegistration() {
    FocusScope.of(context).unfocus();

    final tagValid = _isTagReadyForSubmit();
    final serialValid = _isValidSerialNumber(_serialController.text);
    final employeeValid = _isValidEmployeeId(_employeeController.text);

    setState(() {
      _hasTagError = !tagValid;
      _hasSerialError = !serialValid;
      _hasEmployeeError = !employeeValid;
      _showDeviceData = tagValid && serialValid;
      _showEmployeeData = employeeValid;
    });

    if (tagValid && serialValid && employeeValid) {
      _showSubmitConfirmationDialog();
    }
  }

  /// Asks users to confirm before completing the placeholder registration.
  Future<void> _showSubmitConfirmationDialog() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        final dialogWidth = (MediaQuery.sizeOf(dialogContext).width * 0.84)
            .clamp(280.0, 420.0);

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            backgroundColor: Colors.transparent,
            child: SizedBox(
              width: dialogWidth,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 30,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 36,
                        backgroundColor: AppTheme.lightBlue,
                        child: Icon(
                          Icons.help_outline,
                          color: AppTheme.primaryBlue,
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        l10n.confirmSubmission,
                        textAlign: TextAlign.center,
                        style: Theme.of(dialogContext).textTheme.titleLarge
                            ?.copyWith(
                              color: isDark ? Colors.white : AppTheme.darkBlue,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.submitConfirmationMessage,
                        textAlign: TextAlign.center,
                        style: Theme.of(dialogContext).textTheme.bodyLarge
                            ?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 24),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: colorScheme.surface,
                                foregroundColor: AppTheme.primaryBlue,
                                side: const BorderSide(
                                  color: AppTheme.primaryBlue,
                                ),
                                minimumSize: const Size.fromHeight(54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(l10n.cancel),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(l10n.submit),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    Navigator.of(context).pushNamed(AppRoutes.success);
  }

  /// Checks the placeholder tag number format used by the current UI-only flow.
  bool _isValidTagNumber(String value) {
    return RegExp(r'^TAG-\d{4}-\d{6}$').hasMatch(value.trim());
  }

  /// Accepts typed placeholder tags or scanned tags that completed lookup.
  bool _isTagReadyForSubmit() {
    final tagNumber = _tagController.text.trim();
    if (tagNumber.isEmpty) {
      return false;
    }

    // Scanned barcodes can use real asset tag formats, so successful lookup
    // makes the current tag valid even when it is not the placeholder pattern.
    return _isValidTagNumber(tagNumber) || _showDeviceData;
  }

  /// Checks the placeholder serial number format used by the current UI-only flow.
  bool _isValidSerialNumber(String value) {
    return RegExp(r'^SN-[A-Z0-9]{4}-\d{4}-[A-Z0-9]{4}$').hasMatch(value.trim());
  }

  /// Checks the placeholder employee ID format used by the current UI-only flow.
  bool _isValidEmployeeId(String value) {
    return RegExp(r'^EMP-\d{5}$').hasMatch(value.trim());
  }

  /// Clears the tag error while keeping already validated data hidden if edited.
  void _clearTagError() {
    if (_hasTagError || _showDeviceData) {
      setState(() {
        _hasTagError = false;
        _showDeviceData = false;
      });
    }
  }

  /// Clears the serial number error when the user edits the field.
  void _clearSerialError() {
    if (_hasSerialError) {
      setState(() => _hasSerialError = false);
    }
  }

  /// Clears the employee error while hiding stale employee details if edited.
  void _clearEmployeeError() {
    if (_hasEmployeeError || _showEmployeeData) {
      setState(() {
        _hasEmployeeError = false;
        _showEmployeeData = false;
      });
    }
  }
}

/// Responsive spacing values that keep the fixed FAB clear of form content.
class _RegistrationLayoutMetrics {
  const _RegistrationLayoutMetrics({
    required this.fabSize,
    required this.iconSize,
    required this.endMargin,
    required this.headerSideWidth,
    required this.toolbarHeight,
  });

  /// Diameter of the scanner FAB.
  final double fabSize;

  /// Size of the camera icon inside the FAB.
  final double iconSize;

  /// Trailing distance from the constrained content edge.
  final double endMargin;

  /// Symmetric header side width keeps title centered and clear of controls.
  final double headerSideWidth;

  /// Toolbar height keeps the circular button inside the header SafeArea.
  final double toolbarHeight;

  /// Creates phone, foldable, and tablet friendly spacing from available width.
  factory _RegistrationLayoutMetrics.fromWidth(double width) {
    final isTabletLike = width >= 600;
    final isCompactPhone = width < 360;
    final fabSize = isTabletLike ? 64.0 : (isCompactPhone ? 52.0 : 56.0);
    final iconSize = isTabletLike ? 28.0 : 26.0;
    final endMargin = isTabletLike ? 18.0 : (isCompactPhone ? 12.0 : 16.0);

    return _RegistrationLayoutMetrics(
      fabSize: fabSize,
      iconSize: iconSize,
      endMargin: endMargin,
      headerSideWidth: fabSize + endMargin + 8,
      toolbarHeight: fabSize + 16,
    );
  }
}

/// Fixed scanner FAB positioned above the form content.
class _ScannerFloatingButton extends StatelessWidget {
  const _ScannerFloatingButton({
    required this.tooltip,
    required this.size,
    required this.iconSize,
    required this.onPressed,
  });

  /// Localized accessibility label for scanner navigation.
  final String tooltip;

  /// Responsive button diameter.
  final double size;

  /// Responsive camera icon size.
  final double iconSize;

  /// Opens the barcode scanner route.
  final VoidCallback onPressed;

  /// Builds a circular Material 3-style scanner action with brand styling.
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: AppTheme.primaryBlue,
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.22),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox.square(
              key: const Key('registration_scanner_fab'),
              dimension: size,
              child: Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Subtle section break used to separate registration form groups.
class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  /// Builds a lightweight timeline-style divider without adding containers.
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE5E7EB);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(height: 1, color: lineColor),
            Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: AppTheme.primaryBlue,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
