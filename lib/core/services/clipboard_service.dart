// Reusable platform clipboard service for copying application values.

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contract that keeps platform clipboard calls outside presentation widgets.
abstract interface class ClipboardWriter {
  /// Copies one non-empty value to the system clipboard.
  Future<void> copy(String value);
}

/// Writes text through Flutter's platform clipboard integration.
class ClipboardService implements ClipboardWriter {
  const ClipboardService();

  @override
  Future<void> copy(String value) {
    return Clipboard.setData(ClipboardData(text: value));
  }
}

/// Provides one reusable clipboard writer and supports test overrides.
final clipboardServiceProvider = Provider<ClipboardWriter>((ref) {
  return const ClipboardService();
});
