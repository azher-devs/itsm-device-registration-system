// Compact reusable copy action for text-field suffix areas.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/clipboard_service.dart';

/// Combines an optional copy action with an existing field action.
class CopyableFieldSuffix extends StatelessWidget {
  const CopyableFieldSuffix({
    required this.controller,
    required this.copyTooltip,
    required this.copiedMessage,
    this.trailingAction,
    this.copyButtonKey,
    super.key,
  });

  final TextEditingController controller;
  final String copyTooltip;
  final String copiedMessage;
  final Widget? trailingAction;
  final Key? copyButtonKey;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final copyValue = value.text.trim();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (copyValue.isNotEmpty)
              _CopyValueButton(
                key: copyButtonKey,
                value: copyValue,
                tooltip: copyTooltip,
                copiedMessage: copiedMessage,
              ),
            ?trailingAction,
          ],
        );
      },
    );
  }
}

/// Copies one field value and provides short, non-queued feedback.
class _CopyValueButton extends ConsumerStatefulWidget {
  const _CopyValueButton({
    required this.value,
    required this.tooltip,
    required this.copiedMessage,
    super.key,
  });

  final String value;
  final String tooltip;
  final String copiedMessage;

  @override
  ConsumerState<_CopyValueButton> createState() => _CopyValueButtonState();
}

class _CopyValueButtonState extends ConsumerState<_CopyValueButton> {
  bool _isCopying = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: widget.tooltip,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      padding: const EdgeInsets.all(8),
      iconSize: 19,
      color: colorScheme.onSurfaceVariant,
      onPressed: _isCopying ? null : _copy,
      icon: const Icon(Icons.content_copy),
    );
  }

  /// Delegates platform work to the service and keeps feedback presentation local.
  Future<void> _copy() async {
    if (_isCopying) {
      return;
    }

    setState(() => _isCopying = true);
    try {
      await ref.read(clipboardServiceProvider).copy(widget.value);
      if (!mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(widget.copiedMessage),
            duration: const Duration(seconds: 1),
          ),
        );
    } on Object catch (error) {
      debugPrint('Unable to copy field value: $error');
    } finally {
      if (mounted) {
        setState(() => _isCopying = false);
      }
    }
  }
}
