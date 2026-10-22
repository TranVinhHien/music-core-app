// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlists_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PlaylistsController)
final playlistsControllerProvider = PlaylistsControllerProvider._();

final class PlaylistsControllerProvider
    extends $AsyncNotifierProvider<PlaylistsController, List<PlaylistEntity>> {
  PlaylistsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playlistsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playlistsControllerHash();

  @$internal
  @override
  PlaylistsController create() => PlaylistsController();
}

String _$playlistsControllerHash() =>
    r'91e3b224354952e29e43ca7942d264cef5d7cf34';

abstract class _$PlaylistsController
    extends $AsyncNotifier<List<PlaylistEntity>> {
  FutureOr<List<PlaylistEntity>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<PlaylistEntity>>, List<PlaylistEntity>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<PlaylistEntity>>,
                List<PlaylistEntity>
              >,
              AsyncValue<List<PlaylistEntity>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
