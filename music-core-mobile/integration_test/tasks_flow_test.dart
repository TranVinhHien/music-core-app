import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture_example/features/auth/data/session_storage.dart';
import 'package:flutter_clean_architecture_example/features/auth/presentation/auth_widget_keys.dart';
import 'package:flutter_clean_architecture_example/features/tasks/presentation/task_widget_keys.dart';
import 'package:flutter_clean_architecture_example/main_dev.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('signs in and completes the task lifecycle', (tester) async {
    await SharedPreferencesAsync().remove(
      SharedPreferencesSessionStorage.activeAccountKey,
    );
    app.main();
    await tester.pumpAndSettle();

    if (find.byKey(TaskWidgetKeys.logoutButton).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(TaskWidgetKeys.logoutButton));
      await tester.pumpAndSettle();
    }

    await tester.enterText(
      find.byKey(AuthWidgetKeys.loginEmail),
      'alice@example.com',
    );
    await tester.enterText(
      find.byKey(AuthWidgetKeys.loginPassword),
      'demo1234',
    );
    await tester.tap(find.byKey(AuthWidgetKeys.loginButton));
    await tester.pumpAndSettle();

    expect(find.byKey(TaskWidgetKeys.addTaskButton), findsOneWidget);

    final taskTitle =
        'Integration task ${DateTime.now().microsecondsSinceEpoch}';
    await tester.tap(find.byKey(TaskWidgetKeys.addTaskButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(TaskWidgetKeys.titleInput), taskTitle);
    await tester.tap(find.byKey(TaskWidgetKeys.saveButton));
    await tester.pumpAndSettle();

    expect(find.text(taskTitle), findsOneWidget);
    final taskCard = find.ancestor(
      of: find.text(taskTitle),
      matching: find.byType(Card),
    );
    await tester.tap(
      find.descendant(of: taskCard, matching: find.byType(Checkbox)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();
    expect(find.text(taskTitle), findsOneWidget);

    await tester.tap(find.text('Active'));
    await tester.pumpAndSettle();
    expect(find.text(taskTitle), findsNothing);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(of: taskCard, matching: find.byTooltip('Edit task')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(TaskWidgetKeys.titleInput),
      'Renamed integration task',
    );
    await tester.tap(find.byKey(TaskWidgetKeys.saveButton));
    await tester.pumpAndSettle();

    expect(find.text('Renamed integration task'), findsOneWidget);

    await tester.tap(find.byKey(TaskWidgetKeys.logoutButton));
    await tester.pumpAndSettle();
    expect(find.byKey(AuthWidgetKeys.loginButton), findsOneWidget);

    await tester.enterText(
      find.byKey(AuthWidgetKeys.loginEmail),
      'alice@example.com',
    );
    await tester.enterText(
      find.byKey(AuthWidgetKeys.loginPassword),
      'demo1234',
    );
    await tester.tap(find.byKey(AuthWidgetKeys.loginButton));
    await tester.pumpAndSettle();
    expect(find.text('Renamed integration task'), findsOneWidget);

    final renamedCard = find.ancestor(
      of: find.text('Renamed integration task'),
      matching: find.byType(Card),
    );
    await tester.tap(
      find.descendant(of: renamedCard, matching: find.byTooltip('Delete task')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete task'));
    await tester.pumpAndSettle();

    expect(find.text('Renamed integration task'), findsNothing);
  });
}
