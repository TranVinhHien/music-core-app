import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lightweight diagnostics enabled only for the development flavor.
final class DiagnosticsObserver extends ProviderObserver {
  const DiagnosticsObserver();

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    if (newValue is AsyncError) {
      debugPrint(
        '[${context.provider.name ?? context.provider.runtimeType}] ${newValue.error}',
      );
    }
  }
}
