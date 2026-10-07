// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the app-wide active Demo account and its session commands.

@ProviderFor(AuthController)
final authControllerProvider = AuthControllerProvider._();

/// Owns the app-wide active Demo account and its session commands.
final class AuthControllerProvider
    extends $AsyncNotifierProvider<AuthController, DemoAccount?> {
  /// Owns the app-wide active Demo account and its session commands.
  AuthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authControllerHash();

  @$internal
  @override
  AuthController create() => AuthController();
}

String _$authControllerHash() => r'5882e231ddace1274ff58b5e74018380d329aa17';

/// Owns the app-wide active Demo account and its session commands.

abstract class _$AuthController extends $AsyncNotifier<DemoAccount?> {
  FutureOr<DemoAccount?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DemoAccount?>, DemoAccount?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DemoAccount?>, DemoAccount?>,
              AsyncValue<DemoAccount?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
