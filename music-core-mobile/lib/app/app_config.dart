/// Runtime configuration that intentionally contains no secrets.
final class AppConfig {
  const AppConfig({
    required this.applicationName,
    required this.databaseName,
    required this.enableDiagnostics,
    this.apiBaseUrl = 'http://localhost:8000',
  });

  static const String _defaultDevUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  const AppConfig.dev({
    String? apiBaseUrl,
  }) : this(
         applicationName: '(DEV) Music Core',
         databaseName: 'music_core_app_dev',
         enableDiagnostics: true,
         apiBaseUrl: apiBaseUrl ?? _defaultDevUrl,
       );

  const AppConfig.prod({
    String? apiBaseUrl,
  }) : this(
         applicationName: 'Music Core',
         databaseName: 'music_core_app_prod',
         enableDiagnostics: false,
         apiBaseUrl: apiBaseUrl ?? 'http://localhost:8000',
       );

  final String applicationName;
  final String databaseName;
  final bool enableDiagnostics;
  final String apiBaseUrl;
}
