/// Runtime configuration that intentionally contains no secrets.
final class AppConfig {
  const AppConfig({
    required this.applicationName,
    required this.databaseName,
    required this.enableDiagnostics,
  });

  const AppConfig.dev()
    : this(
        applicationName: '(DEV) Clean Architecture Example',
        databaseName: 'flutter_clean_architecture_example_dev',
        enableDiagnostics: true,
      );

  const AppConfig.prod()
    : this(
        applicationName: 'Clean Architecture Example',
        databaseName: 'flutter_clean_architecture_example_prod',
        enableDiagnostics: false,
      );

  final String applicationName;
  final String databaseName;
  final bool enableDiagnostics;
}
