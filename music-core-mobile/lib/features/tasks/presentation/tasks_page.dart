import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/app_localizations_resolver.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/auth_failure_message.dart';
import '../domain/entities/task_filter.dart';
import 'task_actions_controller.dart';
import 'task_editor_sheet.dart';
import 'task_failure_message.dart';
import 'task_filter_controller.dart';
import 'task_list_view.dart';
import 'task_widget_keys.dart';

/// Displays and mutates the current account's local tasks.
class TasksPage extends ConsumerWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = appLocalizationsOf(context);

    ref.listen<AsyncValue<void>>(taskActionsControllerProvider, (_, next) {
      final error = next.error;
      if (error is! AppFailure || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(taskFailureMessage(error, localizations))),
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.tasksTitle),
        actions: [
          const _AccountEmail(),
          _SignOutButton(localizations: localizations),
        ],
      ),
      body: Column(
        children: [
          _TaskFilterBar(localizations: localizations),
          const Expanded(child: TaskListView()),
        ],
      ),
      floatingActionButton: _AddTaskButton(localizations: localizations),
    );
  }
}

class _AccountEmail extends ConsumerWidget {
  const _AccountEmail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(
      authControllerProvider.select((state) => state.value?.user.email),
    );
    if (email == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Center(child: Text(email)),
    );
  }
}

class _SignOutButton extends ConsumerWidget {
  const _SignOutButton({required this.localizations});

  final AppLocalizations localizations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authLoading = ref.watch(
      authControllerProvider.select((state) => state.isLoading),
    );
    final taskActionLoading = ref.watch(
      taskActionsControllerProvider.select((state) => state.isLoading),
    );

    return IconButton(
      key: TaskWidgetKeys.logoutButton,
      tooltip: localizations.logout,
      onPressed: authLoading || taskActionLoading
          ? null
          : () => _signOut(context, ref),
      icon: const Icon(Icons.logout),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final failure = await ref.read(authControllerProvider.notifier).signOut();
    if (!context.mounted || failure == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(authFailureMessage(failure, localizations))),
    );
  }
}

class _TaskFilterBar extends ConsumerWidget {
  const _TaskFilterBar({required this.localizations});

  final AppLocalizations localizations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(taskFilterControllerProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: SegmentedButton<TaskFilter>(
        segments: [
          ButtonSegment(
            value: TaskFilter.all,
            label: Text(localizations.filterAll),
          ),
          ButtonSegment(
            value: TaskFilter.active,
            label: Text(localizations.filterActive),
          ),
          ButtonSegment(
            value: TaskFilter.completed,
            label: Text(localizations.filterCompleted),
          ),
        ],
        selected: {filter},
        onSelectionChanged: (selection) {
          final selected = selection.isEmpty ? null : selection.first;
          if (selected == null) return;
          ref.read(taskFilterControllerProvider.notifier).select(selected);
        },
      ),
    );
  }
}

class _AddTaskButton extends ConsumerWidget {
  const _AddTaskButton({required this.localizations});

  final AppLocalizations localizations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      taskActionsControllerProvider.select((state) => state.isLoading),
    );

    return FloatingActionButton.extended(
      key: TaskWidgetKeys.addTaskButton,
      onPressed: isLoading ? null : () => _createTask(context, ref),
      icon: const Icon(Icons.add),
      label: Text(localizations.addTask),
    );
  }

  Future<void> _createTask(BuildContext context, WidgetRef ref) async {
    final title = await TaskEditorSheet.show(context);
    if (!context.mounted || title == null) return;
    await ref.read(taskActionsControllerProvider.notifier).create(title);
  }
}
