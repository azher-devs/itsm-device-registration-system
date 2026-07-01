// Shared primary action button.

import 'package:flutter/material.dart';

/// Shared primary button with optional leading icon.
class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
  });

  /// Button text shown to the user.
  final String label;

  /// Action triggered when the button is tapped.
  final VoidCallback? onPressed;

  /// Optional icon for actions that benefit from a visual cue.
  final IconData? icon;

  /// Builds an icon button only when an icon is provided.
  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      return ElevatedButton(onPressed: onPressed, child: Text(label));
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
    );
  }
}
