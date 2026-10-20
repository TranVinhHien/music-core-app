import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app.dart';
import 'app_config.dart';
import 'dependencies.dart';
import 'provider_observer.dart';

/// Starts the app with a fully explicit flavor configuration.
Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.music_core.channel.audio',
    androidNotificationChannelName: 'Music Core Playback',
    androidNotificationOngoing: true,
  );
  runApp(
    ProviderScope(
      observers: [if (config.enableDiagnostics) const DiagnosticsObserver()],
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const App(),
    ),
  );
}
