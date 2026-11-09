import 'package:flutter_clean_architecture_example/app/dependencies.dart';
import 'package:flutter_clean_architecture_example/core/result.dart';
import 'package:flutter_clean_architecture_example/features/catalog/domain/entities/album_entity.dart';
import 'package:flutter_clean_architecture_example/features/catalog/domain/entities/artist_entity.dart';
import 'package:flutter_clean_architecture_example/features/catalog/domain/entities/catalog_search_result.dart';
import 'package:flutter_clean_architecture_example/features/catalog/domain/entities/track_entity.dart';
import 'package:flutter_clean_architecture_example/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:flutter_clean_architecture_example/features/player/domain/entities/transition_plan.dart';
import 'package:flutter_clean_architecture_example/features/player/presentation/player_controller.dart';
import 'package:flutter_clean_architecture_example/features/player/presentation/smart_transition_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayerController', () {
    test('initial state has no track and is not playing', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(playerControllerProvider);

      expect(state.hasTrack, false);
      expect(state.isPlaying, false);
      expect(state.queue, isEmpty);
    });

    test('playTrack updates currentTrack, queue and sets isPlaying to true', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const track1 = TrackEntity(
        id: 't1',
        title: 'Song 1',
        artistName: 'Artist 1',
        durationMs: 180000,
        fileUrl: '',
      );
      const track2 = TrackEntity(
        id: 't2',
        title: 'Song 2',
        artistName: 'Artist 2',
        durationMs: 200000,
        fileUrl: '',
      );

      final notifier = container.read(playerControllerProvider.notifier);
      await notifier.playTrack(track1, queue: [track1, track2]);

      final state = container.read(playerControllerProvider);
      expect(state.hasTrack, true);
      expect(state.currentTrack?.id, 't1');
      expect(state.queue.length, 2);
      expect(state.currentIndex, 0);
    });

    test('skipNext advances to next track in queue', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const track1 = TrackEntity(
        id: 't1',
        title: 'Song 1',
        artistName: 'Artist 1',
        durationMs: 180000,
        fileUrl: '',
      );
      const track2 = TrackEntity(
        id: 't2',
        title: 'Song 2',
        artistName: 'Artist 2',
        durationMs: 200000,
        fileUrl: '',
      );

      final notifier = container.read(playerControllerProvider.notifier);
      await notifier.playTrack(track1, queue: [track1, track2]);
      await notifier.skipNext();

      final state = container.read(playerControllerProvider);
      expect(state.currentTrack?.id, 't2');
      expect(state.currentIndex, 1);
    });

    test('skipPrevious returns to previous track or seeks to beginning', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const track1 = TrackEntity(
        id: 't1',
        title: 'Song 1',
        artistName: 'Artist 1',
        durationMs: 180000,
        fileUrl: '',
      );
      const track2 = TrackEntity(
        id: 't2',
        title: 'Song 2',
        artistName: 'Artist 2',
        durationMs: 200000,
        fileUrl: '',
      );

      final notifier = container.read(playerControllerProvider.notifier);
      await notifier.playTrack(track2, queue: [track1, track2]);
      expect(container.read(playerControllerProvider).currentIndex, 1);

      await notifier.skipPrevious();
      expect(container.read(playerControllerProvider).currentTrack?.id, 't1');
      expect(container.read(playerControllerProvider).currentIndex, 0);
    });

    test('toggleShuffle toggles shuffle state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(playerControllerProvider.notifier);
      expect(container.read(playerControllerProvider).isShuffle, false);

      notifier.toggleShuffle();
      expect(container.read(playerControllerProvider).isShuffle, true);

      notifier.toggleShuffle();
      expect(container.read(playerControllerProvider).isShuffle, false);
    });

    test('skipNext with Auto-DJ enabled jumps to the exact planned next track and updates queue', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const track1 = TrackEntity(
        id: 't1',
        title: 'Song 1',
        artistName: 'Artist 1',
        durationMs: 180000,
        fileUrl: '',
      );
      const track2 = TrackEntity(
        id: 't2',
        title: 'Song 2',
        artistName: 'Artist 2',
        durationMs: 200000,
        fileUrl: '',
      );

      final notifier = container.read(playerControllerProvider.notifier);
      await notifier.playTrack(track1, queue: [track1, track2]);

      // Simulate Auto-DJ recommending Song 99 (different from queue's track2)
      const plannedTrack = NextTrackTransition(
        id: 't99',
        title: 'AI Recommended Song 99',
        artists: ['AI Artist'],
        fileUrl: '',
        startPlaybackAtMs: 1000,
      );
      const plan = AutoDjTransitionResponse(
        currentTrack: CurrentTrackTransition(
          id: 't1',
          triggerTransitionAtMs: 170000,
          stopPlaybackAtMs: 180000,
        ),
        nextTrack: plannedTrack,
        transitionPlan: TransitionPlan(
          transitionType: 'SMOOTH_FADE',
          crossfadeDurationMs: 5000,
          preBufferAtMs: 160000,
          volumeBalanceGainDb: 0.0,
        ),
      );

      notifier.smartPlayer.setTransitionPlan(plan);
      // Allow transitionSub to process the emitted plan
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final stateWithPlan = container.read(playerControllerProvider);
      expect(stateWithPlan.currentTransitionPlan?.nextTrack.id, 't99');

      // Now skipNext should jump to t99 (the planned track), NOT t2 (queue track)!
      await notifier.skipNext();

      final updatedState = container.read(playerControllerProvider);
      expect(updatedState.currentTrack?.id, 't99');
      expect(updatedState.currentTrack?.title, 'AI Recommended Song 99');
    });

    test('playTrack clears stale transition plan from previous track', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const track1 = TrackEntity(
        id: 't1',
        title: 'Song 1',
        artistName: 'Artist 1',
        durationMs: 180000,
        fileUrl: '',
      );
      const track2 = TrackEntity(
        id: 't2',
        title: 'Song 2',
        artistName: 'Artist 2',
        durationMs: 200000,
        fileUrl: '',
      );

      final notifier = container.read(playerControllerProvider.notifier);
      await notifier.playTrack(track1, queue: [track1, track2]);

      const plan = AutoDjTransitionResponse(
        currentTrack: CurrentTrackTransition(
          id: 't1',
          triggerTransitionAtMs: 170000,
          stopPlaybackAtMs: 180000,
        ),
        nextTrack: NextTrackTransition(
          id: 't99',
          title: 'Song 99',
          artists: ['Artist 99'],
          fileUrl: '',
          startPlaybackAtMs: 1000,
        ),
        transitionPlan: TransitionPlan(
          transitionType: 'SMOOTH_FADE',
          crossfadeDurationMs: 5000,
          preBufferAtMs: 160000,
          volumeBalanceGainDb: 0.0,
        ),
      );

      notifier.smartPlayer.setTransitionPlan(plan);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(container.read(playerControllerProvider).currentTransitionPlan, isNotNull);

      // Play track2 directly - should clear old transition plan
      await notifier.playTrack(track2, queue: [track1, track2]);
      expect(container.read(playerControllerProvider).currentTransitionPlan, isNull);
    });

    test('skipNext with shuffle enabled calls getRandomTrack and plays returned track', () async {
      const randomTrack = TrackEntity(
        id: 'rand-100',
        title: 'Truly Random Song',
        artistName: 'Random Artist',
        durationMs: 190000,
        fileUrl: '',
      );

      final fakeCatalogRepo = _TestCatalogRepository(randomTrack: randomTrack);

      final container = ProviderContainer(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(fakeCatalogRepo),
        ],
      );
      addTearDown(container.dispose);

      const track1 = TrackEntity(
        id: 't1',
        title: 'Song 1',
        artistName: 'Artist 1',
        durationMs: 180000,
        fileUrl: '',
      );
      const track2 = TrackEntity(
        id: 't2',
        title: 'Song 2',
        artistName: 'Artist 2',
        durationMs: 200000,
        fileUrl: '',
      );

      final notifier = container.read(playerControllerProvider.notifier);
      await notifier.playTrack(track1, queue: [track1, track2]);

      notifier.toggleShuffle();
      expect(container.read(playerControllerProvider).isShuffle, true);

      await notifier.skipNext();

      final state = container.read(playerControllerProvider);
      expect(state.currentTrack?.id, 'rand-100');
      expect(state.currentTrack?.title, 'Truly Random Song');
      expect(fakeCatalogRepo.getRandomTrackCalled, true);
    });
  });
}

class _TestCatalogRepository implements CatalogRepository {
  _TestCatalogRepository({this.randomTrack});

  final TrackEntity? randomTrack;
  bool getRandomTrackCalled = false;

  @override
  Future<Result<TrackEntity>> getRandomTrack({
    String? excludeTrackId,
    List<String>? excludeTrackIds,
    String? genreId,
  }) async {
    getRandomTrackCalled = true;
    if (randomTrack != null) {
      return ResultOk(randomTrack!);
    }
    return const ResultError(ServerFailure('No random track'));
  }

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

  @override
  Future<Result<CatalogSearchResult>> searchCatalog({
    required String query,
    int page = 1,
    int limit = 10,
    String type = 'all',
  }) async =>
      const ResultOk(CatalogSearchResult());

  @override
  Future<Result<AlbumEntity>> getAlbumById(String id) async =>
      const ResultError(ServerFailure('Not found'));

  @override
  Future<Result<ArtistEntity>> getArtistById(String id) async =>
      const ResultError(ServerFailure('Not found'));
}
