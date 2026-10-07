import 'package:flutter/widgets.dart';

/// Stable widget keys owned by the tasks presentation layer.
abstract final class TaskWidgetKeys {
  static const logoutButton = Key('logout_button');
  static const addTaskButton = Key('add_task_button');
  static const titleInput = Key('task_title_input');
  static const saveButton = Key('save_task_button');

  static ValueKey<String> taskCard(String id) => ValueKey('task_$id');

  static ValueKey<String> taskCheckbox(String id) =>
      ValueKey('task_checkbox_$id');

  static ValueKey<String> taskTitle(String id) => ValueKey('task_title_$id');

  static ValueKey<String> editTaskButton(String id) =>
      ValueKey('edit_task_$id');

  static ValueKey<String> deleteTaskButton(String id) =>
      ValueKey('delete_task_$id');
}
