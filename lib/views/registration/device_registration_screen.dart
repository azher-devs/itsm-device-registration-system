// Device lookup and employee assignment screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/device_registration_controller.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/device.dart';
import '../../models/employee.dart';
import '../../shared/widgets/info_card.dart';
import '../../shared/widgets/itsm_text_field.dart';
import '../../shared/widgets/keyboard_dismiss_area.dart';
import '../../shared/widgets/mobile_page.dart';
import '../../shared/widgets/primary_action_button.dart';

/// Arguments used to begin registration with an optional scanned tag.
class RegistrationScreenArgs {
  const RegistrationScreenArgs({
    this.tagNumber,
    this.serialNumber,
    this.employeeId,
    this.showValidatedData = false,
  });

  /// Prefilled tag number when returning from a scanner or deep link.
  final String? tagNumber;

  /// Retained for route compatibility; serial data now comes only from the API.
  final String? serialNumber;

  /// Retained for route compatibility; employee data now comes only from the API.
  final String? employeeId;

  /// Retained for compatibility with existing route callers.
  final bool showValidatedData;
}

/// Finds devices and manages their employee assignment.
class DeviceRegistrationScreen extends ConsumerStatefulWidget {
  const DeviceRegistrationScreen({required this.args, super.key});

  final RegistrationScreenArgs args;

  @override
  ConsumerState<DeviceRegistrationScreen> createState() =>
      _DeviceRegistrationScreenState();
}

/// Synchronizes text controllers with Riverpod registration state.
class _DeviceRegistrationScreenState
    extends ConsumerState<DeviceRegistrationScreen> {
  late final TextEditingController _tagController;
  late final TextEditingController _serialController;
  late final TextEditingController _employeeController;

  @override
  void initState() {
    super.initState();
    _tagController = TextEditingController(text: widget.args.tagNumber ?? '');
    _serialController = TextEditingController();
    _employeeController = TextEditingController();

    final initialTag = widget.args.tagNumber?.trim() ?? '';
    if (initialTag.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(deviceRegistrationControllerProvider.notifier)
              .searchDevice(initialTag);
        }
      });
    }
  }

  @override
  void dispose() {
    _tagController.dispose();
    _serialController.dispose();
    _employeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(deviceRegistrationControllerProvider);
    final metrics = _RegistrationLayoutMetrics.fromWidth(
      MediaQuery.sizeOf(context).width,
    );

    ref.listen<DeviceRegistrationState>(deviceRegistrationControllerProvider, (
      previous,
      next,
    ) {
      _synchronizeFields(previous, next);
      if (previous?.noticeVersion != next.noticeVersion &&
          next.notice != null) {
        _showNotice(next.notice!, l10n, apiMessage: next.noticeMessage);
      }
    });

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
                  onPressed: state.isBusy ? null : _openScanner,
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
                  key: const Key('tag_number_field'),
                  label: l10n.tagNumber,
                  hint: l10n.enterOrSearchTagNumber,
                  controller: _tagController,
                  suffixIcon:
                      state.operation == RegistrationOperation.loadingDevice
                      ? const _FieldLoadingIndicator()
                      : IconButton(
                          tooltip: l10n.searchTagNumber,
                          icon: const Icon(Icons.search),
                          onPressed: state.isBusy ? null : _searchTagNumber,
                        ),
                  errorText: state.tagError
                      ? state.tagErrorMessage ??
                            (state.tagTimedOut
                                ? l10n.deviceLookupTimeout
                                : l10n.invalidTagNumber)
                      : null,
                  onChanged: (_) => ref
                      .read(deviceRegistrationControllerProvider.notifier)
                      .clearTagError(),
                ),
                const SizedBox(height: 16),
                _buildDeviceCard(state.device, l10n),
                const _SectionDivider(),
                ItsmTextField(
                  key: const Key('serial_number_field'),
                  label: l10n.serialNumber,
                  hint: l10n.serialNumberFromDevice,
                  controller: _serialController,
                  readOnly: true,
                ),
                const _SectionDivider(),
                ItsmTextField(
                  key: const Key('employee_id_field'),
                  label: l10n.employeeId,
                  hint: state.device?.isAssigned == true
                      ? l10n.assignedEmployee
                      : l10n.enterEmployeeId,
                  controller: _employeeController,
                  readOnly: state.device?.isAssigned == true,
                  suffixIcon:
                      state.operation == RegistrationOperation.loadingEmployee
                      ? const _FieldLoadingIndicator()
                      : IconButton(
                          tooltip: l10n.searchEmployeeId,
                          icon: const Icon(Icons.search),
                          onPressed:
                              state.device != null &&
                                  !state.device!.isAssigned &&
                                  !state.isBusy
                              ? _searchEmployeeId
                              : null,
                        ),
                  errorText: state.employeeError
                      ? state.employeeErrorMessage ?? l10n.invalidEmployeeId
                      : null,
                  onChanged: (_) => ref
                      .read(deviceRegistrationControllerProvider.notifier)
                      .employeeInputChanged(),
                ),
                const SizedBox(height: 16),
                _buildEmployeeCard(state.employee, l10n),
                if (state.canAdd || state.device?.isAssigned == true) ...[
                  const SizedBox(height: 18),
                  _AssignmentActionButton(
                    isRemove: state.device?.isAssigned == true,
                    isEnabled: state.canAdd || state.canRemove,
                    onPressed: () => _showAssignmentConfirmation(
                      isRemove: state.device?.isAssigned == true,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryActionButton(
                  label: l10n.scanBarcode,
                  icon: Icons.qr_code_scanner,
                  onPressed: state.isBusy ? null : _openScanner,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Displays all relevant device values returned by the lookup endpoint.
  Widget _buildDeviceCard(Device? device, AppLocalizations l10n) {
    if (device == null) {
      return InfoCard.empty(
        title: l10n.deviceInformation,
        icon: Icons.laptop_mac,
        message: l10n.deviceInformationEmpty,
      );
    }

    return InfoCard(
      title: l10n.deviceInformation,
      icon: Icons.laptop_mac,
      rows: [
        InfoRow(l10n.tagNumber, _valueOrUnavailable(device.tagNumber, l10n)),
        InfoRow(l10n.brand, _valueOrUnavailable(device.brand, l10n)),
        InfoRow(l10n.deviceType, _valueOrUnavailable(device.deviceType, l10n)),
        InfoRow(
          l10n.serialNumber,
          _valueOrUnavailable(device.serialNumber, l10n),
        ),
        InfoRow(l10n.status, _localizedDeviceStatus(device.status, l10n)),
        InfoRow(
          l10n.assignmentStatus,
          device.isAssigned ? l10n.assigned : l10n.notAssigned,
        ),
      ],
    );
  }

  /// Displays the three employee details required by the current UI.
  Widget _buildEmployeeCard(Employee? employee, AppLocalizations l10n) {
    if (employee == null) {
      return InfoCard.empty(
        title: l10n.employeeInformation,
        icon: Icons.badge_outlined,
        message: l10n.employeeInformationEmpty,
      );
    }

    return InfoCard(
      title: l10n.employeeInformation,
      icon: Icons.badge_outlined,
      rows: [
        InfoRow(
          l10n.employeeId,
          _valueOrUnavailable(employee.employeeNumber, l10n),
        ),
        InfoRow(
          l10n.employeeName,
          _valueOrUnavailable(employee.fullName, l10n),
        ),
        InfoRow(
          l10n.organization,
          _valueOrUnavailable(employee.organization, l10n),
        ),
      ],
    );
  }

  /// Opens the scanner and passes its result through the same device lookup.
  Future<void> _openScanner() async {
    final scannedTag = await Navigator.of(context).pushNamed(AppRoutes.scanner);
    if (!mounted || scannedTag is! String || scannedTag.trim().isEmpty) {
      return;
    }

    _tagController.text = scannedTag.trim();
    await ref
        .read(deviceRegistrationControllerProvider.notifier)
        .searchDevice(scannedTag);
  }

  /// Runs manual tag input through the shared device-search controller method.
  Future<void> _searchTagNumber() async {
    FocusScope.of(context).unfocus();
    await ref
        .read(deviceRegistrationControllerProvider.notifier)
        .searchDevice(_tagController.text);
  }

  /// Searches the API for the employee number entered by the user.
  Future<void> _searchEmployeeId() async {
    FocusScope.of(context).unfocus();
    await ref
        .read(deviceRegistrationControllerProvider.notifier)
        .searchEmployee(_employeeController.text);
  }

  /// Shows an assignment-specific confirmation dialog before making a request.
  Future<void> _showAssignmentConfirmation({required bool isRemove}) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (dialogContext) => _AssignmentConfirmationDialog(
        isRemove: isRemove,
        tagNumber: _tagController.text.trim(),
        employeeId: _employeeController.text.trim(),
        onConfirm: () async {
          final controller = ref.read(
            deviceRegistrationControllerProvider.notifier,
          );
          return isRemove
              ? controller.removeAssignment()
              : controller.addAssignment();
        },
      ),
    );
  }

  /// Keeps read-only API fields synchronized after lookups and mutations.
  void _synchronizeFields(
    DeviceRegistrationState? previous,
    DeviceRegistrationState next,
  ) {
    if (previous?.device != next.device) {
      final device = next.device;
      _serialController.text = device?.serialNumber ?? '';
      if (device != null && device.tagNumber.isNotEmpty) {
        _tagController.text = device.tagNumber;
      }
    }

    if (previous?.employee != next.employee ||
        previous?.device != next.device) {
      _employeeController.text =
          next.employee?.employeeNumber ??
          next.device?.assignedEmployeeNumber ??
          '';
    }
  }

  /// Converts controller notices to localized, theme-aware snackbars.
  void _showNotice(
    RegistrationNotice notice,
    AppLocalizations l10n, {
    String? apiMessage,
  }) {
    final isFailure =
        notice == RegistrationNotice.assignmentAddFailed ||
        notice == RegistrationNotice.assignmentRemoveFailed;
    final message = isFailure && apiMessage?.isNotEmpty == true
        ? apiMessage!
        : switch (notice) {
            RegistrationNotice.assignmentAdded =>
              l10n.assignmentAddedSuccessfully,
            RegistrationNotice.assignmentRemoved =>
              l10n.assignmentRemovedSuccessfully,
            RegistrationNotice.assignmentAddFailed => l10n.assignmentAddFailure,
            RegistrationNotice.assignmentRemoveFailed =>
              l10n.assignmentRemovalFailure,
          };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isFailure ? AppTheme.danger : AppTheme.success,
          duration: const Duration(milliseconds: 2500),
        ),
      );
  }

  /// Uses localized fallback copy for optional empty API values.
  String _valueOrUnavailable(String value, AppLocalizations l10n) {
    return value.trim().isEmpty ? l10n.notAvailable : value;
  }

  /// Localizes assignment-like demo statuses without changing API values.
  String _localizedDeviceStatus(String status, AppLocalizations l10n) {
    return switch (status.trim().toLowerCase()) {
      'assigned' => l10n.assigned,
      'not assigned' => l10n.notAssigned,
      _ => _valueOrUnavailable(status, l10n),
    };
  }
}

/// Dynamic Add or Remove action shown below employee information.
class _AssignmentActionButton extends StatelessWidget {
  const _AssignmentActionButton({
    required this.isRemove,
    required this.isEnabled,
    required this.onPressed,
  });

  final bool isRemove;
  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        key: Key(
          isRemove ? 'remove_assignment_button' : 'add_assignment_button',
        ),
        onPressed: isEnabled ? onPressed : null,
        icon: Icon(isRemove ? Icons.link_off : Icons.add_link),
        label: Text(isRemove ? l10n.remove : l10n.add),
        style: ElevatedButton.styleFrom(
          backgroundColor: isRemove ? AppTheme.danger : AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Theme.of(context).disabledColor,
        ),
      ),
    );
  }
}

/// Responsive confirmation dialog that prevents duplicate assignment requests.
class _AssignmentConfirmationDialog extends StatefulWidget {
  const _AssignmentConfirmationDialog({
    required this.isRemove,
    required this.tagNumber,
    required this.employeeId,
    required this.onConfirm,
  });

  final bool isRemove;
  final String tagNumber;
  final String employeeId;
  final Future<bool> Function() onConfirm;

  @override
  State<_AssignmentConfirmationDialog> createState() =>
      _AssignmentConfirmationDialogState();
}

/// Holds dialog-local loading state while Add or Remove is running.
class _AssignmentConfirmationDialogState
    extends State<_AssignmentConfirmationDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final actionColor = widget.isRemove
        ? AppTheme.danger
        : AppTheme.primaryBlue;
    final iconBackground = widget.isRemove
        ? AppTheme.danger.withValues(alpha: 0.10)
        : AppTheme.lightBlue;

    return PopScope(
      canPop: !_isLoading,
      child: Dialog(
        key: const Key('assignment_confirmation_dialog'),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.isRemove
                          ? Icons.person_remove_alt_1_rounded
                          : Icons.add_link_rounded,
                      color: actionColor,
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.isRemove ? l10n.removeAssignment : l10n.assignDevice,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.darkBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.isRemove
                      ? l10n.removeDeviceAssignmentConfirmation
                      : l10n.assignDeviceConfirmation,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.mutedText,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                _ConfirmationInfoCard(
                  tagLabel: l10n.tagNumber,
                  tagNumber: widget.tagNumber,
                  employeeLabel: l10n.employeeId,
                  employeeId: widget.employeeId,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryBlue,
                          backgroundColor: Colors.white,
                          side: const BorderSide(
                            color: AppTheme.primaryBlue,
                            width: 1.4,
                          ),
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(l10n.no),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        key: const Key('confirm_assignment_action'),
                        onPressed: _isLoading ? null : _confirm,
                        style: FilledButton.styleFrom(
                          backgroundColor: actionColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(l10n.yes),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Runs one guarded request and closes after either success or failure.
  Future<void> _confirm() async {
    if (_isLoading) {
      return;
    }
    setState(() => _isLoading = true);
    await widget.onConfirm();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// Groups assignment identifiers in the dialog's information card.
class _ConfirmationInfoCard extends StatelessWidget {
  const _ConfirmationInfoCard({
    required this.tagLabel,
    required this.tagNumber,
    required this.employeeLabel,
    required this.employeeId,
  });

  final String tagLabel;
  final String tagNumber;
  final String employeeLabel;
  final String employeeId;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EAF2)),
      ),
      child: Column(
        children: [
          _ConfirmationInfoRow(
            icon: Icons.sell_outlined,
            label: tagLabel,
            value: tagNumber,
          ),
          const Divider(
            height: 1,
            thickness: 1,
            indent: 54,
            endIndent: 16,
            color: Color(0xFFE5EAF2),
          ),
          _ConfirmationInfoRow(
            icon: Icons.badge_outlined,
            label: employeeLabel,
            value: employeeId,
          ),
        ],
      ),
    );
  }
}

/// Displays one icon, label, and current value in the information card.
class _ConfirmationInfoRow extends StatelessWidget {
  const _ConfirmationInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.darkBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact progress indicator used inside search fields.
class _FieldLoadingIndicator extends StatelessWidget {
  const _FieldLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(14),
      child: CircularProgressIndicator(strokeWidth: 2.2),
    );
  }
}

/// Responsive spacing values for the scanner button in the page header.
class _RegistrationLayoutMetrics {
  const _RegistrationLayoutMetrics({
    required this.fabSize,
    required this.iconSize,
    required this.endMargin,
    required this.headerSideWidth,
    required this.toolbarHeight,
  });

  final double fabSize;
  final double iconSize;
  final double endMargin;
  final double headerSideWidth;
  final double toolbarHeight;

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

/// Circular camera action fixed in the responsive page header.
class _ScannerFloatingButton extends StatelessWidget {
  const _ScannerFloatingButton({
    required this.tooltip,
    required this.size,
    required this.iconSize,
    required this.onPressed,
  });

  final String tooltip;
  final double size;
  final double iconSize;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: onPressed == null
            ? Theme.of(context).disabledColor
            : AppTheme.primaryBlue,
        elevation: onPressed == null ? 0 : 4,
        shadowColor: Colors.black.withValues(alpha: 0.22),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            key: const Key('registration_scanner_fab'),
            dimension: size,
            child: Icon(Icons.camera_alt, color: Colors.white, size: iconSize),
          ),
        ),
      ),
    );
  }
}

/// Timeline-style divider separating registration form groups.
class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

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
