// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'songs_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SongsQuery)
final songsQueryProvider = SongsQueryProvider._();

final class SongsQueryProvider extends $NotifierProvider<SongsQuery, String> {
  SongsQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'songsQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$songsQueryHash();

  @$internal
  @override
  SongsQuery create() => SongsQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$songsQueryHash() => r'e4930f10f1e53f86237454096b341b5e90e015e7';

abstract class _$SongsQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(SongsController)
final songsControllerProvider = SongsControllerProvider._();

final class SongsControllerProvider
    extends $AsyncNotifierProvider<SongsController, List<TrackEntity>> {
  SongsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'songsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$songsControllerHash();

  @$internal
  @override
  SongsController create() => SongsController();
}

String _$songsControllerHash() => r'51a8401fbff51f8f85788985f5a19fb2ea652584';

abstract class _$SongsController extends $AsyncNotifier<List<TrackEntity>> {
  FutureOr<List<TrackEntity>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<TrackEntity>>, List<TrackEntity>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<TrackEntity>>, List<TrackEntity>>,
              AsyncValue<List<TrackEntity>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
