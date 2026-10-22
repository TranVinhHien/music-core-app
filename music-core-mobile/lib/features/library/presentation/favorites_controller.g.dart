// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorites_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FavoritesController)
final favoritesControllerProvider = FavoritesControllerProvider._();

final class FavoritesControllerProvider
    extends $AsyncNotifierProvider<FavoritesController, List<TrackEntity>> {
  FavoritesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoritesControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoritesControllerHash();

  @$internal
  @override
  FavoritesController create() => FavoritesController();
}

String _$favoritesControllerHash() =>
    r'00b1a9ec60cdaf65c3e280af7235b7043d180b69';

abstract class _$FavoritesController extends $AsyncNotifier<List<TrackEntity>> {
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
