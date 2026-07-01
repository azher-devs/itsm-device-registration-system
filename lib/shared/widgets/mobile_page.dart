// Shared mobile-width page wrapper.

import 'package:flutter/material.dart';

/// Constrains mobile screens to a readable phone-width layout.
class MobilePage extends StatelessWidget {
  const MobilePage({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.maxWidth = 430,
    this.scrollable = true,
  });

  /// Screen content rendered inside the mobile width constraint.
  final Widget child;

  /// Padding applied around the constrained content.
  final EdgeInsetsGeometry padding;

  /// Maximum readable content width used on tablets and foldables.
  final double maxWidth;

  /// Enables scrolling when a screen can exceed the viewport height.
  final bool scrollable;

  /// Builds either a fixed-height or scrollable mobile page shell.
  @override
  Widget build(BuildContext context) {
    // A max width keeps web/desktop previews close to phone proportions.
    final content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );

    // Splash and scanner-like screens can opt out of scroll behavior.
    if (!scrollable) {
      return content;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // The minimum height lets short screens still center within the viewport.
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: content,
          ),
        );
      },
    );
  }
}
