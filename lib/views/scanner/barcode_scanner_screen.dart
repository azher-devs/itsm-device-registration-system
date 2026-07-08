// Barcode scanner screen backed by the device camera and Google ML Kit.

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/placeholder_data.dart';

/// Camera-based barcode scanner used by the registration flow.
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  /// Creates scanner state that owns camera and ML Kit resources.
  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

/// Coordinates camera frames, ML Kit barcode detection, and scan completion.
class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  /// ML Kit scanner instance reused across camera frames.
  final BarcodeScanner _barcodeScanner = BarcodeScanner();

  /// Active camera controller for live preview and frame streaming.
  CameraController? _cameraController;

  /// Last available back camera selected for scanning.
  CameraDescription? _cameraDescription;

  /// Prevents multiple ML Kit calls from processing the same frame window.
  bool _isProcessingFrame = false;

  /// Prevents duplicate route pops after a barcode has been found.
  bool _hasScanned = false;

  /// Shows loading UI while camera permission and initialization resolve.
  bool _isInitializing = true;

  /// Shows whether torch mode is currently enabled.
  bool _isTorchEnabled = false;

  /// User-facing scanner setup problem, localized at build time.
  _ScannerError? _scannerError;

  /// Starts camera setup after the widget enters the tree.
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  /// Releases native camera and ML Kit resources to avoid leaks.
  @override
  void dispose() {
    _cameraController?.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  /// Builds the scanner preview, overlay, loading, and fallback states.
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
                Positioned.fill(child: _buildCameraLayer(l10n)),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _ScannerAppBar(
                    isTorchEnabled: _isTorchEnabled,
                    onBack: () => Navigator.of(context).maybePop(),
                    onToggleFlash: _toggleFlash,
                  ),
                ),
                const Center(child: _ScannerGuide()),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 28,
                  child: ElevatedButton.icon(
                    onPressed: _returnManualFallback,
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

  /// Initializes the back camera and begins streaming frames to ML Kit.
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _setScannerError(_ScannerError.unavailable);
        return;
      }

      _cameraDescription = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        _cameraDescription!,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      await controller.startImageStream(_processCameraImage);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isInitializing = false;
      });
    } on CameraException catch (error) {
      _setScannerError(
        _isPermissionError(error)
            ? _ScannerError.permissionDenied
            : _ScannerError.unavailable,
      );
    } catch (_) {
      _setScannerError(_ScannerError.unavailable);
    }
  }

  /// Converts camera frames into ML Kit input images and detects barcodes.
  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessingFrame || _hasScanned) {
      return;
    }

    _isProcessingFrame = true;

    try {
      final inputImage = _buildInputImage(image);
      if (inputImage == null) {
        return;
      }

      final barcodes = await _barcodeScanner.processImage(inputImage);
      final scannedValue = _firstValidBarcodeValue(barcodes);

      if (scannedValue == null || _hasScanned) {
        return;
      }

      _hasScanned = true;
      await _cameraController?.stopImageStream();

      if (mounted) {
        Navigator.of(context).pop(scannedValue);
      }
    } catch (error) {
      debugPrint('Barcode scan frame skipped: $error');
    } finally {
      _isProcessingFrame = false;
    }
  }

  /// Builds the camera preview, loading state, or permission error state.
  Widget _buildCameraLayer(AppLocalizations l10n) {
    final controller = _cameraController;

    if (_scannerError != null) {
      return _ScannerMessage(
        icon: Icons.no_photography_outlined,
        message: _scannerError == _ScannerError.permissionDenied
            ? l10n.cameraPermissionDenied
            : l10n.cameraUnavailable,
      );
    }

    if (_isInitializing ||
        controller == null ||
        !controller.value.isInitialized) {
      return _ScannerMessage(
        icon: Icons.camera_alt_outlined,
        message: l10n.initializingCamera,
        showProgress: true,
      );
    }

    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.previewSize?.height ?? 1,
          height: controller.value.previewSize?.width ?? 1,
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  /// Converts a camera frame into the format required by ML Kit.
  InputImage? _buildInputImage(CameraImage image) {
    final camera = _cameraDescription;
    if (camera == null || image.planes.length != 1) {
      return null;
    }

    final rotation = InputImageRotationValue.fromRawValue(
      camera.sensorOrientation,
    );
    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    if (rotation == null || format == null) {
      return null;
    }

    final supportedFormat =
        (Platform.isAndroid && format == InputImageFormat.nv21) ||
        (Platform.isIOS && format == InputImageFormat.bgra8888);
    if (!supportedFormat) {
      return null;
    }

    final plane = image.planes.first;
    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: plane.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: plane.bytes, metadata: metadata);
  }

  /// Selects the first non-empty barcode value returned by ML Kit.
  String? _firstValidBarcodeValue(List<Barcode> barcodes) {
    for (final barcode in barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  /// Toggles torch mode when the selected camera supports it.
  Future<void> _toggleFlash() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    try {
      final nextMode = _isTorchEnabled ? FlashMode.off : FlashMode.torch;
      await controller.setFlashMode(nextMode);
      if (mounted) {
        setState(() => _isTorchEnabled = !_isTorchEnabled);
      }
    } catch (error) {
      debugPrint('Unable to toggle scanner flash: $error');
    }
  }

  /// Returns placeholder data when users choose manual fallback.
  void _returnManualFallback() {
    Navigator.of(context).pop(PlaceholderDeviceData.tagNumber);
  }

  /// Records a scanner setup error and stops the loading state.
  void _setScannerError(_ScannerError error) {
    if (!mounted) {
      return;
    }

    setState(() {
      _scannerError = error;
      _isInitializing = false;
    });
  }

  /// Identifies camera permission failures from platform camera exceptions.
  bool _isPermissionError(CameraException error) {
    return error.code == 'CameraAccessDenied' ||
        error.code == 'CameraAccessDeniedWithoutPrompt' ||
        error.code == 'CameraAccessRestricted';
  }
}

/// Scanner setup errors that need localized user-facing messages.
enum _ScannerError {
  /// User denied or restricted camera permission.
  permissionDenied,

  /// No camera is available or the camera could not be initialized.
  unavailable,
}

/// Top scanner controls for back navigation, title, and flash control.
class _ScannerAppBar extends StatelessWidget {
  const _ScannerAppBar({
    required this.isTorchEnabled,
    required this.onBack,
    required this.onToggleFlash,
  });

  /// Shows active torch state in the flash icon.
  final bool isTorchEnabled;

  /// Callback used by the parent to leave the scanner.
  final VoidCallback onBack;

  /// Callback used to toggle torch mode.
  final VoidCallback onToggleFlash;

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
            color: isTorchEnabled ? AppTheme.primaryBlue : Colors.white,
            icon: Icon(isTorchEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: onToggleFlash,
          ),
        ],
      ),
    );
  }
}

/// Displays loading or error information over the scanner background.
class _ScannerMessage extends StatelessWidget {
  const _ScannerMessage({
    required this.icon,
    required this.message,
    this.showProgress = false,
  });

  /// Icon that identifies the current scanner state.
  final IconData icon;

  /// Localized message explaining the current scanner state.
  final String message;

  /// Shows a progress indicator while camera initialization is pending.
  final bool showProgress;

  /// Builds the centered scanner status card.
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
      child: Container(
        color: Colors.black.withValues(alpha: 0.42),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 38),
            const SizedBox(height: 16),
            if (showProgress) ...[
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
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

    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Scale the scan target with the preview width while keeping phone proportions.
            final frameHeight = (constraints.maxWidth * 0.42).clamp(
              124.0,
              184.0,
            );

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
                  child: CustomPaint(painter: _ScanFramePainter()),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Paints the blue corner brackets and subtle frame scrim.
class _ScanFramePainter extends CustomPainter {
  /// Draws four corner brackets around the scan target area.
  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = AppTheme.primaryBlue
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final scrimPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    const cornerLength = 44.0;
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      scrimPaint,
    );

    canvas.drawLine(
      rect.topLeft,
      rect.topLeft + const Offset(cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      rect.topLeft,
      rect.topLeft + const Offset(0, cornerLength),
      borderPaint,
    );
    canvas.drawLine(
      rect.topRight,
      rect.topRight - const Offset(cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      rect.topRight,
      rect.topRight + const Offset(0, cornerLength),
      borderPaint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + const Offset(cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft - const Offset(0, cornerLength),
      borderPaint,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight - const Offset(cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight - const Offset(0, cornerLength),
      borderPaint,
    );
  }

  /// The frame is static, so repainting is unnecessary.
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
