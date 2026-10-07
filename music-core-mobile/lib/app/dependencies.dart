import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/data/demo_auth_repository.dart';
import '../features/auth/data/session_storage.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/tasks/data/task_database.dart';
import '../features/tasks/data/task_repository_impl.dart';
import '../features/tasks/domain/repositories/task_repository.dart';
import 'app_config.dart';

part 'dependencies.g.dart';

/// Overridden by [bootstrap] for the selected flavor.
@Riverpod(keepAlive: true)
AppConfig appConfig(Ref ref) =>
    throw StateError('AppConfig has not been provided');

@Riverpod(keepAlive: true)
SessionStorage sessionStorage(Ref ref) =>
    SharedPreferencesSessionStorage(SharedPreferencesAsync());

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    DemoAuthRepository(ref.read(sessionStorageProvider));

@Riverpod(keepAlive: true)
TaskDatabase taskDatabase(Ref ref) {
  final database = TaskDatabase(name: ref.read(appConfigProvider).databaseName);
  ref.onDispose(database.close);
  return database;
}

@Riverpod(keepAlive: true)
TaskRepository taskRepository(Ref ref) =>
    TaskRepositoryImpl(ref.read(taskDatabaseProvider));
