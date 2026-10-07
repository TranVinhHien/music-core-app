import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/entities/task_filter.dart';

part 'task_filter_controller.g.dart';

/// Owns the task filter for the lifetime of the task screen.
@riverpod
class TaskFilterController extends _$TaskFilterController {
  @override
  TaskFilter build() => TaskFilter.all;

  void select(TaskFilter filter) {
    if (state == filter) return;
    state = filter;
  }
}
