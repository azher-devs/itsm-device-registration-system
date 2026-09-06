// Editable real-server settings used only by the iTop application entry point.

import '../core/config/itop_configuration.dart';

/// Contains the three values a supervisor must provide for real API testing.
class ITopConfig {
  const ITopConfig._();

  // Restore these placeholders before committing or sharing the project.
  static const baseUrl = 'https://your-itop-server';
  static const username = 'your_username';
  static const password = 'your_password';

  /// Adapts the editable constants to the shared API configuration model.
  static const configuration = ItopConfiguration(
    baseUrl: baseUrl,
    username: username,
    password: password,
  );
}
