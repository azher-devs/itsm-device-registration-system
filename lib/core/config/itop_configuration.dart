// Central placeholder configuration for the future iTop server connection.

/// Holds every server-specific value that must be replaced for final integration.
class ItopConfiguration {
  const ItopConfiguration({
    required this.baseUrl,
    required this.username,
    required this.password,
  });

  /// Placeholder configuration retained for future API integration only.
  static const placeholder = ItopConfiguration(
    baseUrl: 'https://your-itop-instance.com',
    username: 'YOUR_USERNAME',
    password: 'YOUR_PASSWORD',
  );

  /// iTop host without the REST endpoint path.
  final String baseUrl;

  /// iTop API username sent as `auth_user`.
  final String username;

  /// iTop API password sent as `auth_pwd`.
  final String password;

  /// REST/JSON endpoint shared by all documented operations.
  static const restPath = '/webservices/rest.php?version=1.0';
}
