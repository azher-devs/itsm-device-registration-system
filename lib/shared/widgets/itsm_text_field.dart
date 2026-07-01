// Shared labeled text field used by form screens.

import 'package:flutter/material.dart';

/// Shared text field wrapper used to keep form spacing and styling consistent.
class ItsmTextField extends StatelessWidget {
  const ItsmTextField({
    required this.label,
    required this.hint,
    super.key,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.errorText,
    this.onChanged,
    this.obscureText = false,
    this.readOnly = false,
    this.keyboardType,
  });

  /// Optional field label displayed above the input.
  final String label;

  /// Placeholder text shown when the field is empty.
  final String hint;

  /// Controller used when the parent screen needs to read or prefill text.
  final TextEditingController? controller;

  /// Optional leading icon that clarifies the field purpose.
  final IconData? prefixIcon;

  /// Optional trailing widget, such as search or password visibility.
  final Widget? suffixIcon;

  /// Localized validation message shown when the input is invalid.
  final String? errorText;

  /// Called when text changes so parent forms can clear validation states.
  final ValueChanged<String>? onChanged;

  /// Enables secure entry for password-like fields.
  final bool obscureText;

  /// Prevents editing when a field is informational only.
  final bool readOnly;

  /// Keyboard type that matches the expected input.
  final TextInputType? keyboardType;

  /// Builds a labeled input while allowing login fields to omit labels.
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Login fields use icon-only context, so empty labels are intentionally hidden.
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          obscureText: obscureText,
          readOnly: readOnly,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
            suffixIcon: suffixIcon,
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}
