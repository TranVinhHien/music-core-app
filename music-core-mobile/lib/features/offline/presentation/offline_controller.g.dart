// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// State of active downloads: maps trackId to download percentage (0.0 - 1.0).

@ProviderFor(DownloadProgressController)
final downloadProgressControllerProvider =
    DownloadProgressControllerProvider._();

/// State of active downloads: maps trackId to download percentage (0.0 - 1.0).
final class DownloadProgressControllerProvider
    extends $NotifierProvider<DownloadProgressController, Map<String, double>> {
  /// State of active downloads: maps trackId to download percentage (0.0 - 1.0).
  DownloadProgressControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadProgressControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadProgressControllerHash();

  @$internal
  @override
  DownloadProgressController create() => DownloadProgressController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, double> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, double>>(value),
    );
  }
}

String _$downloadProgressControllerHash() =>
    r'cdebfb4c79658e350898c7d8bf1a1817e912374e';

/// State of active downloads: maps trackId to download percentage (0.0 - 1.0).

abstract class _$DownloadProgressController
    extends $Notifier<Map<String, double>> {
  Map<String, double> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Map<String, double>, Map<String, double>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, double>, Map<String, double>>,
              Map<String, double>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Real-time stream of all tracks saved locally on the device.

@ProviderFor(offlineTracksStream)
final offlineTracksStreamProvider = OfflineTracksStreamProvider._();

/// Real-time stream of all tracks saved locally on the device.

final class OfflineTracksStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TrackEntity>>,
          List<TrackEntity>,
          Stream<List<TrackEntity>>
        >
    with
        $FutureModifier<List<TrackEntity>>,
        $StreamProvider<List<TrackEntity>> {
  /// Real-time stream of all tracks saved locally on the device.
  OfflineTracksStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'offlineTracksStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$offlineTracksStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<TrackEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TrackEntity>> create(Ref ref) {
    return offlineTracksStream(ref);
  }
}

String _$offlineTracksStreamHash() =>
    r'913cc6ddb9746a71411bc9158e0edcebb880ad24';

/// Real-time stream of offline cached playlists.

@ProviderFor(offlinePlaylistsStream)
final offlinePlaylistsStreamProvider = OfflinePlaylistsStreamProvider._();

/// Real-time stream of offline cached playlists.

final class OfflinePlaylistsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlaylistEntity>>,
          List<PlaylistEntity>,
          Stream<List<PlaylistEntity>>
        >
    with
        $FutureModifier<List<PlaylistEntity>>,
        $StreamProvider<List<PlaylistEntity>> {
  /// Real-time stream of offline cached playlists.
  OfflinePlaylistsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'offlinePlaylistsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$offlinePlaylistsStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<PlaylistEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<PlaylistEntity>> create(Ref ref) {
    return offlinePlaylistsStream(ref);
  }
}

String _$offlinePlaylistsStreamHash() =>
    r'd3c3e26fb4a94a85f9f10c9d2776f4f29ac41427';

/// Real-time stream of offline cached favorites.

@ProviderFor(offlineFavoritesStream)
final offlineFavoritesStreamProvider = OfflineFavoritesStreamProvider._();

/// Real-time stream of offline cached favorites.

final class OfflineFavoritesStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TrackEntity>>,
          List<TrackEntity>,
          Stream<List<TrackEntity>>
        >
    with
        $FutureModifier<List<TrackEntity>>,
        $StreamProvider<List<TrackEntity>> {
  /// Real-time stream of offline cached favorites.
  OfflineFavoritesStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'offlineFavoritesStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$offlineFavoritesStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<TrackEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TrackEntity>> create(Ref ref) {
    return offlineFavoritesStream(ref);
  }
}

String _$offlineFavoritesStreamHash() =>
    r'd4c51ef98627fb46649b71150963c30470126c87';
