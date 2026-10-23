// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_transition_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controls whether intelligent Auto-DJ crossfade transition mode is enabled.
/// Persists the user preference locally via [SharedPreferencesAsync].

@ProviderFor(SmartTransitionController)
final smartTransitionControllerProvider = SmartTransitionControllerProvider._();

/// Controls whether intelligent Auto-DJ crossfade transition mode is enabled.
/// Persists the user preference locally via [SharedPreferencesAsync].
final class SmartTransitionControllerProvider
    extends $NotifierProvider<SmartTransitionController, bool> {
  /// Controls whether intelligent Auto-DJ crossfade transition mode is enabled.
  /// Persists the user preference locally via [SharedPreferencesAsync].
  SmartTransitionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'smartTransitionControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$smartTransitionControllerHash();

  @$internal
  @override
  SmartTransitionController create() => SmartTransitionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$smartTransitionControllerHash() =>
    r'd5b5a6f34f895b57186032c4396bd8effa00ba45';

/// Controls whether intelligent Auto-DJ crossfade transition mode is enabled.
/// Persists the user preference locally via [SharedPreferencesAsync].

abstract class _$SmartTransitionController extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
