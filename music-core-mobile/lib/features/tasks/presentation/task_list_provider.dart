import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/dependencies.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/entities/task_item.dart';
import 'task_filter_controller.dart';

part 'task_list_provider.g.dart';

/// Exposes the account-scoped task stream to the task view.
@riverpod
Stream<List<TaskItem>> taskList(Ref ref) async* {
  final accountId = ref.watch(authControllerProvider).value?.id;
  if (accountId == null) return;

  final filter = ref.watch(taskFilterControllerProvider);
  yield* ref
      .read(taskRepositoryProvider)
      .watchTasks(ownerId: accountId, filter: filter);
}
