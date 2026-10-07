// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_actions_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Runs task mutations and exposes their loading/error state to the view.

@ProviderFor(TaskActionsController)
final taskActionsControllerProvider = TaskActionsControllerProvider._();

/// Runs task mutations and exposes their loading/error state to the view.
final class TaskActionsControllerProvider
    extends $AsyncNotifierProvider<TaskActionsController, void> {
  /// Runs task mutations and exposes their loading/error state to the view.
  TaskActionsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskActionsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskActionsControllerHash();

  @$internal
  @override
  TaskActionsController create() => TaskActionsController();
}

String _$taskActionsControllerHash() =>
    r'4e35b07e8bf49a1337d2f55e9c3a827d9cfad6bd';

/// Runs task mutations and exposes their loading/error state to the view.

abstract class _$TaskActionsController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
