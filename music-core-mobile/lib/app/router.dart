import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/domain/entities/demo_account.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/splash_page.dart';
import '../features/tasks/presentation/tasks_page.dart';
import '../l10n/app_localizations_resolver.dart';

part 'router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final refresh = _RouterRefresh();
  ref.listen<AsyncValue<DemoAccount?>>(authControllerProvider, (_, _) {
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
      if (!isAuthenticated) return location == '/login' ? null : '/login';
      if (location == '/login' || location == '/splash') return '/tasks';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/tasks', builder: (context, state) => const TasksPage()),
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
