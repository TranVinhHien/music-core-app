// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_detail_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PlaylistDetailController)
final playlistDetailControllerProvider = PlaylistDetailControllerFamily._();

final class PlaylistDetailControllerProvider
    extends $AsyncNotifierProvider<PlaylistDetailController, PlaylistEntity> {
  PlaylistDetailControllerProvider._({
    required PlaylistDetailControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'playlistDetailControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$playlistDetailControllerHash();

  @override
  String toString() {
    return r'playlistDetailControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PlaylistDetailController create() => PlaylistDetailController();

  @override
  bool operator ==(Object other) {
    return other is PlaylistDetailControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playlistDetailControllerHash() =>
    r'd73bf136d36be063ca0bedd14dce7d62664ad1fc';

final class PlaylistDetailControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          PlaylistDetailController,
          AsyncValue<PlaylistEntity>,
          PlaylistEntity,
          FutureOr<PlaylistEntity>,
          String
        > {
  PlaylistDetailControllerFamily._()
    : super(
        retry: null,
        name: r'playlistDetailControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PlaylistDetailControllerProvider call(String playlistId) =>
      PlaylistDetailControllerProvider._(argument: playlistId, from: this);

  @override
  String toString() => r'playlistDetailControllerProvider';
}

abstract class _$PlaylistDetailController
    extends $AsyncNotifier<PlaylistEntity> {
  late final _$args = ref.$arg as String;
  String get playlistId => _$args;

  FutureOr<PlaylistEntity> build(String playlistId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PlaylistEntity>, PlaylistEntity>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PlaylistEntity>, PlaylistEntity>,
              AsyncValue<PlaylistEntity>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
