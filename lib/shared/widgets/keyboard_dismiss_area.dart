// Reusable wrapper that dismisses the keyboard when users tap outside inputs.

import 'package:flutter/material.dart';

/// Allows form screens to dismiss the active keyboard without affecting scroll.
class KeyboardDismissArea extends StatelessWidget {
  const KeyboardDismissArea({required this.child, super.key});

  /// Screen content that should support tap-to-dismiss behavior.
  final Widget child;

  /// Builds a translucent tap target around the screen content.
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      // Unfocus the active input so iOS and Android keyboards close naturally.
      onTap: () => FocusScope.of(context).unfocus(),
      child: child,
    );
  }
}
