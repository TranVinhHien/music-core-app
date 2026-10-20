import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture_example/app/dependencies.dart';
import 'package:flutter_clean_architecture_example/core/result.dart';
import 'package:flutter_clean_architecture_example/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_clean_architecture_example/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_clean_architecture_example/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_clean_architecture_example/features/auth/presentation/auth_controller.dart';
import 'package:flutter_clean_architecture_example/features/tasks/domain/entities/task_filter.dart';
import 'package:flutter_clean_architecture_example/features/tasks/domain/entities/task_item.dart';
import 'package:flutter_clean_architecture_example/features/tasks/domain/repositories/task_repository.dart';
import 'package:flutter_clean_architecture_example/features/tasks/domain/value_objects/task_title.dart';
import 'package:flutter_clean_architecture_example/features/tasks/presentation/tasks_page.dart';
import 'package:flutter_clean_architecture_example/features/tasks/presentation/task_widget_keys.dart';
import 'package:flutter_clean_architecture_example/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('starts empty and changes the repository filter once', (
    tester,
  ) async {
    final repository = _FakeTaskRepository();
    await _pumpTasks(tester, repository);

    expect(find.text('No tasks yet'), findsOneWidget);
    expect(repository.filters, [TaskFilter.all]);

    final filterControl = tester.widget<SegmentedButton<TaskFilter>>(
      find.byType(SegmentedButton<TaskFilter>),
    );
    filterControl.onSelectionChanged?.call({});
    await tester.pump();
    expect(repository.filters, [TaskFilter.all]);

    await tester.tap(find.text('Active'));
    await tester.pumpAndSettle();

    expect(repository.filters, [TaskFilter.all, TaskFilter.active]);
    expect(find.text('No tasks yet'), findsOneWidget);
  });

  testWidgets('creates a task through the shared editor', (tester) async {
    final repository = _FakeTaskRepository();
    await _pumpTasks(tester, repository);

    await tester.tap(find.byKey(TaskWidgetKeys.addTaskButton));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(TaskWidgetKeys.titleInput),
      '  New task  ',
    );
    await tester.tap(find.byKey(TaskWidgetKeys.saveButton));
    await tester.pumpAndSettle();

    expect(repository.createdTitle?.value, 'New task');
  });

  testWidgets('renames a task through the shared editor', (tester) async {
    final repository = _FakeTaskRepository(tasks: [_task()]);
    await _pumpTasks(tester, repository);

    await tester.tap(find.byKey(TaskWidgetKeys.editTaskButton('task-1')));
    await tester.pumpAndSettle();

    final titleField = tester.widget<TextFormField>(
      find.byKey(TaskWidgetKeys.titleInput),
    );
    expect(titleField.controller?.text, 'Pending task');

    await tester.enterText(
      find.byKey(TaskWidgetKeys.titleInput),
      '  Renamed task  ',
    );
    await tester.tap(find.byKey(TaskWidgetKeys.saveButton));
    await tester.pumpAndSettle();

    expect(repository.renamedTaskId, 'task-1');
    expect(repository.renamedTitle?.value, 'Renamed task');
  });

  testWidgets('does not create a task when the editor is cancelled', (
    tester,
  ) async {
    final repository = _FakeTaskRepository();
    await _pumpTasks(tester, repository);

    await tester.tap(find.byKey(TaskWidgetKeys.addTaskButton));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(repository.createdTitle, isNull);
  });

  testWidgets('disables task controls while a mutation is running', (
    tester,
  ) async {
    final pendingMutation = Completer<Result<void>>();
    final repository = _FakeTaskRepository(
      tasks: [
        TaskItem(
          id: 'task-1',
          ownerId: _testUser.id,
          title: 'Pending task',
          isCompleted: false,
          updatedAt: DateTime.utc(2026),
        ),
      ],
      pendingSetCompleted: pendingMutation,
    );
    await _pumpTasks(tester, repository);

    await tester.tap(find.byKey(TaskWidgetKeys.taskCheckbox('task-1')));
    await tester.pump();

    expect(
      tester
          .widget<Checkbox>(find.byKey(TaskWidgetKeys.taskCheckbox('task-1')))
          .onChanged,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(
            find.byKey(TaskWidgetKeys.editTaskButton('task-1')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<FloatingActionButton>(
            find.byKey(TaskWidgetKeys.addTaskButton),
          )
          .onPressed,
      isNull,
    );

    pendingMutation.complete(const ResultOk(null));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Checkbox>(find.byKey(TaskWidgetKeys.taskCheckbox('task-1')))
          .onChanged,
      isNotNull,
    );
  });

  testWidgets('shows a localized task stream error', (tester) async {
    await _pumpTasks(
      tester,
      _FakeTaskRepository(streamError: const StorageFailure()),
    );

    expect(find.text('Local data is temporarily unavailable.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('shows a localized task mutation error', (tester) async {
    final repository = _FakeTaskRepository(
      tasks: [_task()],
      setCompletedResult: const ResultError(StorageFailure()),
    );
    await _pumpTasks(tester, repository);

    await tester.tap(find.byKey(TaskWidgetKeys.taskCheckbox('task-1')));
    await tester.pumpAndSettle();

    expect(find.text('Local data is temporarily unavailable.'), findsOneWidget);
  });

  testWidgets('keeps the account when sign-out storage fails', (tester) async {
    await _pumpTasks(
      tester,
      _FakeTaskRepository(),
      authRepository: const _FailingSignOutAuthRepository(),
    );

    await tester.tap(find.byKey(TaskWidgetKeys.logoutButton));
    await tester.pumpAndSettle();

    expect(find.text(_testUser.email), findsOneWidget);
    expect(find.text('Local data is temporarily unavailable.'), findsOneWidget);
  });

  testWidgets('uses natural Chinese task text', (tester) async {
    await _pumpTasks(tester, _FakeTaskRepository(), locale: const Locale('zh'));

    expect(find.text('未完成'), findsOneWidget);
    expect(find.text('暂无任务'), findsOneWidget);
    expect(find.text('点击“添加任务”创建第一条任务。'), findsOneWidget);
  });

  testWidgets('uses a natural Chinese delete confirmation', (tester) async {
    await _pumpTasks(
      tester,
      _FakeTaskRepository(tasks: [_task()]),
      locale: const Locale('zh'),
    );

    await tester.tap(find.byKey(TaskWidgetKeys.deleteTaskButton('task-1')));
    await tester.pumpAndSettle();

    expect(find.text('删除后无法恢复，确定要删除这条任务吗？'), findsOneWidget);
  });
}

const _testUser = UserEntity(
  id: 'user-alice',
  email: 'alice@example.com',
  fullName: 'Alice',
);

const _testSession = AuthSession(
  user: _testUser,
  accessToken: 'mock_token',
);

Future<void> _pumpTasks(
  WidgetTester tester,
  _FakeTaskRepository repository, {
  Locale locale = const Locale('en'),
  AuthRepository? authRepository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (authRepository == null)
          authControllerProvider.overrideWithBuild(
            (ref, notifier) async => _testSession,
          )
        else
          authRepositoryProvider.overrideWithValue(authRepository),
        taskRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const TasksPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final class _FakeTaskRepository implements TaskRepository {
  _FakeTaskRepository({
    this.tasks = const [],
    this.pendingSetCompleted,
    this.streamError,
    this.setCompletedResult = const ResultOk(null),
  });

  final List<TaskItem> tasks;
  final Completer<Result<void>>? pendingSetCompleted;
  final Object? streamError;
  final Result<void> setCompletedResult;
  final filters = <TaskFilter>[];
  TaskTitle? createdTitle;
  String? renamedTaskId;
  TaskTitle? renamedTitle;

  @override
  Stream<List<TaskItem>> watchTasks({
    required String ownerId,
    required TaskFilter filter,
  }) {
    filters.add(filter);
    final error = streamError;
    if (error != null) return Stream.error(error);
    return Stream.value(tasks);
  }

  @override
  Future<Result<void>> createTask({
    required String ownerId,
    required TaskTitle title,
  }) async {
    createdTitle = title;
    return const ResultOk(null);
  }

  @override
  Future<Result<void>> renameTask({
    required String ownerId,
    required String id,
    required TaskTitle title,
  }) async {
    renamedTaskId = id;
    renamedTitle = title;
    return const ResultOk(null);
  }

  @override
  Future<Result<void>> setCompleted({
    required String ownerId,
    required String id,
    required bool isCompleted,
  }) async {
    final pending = pendingSetCompleted;
    if (pending != null) return pending.future;
    return setCompletedResult;
  }

  @override
  Future<Result<void>> deleteTask({
    required String ownerId,
    required String id,
  }) async => const ResultOk(null);
}

final class _FailingSignOutAuthRepository implements AuthRepository {
  const _FailingSignOutAuthRepository();

  @override
  Future<Result<AuthSession?>> restoreSession() async =>
      const ResultOk(_testSession);

  @override
  Future<Result<AuthSession>> signIn(String email, String password) async =>
      const ResultOk(_testSession);

  @override
  Future<Result<void>> register({
    required String email,
    required String password,
    required String fullName,
    String? avatarUrl,
    String? phoneNumber,
    String? homeAddress,
  }) async =>
      const ResultOk(null);

  @override
  Future<Result<void>> signOut() async => const ResultError(StorageFailure());

  @override
  Future<Result<AuthSession>> refreshToken() async =>
      const ResultError(UnauthorizedFailure('Not implemented'));
}

TaskItem _task() => TaskItem(
  id: 'task-1',
  ownerId: _testUser.id,
  title: 'Pending task',
  isCompleted: false,
  updatedAt: DateTime.utc(2026),
);
