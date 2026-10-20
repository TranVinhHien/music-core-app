import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture_example/app/dependencies.dart';
import 'package:flutter_clean_architecture_example/app/router.dart';
import 'package:flutter_clean_architecture_example/core/result.dart';
import 'package:flutter_clean_architecture_example/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_clean_architecture_example/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_clean_architecture_example/features/auth/presentation/auth_controller.dart';
import 'package:flutter_clean_architecture_example/features/auth/presentation/auth_widget_keys.dart';
import 'package:flutter_clean_architecture_example/features/catalog/domain/entities/track_entity.dart';
import 'package:flutter_clean_architecture_example/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:flutter_clean_architecture_example/features/library/domain/entities/playlist_entity.dart';
import 'package:flutter_clean_architecture_example/features/library/domain/repositories/library_repository.dart';
import 'package:flutter_clean_architecture_example/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const testSession = AuthSession(
    user: UserEntity(
      id: '1',
      email: 'user@example.com',
      fullName: 'Test User',
    ),
    accessToken: 'token',
  );

  testWidgets('routes an empty session to the login page', (tester) async {
    await _pumpRouter(tester, null);

    expect(find.byKey(AuthWidgetKeys.loginButton), findsOneWidget);
  });

  testWidgets('routes a restored session to the home page', (tester) async {
    await _pumpRouter(tester, testSession);

    expect(find.text('Xin chào, Test User 👋'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Khám phá'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Bài hát'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Playlists'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Yêu thích'),
      ),
      findsOneWidget,
    );
  });
}

Future<void> _pumpRouter(WidgetTester tester, AuthSession? account) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWithBuild(
          (ref, notifier) async => account,
        ),
        catalogRepositoryProvider.overrideWithValue(_FakeCatalogRepository()),
        libraryRepositoryProvider.overrideWithValue(_FakeLibraryRepository()),
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

final class _FakeCatalogRepository implements CatalogRepository {
  @override
  Future<Result<List<TrackEntity>>> getTracks({
    int page = 1,
    int limit = 20,
    String? query,
  }) async =>
      const ResultOk(<TrackEntity>[]);

  @override
  Future<Result<TrackEntity>> getTrackById(String id) async =>
      const ResultError(ServerFailure('Not found'));
}

final class _FakeLibraryRepository implements LibraryRepository {
  @override
  Future<Result<List<PlaylistEntity>>> getPlaylists({
    int page = 1,
    int limit = 20,
    String? query,
  }) async =>
      const ResultOk(<PlaylistEntity>[]);

  @override
  Future<Result<PlaylistEntity>> getPlaylistDetails(String playlistId) async =>
      const ResultError(ServerFailure('Not found'));

  @override
  Future<Result<PlaylistEntity>> createPlaylist({
    required String name,
    String? description,
    String? coverImageUrl,
    String visibility = 'PRIVATE',
  }) async =>
      ResultOk(
        PlaylistEntity(
          id: 'p1',
          userId: 'u1',
          name: name,
          description: description,
          trackCount: 0,
          createdAt: DateTime.now(),
        ),
      );

  @override
  Future<Result<void>> deletePlaylist(String playlistId) async =>
      const ResultOk(null);

  @override
  Future<Result<void>> addTrackToPlaylist(
    String playlistId,
    String trackId,
  ) async =>
      const ResultOk(null);

  @override
  Future<Result<void>> removeTrackFromPlaylist(
    String playlistId,
    String trackId,
  ) async =>
      const ResultOk(null);

  @override
  Future<Result<List<TrackEntity>>> getFavoriteTracks({
    int page = 1,
    int limit = 50,
  }) async =>
      const ResultOk(<TrackEntity>[]);

  @override
  Future<Result<void>> addFavorite(String trackId) async =>
      const ResultOk(null);

  @override
  Future<Result<void>> removeFavorite(String trackId) async =>
      const ResultOk(null);
}
