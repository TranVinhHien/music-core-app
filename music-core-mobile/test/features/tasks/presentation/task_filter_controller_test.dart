import 'package:flutter_clean_architecture_example/features/tasks/domain/entities/task_filter.dart';
import 'package:flutter_clean_architecture_example/features/tasks/presentation/task_filter_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selects a filter without notifying for the current value', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final values = <TaskFilter>[];
    final subscription = container.listen(
      taskFilterControllerProvider,
      (_, next) => values.add(next),
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final controller = container.read(taskFilterControllerProvider.notifier);
    controller.select(TaskFilter.all);
    controller.select(TaskFilter.active);
    controller.select(TaskFilter.active);
    controller.select(TaskFilter.completed);

    expect(values, [TaskFilter.all, TaskFilter.active, TaskFilter.completed]);
  });

  test('starts from all in a new provider scope', () {
    final first = ProviderContainer();
    first.read(taskFilterControllerProvider.notifier).select(TaskFilter.active);
    expect(first.read(taskFilterControllerProvider), TaskFilter.active);
    first.dispose();

    final second = ProviderContainer();
    addTearDown(second.dispose);
    expect(second.read(taskFilterControllerProvider), TaskFilter.all);
  });
}
