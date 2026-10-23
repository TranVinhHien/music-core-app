import 'package:flutter/foundation.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:just_audio_platform_interface/method_channel_just_audio.dart';

/// Wraps [JustAudioPlatform] to allow secondary player instances (such as Deck B in dual-deck crossfade)
/// to operate natively without triggering `PlatformException(error, just_audio_background supports only a single player instance)`.
class MultiDeckJustAudioPlatform extends JustAudioPlatform {
  final JustAudioPlatform _backgroundPlatform;
  final JustAudioPlatform _rawPlatform;
  String? _backgroundPlayerId;

  MultiDeckJustAudioPlatform._({
    required JustAudioPlatform backgroundPlatform,
    required JustAudioPlatform rawPlatform,
  })  : _backgroundPlatform = backgroundPlatform,
        _rawPlatform = rawPlatform;

  /// Installs the multi-deck platform wrapper over the current platform instance.
  static void install() {
    final current = JustAudioPlatform.instance;
    if (current is! MultiDeckJustAudioPlatform) {
      JustAudioPlatform.instance = MultiDeckJustAudioPlatform._(
        backgroundPlatform: current,
        rawPlatform: MethodChannelJustAudio(),
      );
      debugPrint('[MultiDeckJustAudioPlatform] Multi-deck platform installed successfully.');
    }
  }

  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    // First player instance gets the background notification / lock screen capability
    if (_backgroundPlayerId == null) {
      _backgroundPlayerId = request.id;
      return _backgroundPlatform.init(request);
    }

    // Secondary player instance uses the raw platform channel without single-instance restriction
    return _rawPlatform.init(request);
  }

  @override
  Future<DisposePlayerResponse> disposePlayer(DisposePlayerRequest request) async {
    if (request.id == _backgroundPlayerId) {
      _backgroundPlayerId = null;
      return _backgroundPlatform.disposePlayer(request);
    }
    return _rawPlatform.disposePlayer(request);
  }

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(DisposeAllPlayersRequest request) async {
    _backgroundPlayerId = null;
    await _backgroundPlatform.disposeAllPlayers(request);
    await _rawPlatform.disposeAllPlayers(request);
    return DisposeAllPlayersResponse();
  }
}
