import 'dart:io';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/database/music_database.dart';
import '../core/network/api_client.dart';
import '../features/auth/data/auth_repository_impl.dart';
import '../features/auth/data/datasources/auth_remote_data_source.dart';
import '../features/auth/data/session_storage.dart';
import '../features/auth/domain/entities/auth_session.dart';
import '../features/auth/domain/entities/user_entity.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/catalog/data/datasources/catalog_remote_data_source.dart';
import '../features/catalog/data/repositories/catalog_repository_impl.dart';
import '../features/catalog/domain/repositories/catalog_repository.dart';
import '../features/library/data/datasources/library_remote_data_source.dart';
import '../features/library/data/repositories/library_repository_impl.dart';
import '../features/library/domain/repositories/library_repository.dart';
import '../features/offline/data/offline_download_service.dart';
import '../features/offline/data/repositories/offline_repository_impl.dart';
import '../features/offline/domain/repositories/offline_repository.dart';
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
ApiClient apiClient(Ref ref) {
  final config = ref.watch(appConfigProvider);
  final storage = ref.watch(sessionStorageProvider);
  return ApiClient(
    baseUrl: config.apiBaseUrl,
    tokenGetter: () => storage.cachedAccessToken,
    onRefreshToken: () async {
      final session = await storage.readSession();
      final refreshToken = session?.refreshToken;
      if (refreshToken == null || refreshToken.isEmpty) {
        return null;
      }

      final refreshDio = Dio(
        BaseOptions(
          baseUrl: config.apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      try {
        final res = await refreshDio.post<dynamic>(
          '/api/v1/auth/refresh',
          data: {'refresh_token': refreshToken},
        );

        final body = res.data;
        if (body is Map<String, dynamic>) {
          final data = body['data'];
          if (data is Map<String, dynamic>) {
            final newAccessToken =
                (data['token'] ?? data['access_token']) as String?;
            final newRefreshToken =
                (data['refresh_token'] as String?) ?? refreshToken;

            if (newAccessToken != null && newAccessToken.isNotEmpty) {
              final updatedSession = AuthSession(
                user: data['user'] is Map<String, dynamic>
                    ? UserEntity.fromJson(data['user'] as Map<String, dynamic>)
                    : session!.user,
                accessToken: newAccessToken,
                refreshToken: newRefreshToken,
              );
              await storage.writeSession(updatedSession);
              return newAccessToken;
            }
          }
        }
      } catch (e) {
        if (e is DioException &&
            e.response?.statusCode == HttpStatus.unauthorized) {
          await storage.clearSession();
        }
        return null;
      }
      return null;
    },
    onAuthenticationFailed: () async {
      await storage.clearSession();
      try {
        ref.read(authControllerProvider.notifier).clearSession();
      } catch (_) {}
    },
  );
}

@Riverpod(keepAlive: true)
AuthRemoteDataSource authRemoteDataSource(Ref ref) =>
    AuthRemoteDataSourceImpl(ref.watch(apiClientProvider));

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => AuthRepositoryImpl(
      ref.watch(authRemoteDataSourceProvider),
      ref.watch(sessionStorageProvider),
    );

@Riverpod(keepAlive: true)
CatalogRemoteDataSource catalogRemoteDataSource(Ref ref) =>
    CatalogRemoteDataSourceImpl(ref.watch(apiClientProvider));

@Riverpod(keepAlive: true)
CatalogRepository catalogRepository(Ref ref) =>
    CatalogRepositoryImpl(ref.watch(catalogRemoteDataSourceProvider));

@Riverpod(keepAlive: true)
LibraryRemoteDataSource libraryRemoteDataSource(Ref ref) =>
    LibraryRemoteDataSourceImpl(ref.watch(apiClientProvider));

@Riverpod(keepAlive: true)
LibraryRepository libraryRepository(Ref ref) =>
    LibraryRepositoryImpl(ref.watch(libraryRemoteDataSourceProvider));

@Riverpod(keepAlive: true)
MusicDatabase musicDatabase(Ref ref) {
  try {
    final config = ref.read(appConfigProvider);
    if (config.databaseName.contains('test')) {
      final db = MusicDatabase.forTesting();
      ref.onDispose(db.close);
      return db;
    }
    final database = MusicDatabase(name: '${config.databaseName}_music');
    ref.onDispose(database.close);
    return database;
  } catch (_) {
    final db = MusicDatabase.forTesting();
    ref.onDispose(db.close);
    return db;
  }
}

@Riverpod(keepAlive: true)
OfflineDownloadService offlineDownloadService(Ref ref) =>
    OfflineDownloadService();

@Riverpod(keepAlive: true)
OfflineRepository offlineRepository(Ref ref) => OfflineRepositoryImpl(
      database: ref.watch(musicDatabaseProvider),
      downloadService: ref.watch(offlineDownloadServiceProvider),
    );

@Riverpod(keepAlive: true)
TaskDatabase taskDatabase(Ref ref) {
  final database = TaskDatabase(name: ref.read(appConfigProvider).databaseName);
  ref.onDispose(database.close);
  return database;
}

@Riverpod(keepAlive: true)
TaskRepository taskRepository(Ref ref) =>
    TaskRepositoryImpl(ref.read(taskDatabaseProvider));
