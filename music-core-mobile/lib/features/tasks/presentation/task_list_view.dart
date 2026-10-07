import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/app_localizations_resolver.dart';
import '../domain/entities/task_item.dart';
import 'task_actions_controller.dart';
import 'task_editor_sheet.dart';
import 'task_failure_message.dart';
import 'task_list_provider.dart';
import 'task_widget_keys.dart';

/// Displays the current account's task stream and row-level actions.
class TaskListView extends ConsumerWidget {
  const TaskListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = appLocalizationsOf(context);
    final tasks = ref.watch(taskListProvider);

    return tasks.when(
      data: (items) => items.isEmpty
          ? _EmptyTasks(localizations: localizations)
          : _TaskList(items: items, localizations: localizations),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _TaskError(
        message: error is AppFailure
            ? taskFailureMessage(error, localizations)
            : localizations.unexpectedError,
        retryLabel: localizations.retry,
        onRetry: () => ref.invalidate(taskListProvider),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({required this.items, required this.localizations});

  final List<TaskItem> items;
  final AppLocalizations localizations;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final task = items[index];
        return Card(
          key: TaskWidgetKeys.taskCard(task.id),
          child: ListTile(
            leading: Consumer(
              builder: (context, ref, child) {
                final isLoading = ref.watch(
                  taskActionsControllerProvider.select(
                    (state) => state.isLoading,
                  ),
                );
                return Checkbox(
                  key: TaskWidgetKeys.taskCheckbox(task.id),
                  value: task.isCompleted,
                  onChanged: isLoading
                      ? null
                      : (value) => ref
                            .read(taskActionsControllerProvider.notifier)
                            .setCompleted(task.id, value ?? false),
                );
              },
            ),
            title: Text(
              task.title,
              key: TaskWidgetKeys.taskTitle(task.id),
              style: task.isCompleted
                  ? const TextStyle(decoration: TextDecoration.lineThrough)
                  : null,
            ),
            trailing: Consumer(
              builder: (context, ref, child) {
                final isLoading = ref.watch(
                  taskActionsControllerProvider.select(
                    (state) => state.isLoading,
                  ),
                );
                return Wrap(
                  children: [
                    IconButton(
                      key: TaskWidgetKeys.editTaskButton(task.id),
                      tooltip: localizations.editTask,
                      onPressed: isLoading
                          ? null
                          : () => _editTask(context, ref, task),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      key: TaskWidgetKeys.deleteTaskButton(task.id),
                      tooltip: localizations.deleteTask,
                      onPressed: isLoading
                          ? null
                          : () => _deleteTask(context, ref, task),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _editTask(
    BuildContext context,
    WidgetRef ref,
    TaskItem task,
  ) async {
    final title = await TaskEditorSheet.show(context, task: task);
    if (!context.mounted || title == null) return;
    await ref
        .read(taskActionsControllerProvider.notifier)
        .rename(task.id, title);
  }

  Future<void> _deleteTask(
    BuildContext context,
    WidgetRef ref,
    TaskItem task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.deleteTask),
        content: Text(localizations.deleteTaskConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(localizations.deleteTask),
          ),
        ],
      ),
    );
    if (!context.mounted || confirmed != true) return;
    await ref.read(taskActionsControllerProvider.notifier).delete(task.id);
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks({required this.localizations});

  final AppLocalizations localizations;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.checklist_outlined, size: 56),
            const SizedBox(height: 16),
            Text(
              localizations.emptyTasksTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(localizations.emptyTasksMessage, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _TaskError extends StatelessWidget {
  const _TaskError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}
