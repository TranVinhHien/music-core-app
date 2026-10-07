import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'app_config.dart';
import 'dependencies.dart';
import 'provider_observer.dart';

/// Starts the app with a fully explicit flavor configuration.
void bootstrap(AppConfig config) {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      observers: [if (config.enableDiagnostics) const DiagnosticsObserver()],
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const App(),
    ),
  );
}
