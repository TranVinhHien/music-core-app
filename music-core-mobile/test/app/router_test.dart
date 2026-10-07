import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture_example/app/dependencies.dart';
import 'package:flutter_clean_architecture_example/app/router.dart';
import 'package:flutter_clean_architecture_example/core/result.dart';
import 'package:flutter_clean_architecture_example/features/auth/domain/entities/demo_account.dart';
import 'package:flutter_clean_architecture_example/features/auth/domain/entities/demo_accounts.dart';
import 'package:flutter_clean_architecture_example/features/auth/presentation/auth_controller.dart';
import 'package:flutter_clean_architecture_example/features/auth/presentation/auth_widget_keys.dart';
import 'package:flutter_clean_architecture_example/features/tasks/domain/entities/task_filter.dart';
import 'package:flutter_clean_architecture_example/features/tasks/domain/entities/task_item.dart';
import 'package:flutter_clean_architecture_example/features/tasks/domain/repositories/task_repository.dart';
import 'package:flutter_clean_architecture_example/features/tasks/domain/value_objects/task_title.dart';
import 'package:flutter_clean_architecture_example/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('routes an empty session to the login page', (tester) async {
    await _pumpRouter(tester, null);

    expect(find.byKey(AuthWidgetKeys.loginButton), findsOneWidget);
  });

  testWidgets('routes a restored session to the task page', (tester) async {
    await _pumpRouter(tester, DemoAccounts.alice);

    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('No tasks yet'), findsOneWidget);
  });
}

Future<void> _pumpRouter(WidgetTester tester, DemoAccount? account) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWithBuild(
          (ref, notifier) async => account,
        ),
        taskRepositoryProvider.overrideWithValue(_FakeTaskRepository()),
      ],
      child: const _RouterApp(),
    ),
  );
  await tester.pumpAndSettle();
}

class _RouterApp extends ConsumerWidget {
  const _RouterApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}

final class _FakeTaskRepository implements TaskRepository {
  @override
  Stream<List<TaskItem>> watchTasks({
    required String ownerId,
    required TaskFilter filter,
  }) => Stream.value(const <TaskItem>[]);

  @override
  Future<Result<void>> createTask({
    required String ownerId,
    required TaskTitle title,
  }) async => const ResultOk(null);

  @override
  Future<Result<void>> renameTask({
    required String ownerId,
    required String id,
    required TaskTitle title,
  }) async => const ResultOk(null);

  @override
  Future<Result<void>> setCompleted({
    required String ownerId,
    required String id,
    required bool isCompleted,
  }) async => const ResultOk(null);

  @override
  Future<Result<void>> deleteTask({
    required String ownerId,
    required String id,
  }) async => const ResultOk(null);
}
