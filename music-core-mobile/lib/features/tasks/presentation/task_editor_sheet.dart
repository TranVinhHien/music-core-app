import 'package:flutter/material.dart';

import '../../../l10n/app_localizations_resolver.dart';
import '../domain/entities/task_item.dart';
import 'task_widget_keys.dart';

/// Edits the title for a new or existing task.
class TaskEditorSheet extends StatefulWidget {
  const TaskEditorSheet({super.key, this.task});

  final TaskItem? task;

  static Future<String?> show(BuildContext context, {TaskItem? task}) =>
      showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => TaskEditorSheet(task: task),
      );

  @override
  State<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<TaskEditorSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.task?.title,
  );
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = appLocalizationsOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.task == null
                  ? localizations.addTask
                  : localizations.editTask,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: TaskWidgetKeys.titleInput,
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: localizations.taskTitleLabel,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? localizations.taskTitleRequired
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(localizations.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: TaskWidgetKeys.saveButton,
                  onPressed: () {
                    final formState = _formKey.currentState;
                    if (formState?.validate() != true) return;
                    Navigator.pop(context, _controller.text);
                  },
                  child: Text(localizations.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
