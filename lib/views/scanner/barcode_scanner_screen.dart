// Barcode scanner placeholder screen used by the registration flow.

import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/placeholder_data.dart';
import '../registration/device_registration_screen.dart';

/// Barcode scanner placeholder used before camera integration is added.
class BarcodeScannerScreen extends StatelessWidget {
  const BarcodeScannerScreen({super.key});

  /// Builds the dark scanner mockup and manual entry action.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Stack(
              children: [
                const Positioned.fill(child: _CameraPreviewPlaceholder()),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _ScannerAppBar(
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                ),
                const Center(child: _ScannerGuide()),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 28,
                  child: ElevatedButton.icon(
                    onPressed: () => _finishScan(context),
                    icon: const Icon(Icons.keyboard_alt_outlined),
                    label: Text(l10n.manualEntry),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Simulates a completed scan by returning prefilled registration data.
  void _finishScan(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.registration,
      arguments: const RegistrationScreenArgs(
        tagNumber: PlaceholderDeviceData.tagNumber,
        serialNumber: PlaceholderDeviceData.serialNumber,
        employeeId: PlaceholderEmployeeData.id,
        showValidatedData: true,
      ),
    );
  }
}

/// Top scanner controls for back navigation, title, and flash placeholder.
class _ScannerAppBar extends StatelessWidget {
  const _ScannerAppBar({required this.onBack});

  /// Callback used by the parent to leave the scanner.
  final VoidCallback onBack;

  /// Builds scanner header controls over the camera preview.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.back,
            color: Colors.white,
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              l10n.scanBarcode,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.flash,
            color: Colors.white,
            icon: const Icon(Icons.flash_on),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

/// Visual stand-in for the future live camera preview.
class _CameraPreviewPlaceholder extends StatelessWidget {
  const _CameraPreviewPlaceholder();

  /// Builds a dark gradient that reads like an inactive camera feed.
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, 0.25),
          radius: 1.05,
          colors: [
            Colors.blueGrey.shade300,
            const Color(0xFF172124),
            Colors.black,
          ],
        ),
      ),
      child: Container(color: Colors.black.withValues(alpha: 0.28)),
    );
  }
}

/// Shows scan instructions and the barcode target area.
class _ScannerGuide extends StatelessWidget {
  const _ScannerGuide();

  /// Builds the centered guidance text and scan frame.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 34),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Scale the scan target with the preview width while keeping phone proportions.
          final frameHeight = (constraints.maxWidth * 0.42).clamp(124.0, 184.0);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.alignBarcode,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: frameHeight,
                width: double.infinity,
                child: CustomPaint(
                  painter: _ScanFramePainter(),
                  child: Row(
                    children: [
                      Expanded(child: _MockBarcodeBlock(opacity: 0.48)),
                      const SizedBox(width: 14),
                      Expanded(child: _MockBarcodeBlock(opacity: 0.42)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Soft block used to suggest barcode content inside the scan frame.
class _MockBarcodeBlock extends StatelessWidget {
  const _MockBarcodeBlock({required this.opacity});

  /// Opacity creates slight variation between placeholder blocks.
  final double opacity;

  /// Builds one blurred placeholder block.
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.18),
            blurRadius: 22,
          ),
        ],
      ),
    );
  }
}

/// Paints the blue corner brackets for the scanner target.
class _ScanFramePainter extends CustomPainter {
  /// Draws four corner brackets around the scan target area.
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryBlue
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    const cornerLength = 44.0;
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);

    canvas.drawLine(
      rect.topLeft,
      rect.topLeft + const Offset(cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      rect.topLeft,
      rect.topLeft + const Offset(0, cornerLength),
      paint,
    );
    canvas.drawLine(
      rect.topRight,
      rect.topRight - const Offset(cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      rect.topRight,
      rect.topRight + const Offset(0, cornerLength),
      paint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + const Offset(cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft - const Offset(0, cornerLength),
      paint,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight - const Offset(cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight - const Offset(0, cornerLength),
      paint,
    );
  }

  /// The frame is static, so repainting is unnecessary.
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
