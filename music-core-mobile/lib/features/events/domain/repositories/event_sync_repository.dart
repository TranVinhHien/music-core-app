import '../../../../core/result.dart';
import '../entities/client_event.dart';

abstract interface class EventSyncRepository {
  /// Records an event locally into SQLite.
  Future<void> recordEvent(ClientEvent event);

  /// Synchronizes a batch of pending events (up to maxBatch items) to backend.
  /// If offline, skips and returns ResultOk(0).
  /// If successful, removes the sent events from local SQLite.
  Future<Result<int>> syncPendingEvents({int maxBatch = 100});

  /// Returns total count of un-synced events currently stored locally.
  Future<int> getPendingEventCount();
}
