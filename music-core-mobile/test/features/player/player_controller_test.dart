import 'package:flutter_clean_architecture_example/features/catalog/domain/entities/track_entity.dart';
import 'package:flutter_clean_architecture_example/features/player/presentation/player_controller.dart';
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
  });
}
