import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/domain/entities/auth_session.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/auth/presentation/splash_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/library/presentation/favorites_page.dart';
import '../features/library/presentation/playlist_detail_page.dart';
import '../features/library/presentation/playlists_page.dart';
import '../features/offline/presentation/offline_music_page.dart';
import '../features/songs/presentation/songs_page.dart';
import '../features/tasks/presentation/tasks_page.dart';
import '../l10n/app_localizations_resolver.dart';
import 'main_navigation_scaffold.dart';

part 'router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final refresh = _RouterRefresh();
  ref.listen<AsyncValue<AuthSession?>>(authControllerProvider, (_, _) {
    refresh.refresh();
  });

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final location = state.uri.path;

      if (authState.isLoading && !authState.hasValue) {
        return location == '/splash' ? null : '/splash';
      }
      if (authState.hasError) {
        return location == '/splash' ? null : '/splash';
      }

      final isAuthenticated = authState.value != null;
      if (!isAuthenticated) {
        if (location == '/login' || location == '/register') {
          return null;
        }
        return '/login';
      }

      if (location == '/login' || location == '/register' || location == '/splash') {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
      GoRoute(path: '/offline', builder: (context, state) => const OfflineMusicPage()),
      GoRoute(path: '/tasks', builder: (context, state) => const TasksPage()),

      // Core Music App Navigation Shell with Bottom Navigation Bar
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Branch 1: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          // Branch 2: Songs
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/songs',
                builder: (context, state) => const SongsPage(),
              ),
            ],
          ),
          // Branch 3: Playlists
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/playlists',
                builder: (context, state) => const PlaylistsPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => PlaylistDetailPage(
                      playlistId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Branch 4: Favorites
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                builder: (context, state) => const FavoritesPage(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) {
      final localizations = appLocalizationsOf(context);
      return Scaffold(body: Center(child: Text(localizations.pageNotFound)));
    },
  );

  ref.onDispose(() {
    refresh.dispose();
    router.dispose();
  });
  return router;
}

final class _RouterRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}
