import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../../app/dependencies.dart';
import '../../../core/result.dart';
import '../domain/value_objects/task_title.dart';

part 'task_actions_controller.g.dart';

/// Runs task mutations and exposes their loading/error state to the view.
@riverpod
class TaskActionsController extends _$TaskActionsController {
  @override
  Future<void> build() async {}

  Future<void> create(String rawTitle) => _runTitleMutation(
    rawTitle,
    (ownerId, title) => ref
        .read(taskRepositoryProvider)
        .createTask(ownerId: ownerId, title: title),
  );

  Future<void> rename(String id, String rawTitle) => _runTitleMutation(
    rawTitle,
    (ownerId, title) => ref
        .read(taskRepositoryProvider)
        .renameTask(ownerId: ownerId, id: id, title: title),
  );

  Future<void> setCompleted(String id, bool isCompleted) async {
    if (state.isLoading) return;
    final account = _accountId;
    if (account == null) return;
    await _run(
      () => ref
          .read(taskRepositoryProvider)
          .setCompleted(ownerId: account, id: id, isCompleted: isCompleted),
    );
  }

  Future<void> delete(String id) async {
    if (state.isLoading) return;
    final account = _accountId;
    if (account == null) return;
    await _run(
      () =>
          ref.read(taskRepositoryProvider).deleteTask(ownerId: account, id: id),
    );
  }

  String? get _accountId => ref.read(authControllerProvider).value?.user.id;

  Future<void> _runTitleMutation(
    String rawTitle,
    Future<Result<void>> Function(String ownerId, TaskTitle title) operation,
  ) async {
    if (state.isLoading) return;
    final title = TaskTitle.create(rawTitle);
    switch (title) {
      case ResultError(failure: final failure):
        _setFailure(failure);
      case ResultOk(value: final value):
        final account = _accountId;
        if (account == null) return;
        await _run(() => operation(account, value));
    }
  }

  Future<void> _run(Future<Result<void>> Function() operation) async {
    state = const AsyncLoading();
    final result = await operation();
    state = switch (result) {
      ResultOk() => const AsyncData(null),
      ResultError(failure: final failure) => AsyncError(
        failure,
        StackTrace.current,
      ),
    };
  }

  void _setFailure(AppFailure failure) {
    state = AsyncError(failure, StackTrace.current);
  }
}
