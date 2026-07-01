// Shared ITSM logo widget.

import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';

/// Displays the ITSM logo with consistent sizing and image quality.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.width = 168, this.height});

  /// Uniform scale used to compensate for transparent padding in the logo PNG.
  static const double _presentationScale = 2.3;

  /// Desired rendered width for the logo in the current screen.
  final double width;

  /// Optional display frame height used to keep large logos balanced.
  final double? height;

  /// Builds the image from the centralized asset path.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use the resolved frame width so constrained parents do not shrink the logo back down.
        final frameWidth = constraints.maxWidth.isFinite
            ? width.clamp(0.0, constraints.maxWidth)
            : width;

        return SizedBox(
          width: frameWidth,
          height: height,
          child: ClipRect(
            child: OverflowBox(
              // Allow the PNG to grow beyond the frame so transparent padding is clipped.
              maxWidth: frameWidth * _presentationScale,
              minWidth: frameWidth * _presentationScale,
              child: Image.asset(
                AppAssets.logo,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        );
      },
    );
  }
}
