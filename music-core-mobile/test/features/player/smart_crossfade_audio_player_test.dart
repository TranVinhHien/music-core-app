import 'dart:async';
import 'package:flutter_clean_architecture_example/core/result.dart';
import 'package:flutter_clean_architecture_example/features/catalog/domain/entities/track_entity.dart';
import 'package:flutter_clean_architecture_example/features/player/domain/entities/transition_plan.dart';
import 'package:flutter_clean_architecture_example/features/player/domain/repositories/transition_repository.dart';
import 'package:flutter_clean_architecture_example/features/player/presentation/smart_crossfade_audio_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart' as ja;

class FakeTransitionRepository implements TransitionRepository {
  AutoDjTransitionResponse? nextPlanToReturn;

  @override
  Future<Result<AutoDjTransitionResponse>> getNextTransition({
    required String currentTrackId,
    List<String>? excludeTrackIds,
    double temperature = 0.7,
  }) async {
    if (nextPlanToReturn != null) {
      return ResultOk(nextPlanToReturn!);
    }
    return const ResultError(NetworkFailure('No transition plan'));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SmartCrossfadeAudioPlayer', () {
    test('initializes with distinct primary and secondary decks', () {
      final player = SmartCrossfadeAudioPlayer(
        primaryDeck: ja.AudioPlayer(),
        secondaryDeck: ja.AudioPlayer(),
      );
      expect(player.primaryDeck, isNotNull);
      expect(player.secondaryDeck, isNotNull);
      expect(player.primaryDeck != player.secondaryDeck, isTrue);
      expect(player.isCrossfading, isFalse);
      expect(player.isPrebuffered, isFalse);
    });

    test('calculateLinearGain scales dB accurately', () {
      expect(SmartCrossfadeAudioPlayer.calculateLinearGain(0.0), closeTo(1.0, 0.001));
      expect(SmartCrossfadeAudioPlayer.calculateLinearGain(-6.0), closeTo(0.501, 0.01));
      expect(SmartCrossfadeAudioPlayer.calculateLinearGain(-3.5), closeTo(0.668, 0.01));
      expect(SmartCrossfadeAudioPlayer.calculateLinearGain(-20.0), closeTo(0.1, 0.001));
      expect(SmartCrossfadeAudioPlayer.calculateLinearGain(10.0), 1.0); // Clamped
    });

    test('setTransitionPlan updates state and emits through transitionPlanStream', () async {
      final player = SmartCrossfadeAudioPlayer();

      const plan = AutoDjTransitionResponse(
        currentTrack: CurrentTrackTransition(
          id: 'track-1',
          triggerTransitionAtMs: 200000,
          stopPlaybackAtMs: 210000,
        ),
        nextTrack: NextTrackTransition(
          id: 'track-2',
          title: 'Upcoming Track',
          startPlaybackAtMs: 3000,
        ),
        transitionPlan: TransitionPlan(
          transitionType: 'BEAT_CROSSFADE',
          crossfadeDurationMs: 10000,
          preBufferAtMs: 190000,
          volumeBalanceGainDb: -1.5,
        ),
      );

      final planFuture = player.transitionPlanStream.first;
      player.setTransitionPlan(plan);
      final emitted = await planFuture;

      expect(emitted, plan);
      expect(player.currentTransitionPlan, plan);
      expect(player.pendingNextTrack?.id, 'track-2');
    });

    test('fetchAndApplyTransition successfully retrieves plan from TransitionRepository', () async {
      final fakeRepo = FakeTransitionRepository();
      const plan = AutoDjTransitionResponse(
        currentTrack: CurrentTrackTransition(
          id: 't-1',
          triggerTransitionAtMs: 100000,
          stopPlaybackAtMs: 108000,
        ),
        nextTrack: NextTrackTransition(
          id: 't-2',
          title: 'Next One',
          startPlaybackAtMs: 2000,
        ),
        transitionPlan: TransitionPlan(
          transitionType: 'SMOOTH_FADE',
          crossfadeDurationMs: 8000,
          preBufferAtMs: 95000,
          volumeBalanceGainDb: 0.0,
        ),
      );
      fakeRepo.nextPlanToReturn = plan;

      final player = SmartCrossfadeAudioPlayer(
        transitionRepository: fakeRepo,
      );

      const track = TrackEntity(
        id: 't-1',
        title: 'Current One',
        artistName: 'Artist A',
        fileUrl: '',
      );

      await player.playTrack(track);

      final retrieved = await player.fetchAndApplyTransition('t-1');
      expect(retrieved, isNotNull);
      expect(player.currentTransitionPlan?.currentTrack.id, 't-1');
      expect(player.currentTransitionPlan?.nextTrack.id, 't-2');
    });

    test('playTrack with empty fileUrl handles gracefully and returns null without hanging', () async {
      final player = SmartCrossfadeAudioPlayer();

      const track = TrackEntity(
        id: 't-empty',
        title: 'Empty Audio',
        artistName: 'Tester',
        fileUrl: '',
      );

      final duration = await player.playTrack(track);
      expect(duration, isNull);
      expect(player.currentTrack?.id, 't-empty');
    });
  });
}
