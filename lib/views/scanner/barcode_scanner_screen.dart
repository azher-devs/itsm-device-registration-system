// Barcode scanner screen backed by the device camera and Google ML Kit.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

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

  /// Opens the platform image library for a single selected image.
  final ImagePicker _imagePicker = ImagePicker();

  /// Active camera controller for live preview and frame streaming.
  CameraController? _cameraController;

  /// Last available back camera selected for scanning.
  CameraDescription? _cameraDescription;

  /// Prevents multiple ML Kit calls from processing the same frame window.
  bool _isProcessingFrame = false;

  /// Prevents duplicate route pops after a barcode has been found.
  bool _hasScanned = false;

  /// Disables scanner actions and shows progress while processing a gallery image.
  bool _isProcessingGallery = false;

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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _GalleryScanButton(
                        label: l10n.scanFromGallery,
                        isLoading: _isProcessingGallery,
                        onPressed: _isProcessingGallery || _hasScanned
                            ? null
                            : _scanFromGallery,
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isProcessingGallery
                              ? null
                              : _returnManualFallback,
                          icon: const Icon(Icons.keyboard_alt_outlined),
                          label: Text(l10n.manualEntry),
                        ),
                      ),
                    ],
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
    if (_isProcessingFrame || _isProcessingGallery || _hasScanned) {
      return;
    }

    _isProcessingFrame = true;

    try {
      final inputImage = _buildInputImage(image);
      if (inputImage == null) {
        return;
      }

      final scannedValue = await _processInputImage(inputImage);

      if (scannedValue == null || _hasScanned) {
        return;
      }

      await _completeScan(scannedValue);
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

  /// Runs ML Kit for both live camera frames and selected gallery images.
  Future<String?> _processInputImage(InputImage inputImage) async {
    final barcodes = await _barcodeScanner.processImage(inputImage);
    return _firstValidBarcodeValue(barcodes);
  }

  /// Returns one barcode result and prevents camera/gallery duplicate pops.
  Future<void> _completeScan(String scannedValue) async {
    if (_hasScanned) {
      return;
    }

    _hasScanned = true;
    await _pauseCameraStream();

    if (mounted) {
      Navigator.of(context).pop(scannedValue);
    }
  }

  /// Selects and scans one gallery image while preserving the camera fallback.
  Future<void> _scanFromGallery() async {
    if (_isProcessingGallery || _hasScanned) {
      return;
    }

    var shouldRetry = false;
    setState(() => _isProcessingGallery = true);

    try {
      if (!await _requestGalleryPermissionIfNeeded()) {
        return;
      }

      await _pauseCameraStream();
      final selectedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );

      // Closing the platform picker without a selection is not an error.
      if (selectedImage == null) {
        return;
      }

      await _waitForCameraFrame();
      final scannedValue = await _processInputImage(
        InputImage.fromFilePath(selectedImage.path),
      );

      if (scannedValue != null) {
        await _completeScan(scannedValue);
        return;
      }

      if (mounted) {
        final action = await _showNoBarcodeDialog();
        shouldRetry = action == _GalleryScanAction.tryAgain;
      }
    } on PlatformException catch (error) {
      if (_isGalleryPermissionError(error)) {
        await _showGalleryPermissionDialog();
      } else {
        debugPrint('Unable to scan selected gallery image: $error');
        _showGalleryScanFailure();
      }
    } catch (error) {
      debugPrint('Unable to scan selected gallery image: $error');
      _showGalleryScanFailure();
    } finally {
      if (mounted && !_hasScanned) {
        setState(() => _isProcessingGallery = false);
      }
      if (!_hasScanned) {
        await _resumeCameraStream();
      }
    }

    if (shouldRetry && mounted && !_hasScanned) {
      await _scanFromGallery();
    }
  }

  /// Requests photo access on iOS; Android uses the scoped system picker.
  Future<bool> _requestGalleryPermissionIfNeeded() async {
    if (!Platform.isIOS) {
      return true;
    }

    final currentStatus = await Permission.photos.status;
    if (currentStatus.isGranted || currentStatus.isLimited) {
      return true;
    }

    final requestedStatus = await Permission.photos.request();
    if (requestedStatus.isGranted || requestedStatus.isLimited) {
      return true;
    }

    await _showGalleryPermissionDialog();
    return false;
  }

  /// Explains denied gallery access and lets the user open app settings.
  Future<void> _showGalleryPermissionDialog() async {
    if (!mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    final shouldOpenSettings = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.galleryPermissionTitle),
        content: Text(l10n.galleryPermissionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.useCamera),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.openSettings),
          ),
        ],
      ),
    );

    if (shouldOpenSettings == true) {
      await openAppSettings();
    }
  }

  /// Offers another gallery selection or an immediate return to the camera.
  Future<_GalleryScanAction?> _showNoBarcodeDialog() {
    final l10n = AppLocalizations.of(context);
    return showGeneralDialog<_GalleryScanAction>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.62),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: SafeArea(
            child: Center(
              child: NoBarcodeFoundDialog(
                title: l10n.noBarcodeFoundTitle,
                description: l10n.noBarcodeFoundMessage,
                useCameraLabel: l10n.useCamera,
                tryAgainLabel: l10n.tryAgain,
                onUseCamera: () => Navigator.of(
                  dialogContext,
                ).pop(_GalleryScanAction.useCamera),
                onTryAgain: () => Navigator.of(
                  dialogContext,
                ).pop(_GalleryScanAction.tryAgain),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  /// Shows a brief localized message for non-permission gallery failures.
  void _showGalleryScanFailure() {
    if (!mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.galleryScanFailed)));
  }

  /// Stops new frames before ML Kit starts processing a selected image.
  Future<void> _pauseCameraStream() async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        !controller.value.isStreamingImages) {
      return;
    }

    try {
      await controller.stopImageStream();
    } on CameraException catch (error) {
      debugPrint('Unable to pause camera stream: $error');
    }
  }

  /// Restarts the default camera scanner after cancel or unsuccessful selection.
  Future<void> _resumeCameraStream() async {
    final controller = _cameraController;
    if (!mounted ||
        _hasScanned ||
        controller == null ||
        !controller.value.isInitialized ||
        controller.value.isStreamingImages) {
      return;
    }

    try {
      await controller.startImageStream(_processCameraImage);
    } on CameraException catch (error) {
      debugPrint('Unable to resume camera stream: $error');
    }
  }

  /// Waits briefly for an in-flight camera frame before scanning a file.
  Future<void> _waitForCameraFrame() async {
    for (var attempt = 0; attempt < 40 && _isProcessingFrame; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
  }

  /// Recognizes platform image-picker permission failures.
  bool _isGalleryPermissionError(PlatformException error) {
    final details = '${error.code} ${error.message ?? ''}'.toLowerCase();
    return details.contains('permission') ||
        details.contains('access_denied') ||
        details.contains('photo_access_denied');
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

  /// Lets users return any typed tag when camera scanning is unavailable.
  Future<void> _returnManualFallback() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.manualTagEntry),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(hintText: l10n.enterTagNumber),
          onSubmitted: (value) {
            final normalized = value.trim();
            if (normalized.isNotEmpty) {
              Navigator.of(dialogContext).pop(normalized);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final normalized = controller.text.trim();
              if (normalized.isNotEmpty) {
                Navigator.of(dialogContext).pop(normalized);
              }
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    controller.dispose();

    if (mounted && tag != null) {
      Navigator.of(context).pop(tag);
    }
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

/// User choice after ML Kit finds no barcode in a selected image.
enum _GalleryScanAction { tryAgain, useCamera }

/// Responsive Material dialog shown when a selected image has no barcode.
class NoBarcodeFoundDialog extends StatelessWidget {
  const NoBarcodeFoundDialog({
    required this.title,
    required this.description,
    required this.useCameraLabel,
    required this.tryAgainLabel,
    required this.onUseCamera,
    required this.onTryAgain,
    super.key,
  });

  final String title;
  final String description;
  final String useCameraLabel;
  final String tryAgainLabel;
  final VoidCallback onUseCamera;
  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Material(
          color: Colors.white,
          elevation: 24,
          shadowColor: Colors.black.withValues(alpha: 0.28),
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(30),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NoBarcodeIllustration(semanticLabel: title),
                const SizedBox(height: 24),
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF0B1B38),
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    final stackButtons =
                        constraints.maxWidth < 320 || textScale > 1.3;

                    if (stackButtons) {
                      return Column(
                        children: [
                          _NoBarcodeActionButton(
                            label: useCameraLabel,
                            icon: Icons.camera_alt_outlined,
                            isFilled: false,
                            onPressed: onUseCamera,
                          ),
                          const SizedBox(height: 12),
                          _NoBarcodeActionButton(
                            label: tryAgainLabel,
                            icon: Icons.refresh_rounded,
                            isFilled: true,
                            onPressed: onTryAgain,
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: _NoBarcodeActionButton(
                            label: useCameraLabel,
                            icon: Icons.camera_alt_outlined,
                            isFilled: false,
                            onPressed: onUseCamera,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _NoBarcodeActionButton(
                            label: tryAgainLabel,
                            icon: Icons.refresh_rounded,
                            isFilled: true,
                            onPressed: onTryAgain,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Decorative barcode illustration used as the dialog's visual focus.
class _NoBarcodeIllustration extends StatelessWidget {
  const _NoBarcodeIllustration({required this.semanticLabel});

  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel,
      child: SizedBox.square(
        dimension: 116,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 8,
              left: 8,
              child: _DecorationDot(
                color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                size: 7,
              ),
            ),
            const Positioned(
              top: 14,
              right: 5,
              child: _DecorationDot(color: Color(0xFFFF8A9B), size: 7),
            ),
            Positioned(
              bottom: 12,
              left: 3,
              child: _DecorationDot(
                color: AppTheme.primaryBlue.withValues(alpha: 0.18),
                size: 6,
              ),
            ),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: AppTheme.primaryBlue,
                size: 46,
              ),
            ),
            Positioned(
              right: 9,
              bottom: 10,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small accent dot surrounding the barcode illustration.
class _DecorationDot extends StatelessWidget {
  const _DecorationDot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: SizedBox.square(dimension: size),
    );
  }
}

/// Consistent camera and retry actions used by the no-barcode dialog.
class _NoBarcodeActionButton extends StatelessWidget {
  const _NoBarcodeActionButton({
    required this.label,
    required this.icon,
    required this.isFilled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isFilled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final buttonHeight = (54 + ((textScale - 1) * 18)).clamp(54.0, 72.0);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 21),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: double.infinity,
        height: buttonHeight,
        child: isFilled
            ? FilledButton(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: shape,
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: child,
              )
            : OutlinedButton(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                  side: BorderSide(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.42),
                    width: 1.5,
                  ),
                  shape: shape,
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: child,
              ),
      ),
    );
  }
}

/// Compact gallery action placed above the existing manual entry button.
class _GalleryScanButton extends StatelessWidget {
  const _GalleryScanButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const Key('scan_from_gallery_button'),
      onPressed: onPressed,
      icon: isLoading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.photo_library_outlined),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white70,
        backgroundColor: Colors.black.withValues(alpha: 0.38),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.38)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        shape: const StadiumBorder(),
      ),
    );
  }
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
