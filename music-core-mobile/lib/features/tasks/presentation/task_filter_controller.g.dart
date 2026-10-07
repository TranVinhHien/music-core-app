// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_filter_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the task filter for the lifetime of the task screen.

@ProviderFor(TaskFilterController)
final taskFilterControllerProvider = TaskFilterControllerProvider._();

/// Owns the task filter for the lifetime of the task screen.
final class TaskFilterControllerProvider
    extends $NotifierProvider<TaskFilterController, TaskFilter> {
  /// Owns the task filter for the lifetime of the task screen.
  TaskFilterControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskFilterControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskFilterControllerHash();

  @$internal
  @override
  TaskFilterController create() => TaskFilterController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TaskFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TaskFilter>(value),
    );
  }
}

String _$taskFilterControllerHash() =>
    r'7740ca7dc7f1f4e21a4cc3e6b67bd4ad72bb8fb7';

/// Owns the task filter for the lifetime of the task screen.

abstract class _$TaskFilterController extends $Notifier<TaskFilter> {
  TaskFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TaskFilter, TaskFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TaskFilter, TaskFilter>,
              TaskFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
