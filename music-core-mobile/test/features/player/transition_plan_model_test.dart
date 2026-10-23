import 'dart:math' as math;
import 'package:flutter_clean_architecture_example/features/player/data/models/transition_plan_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransitionPlan Models Serialization', () {
    const rawJson = {
      'currentTrack': {
        'id': '2d4e9b6b-4885-4586-a8e8-b2a5f1b880ed',
        'title': 'Trái Tim Bên Lề',
        'durationMs': 313862,
        'bpm': 136.0,
        'camelotKey': '9A',
        'loudnessLufs': -23.1,
        'triggerTransitionAtMs': 303624,
        'stopPlaybackAtMs': 313862,
      },
      'nextTrack': {
        'id': 'cbda8cd0-45ad-4b49-9f22-32767f002302',
        'title': 'Không',
        'fileUrl': 'https://cdn.example.com/audio/khong.m4a',
        'coverImageUrl': 'https://cdn.example.com/cover/khong.jpg',
        'artists': ['Elvis Phương'],
        'durationMs': 245000,
        'bpm': 136.0,
        'camelotKey': '9A',
        'startPlaybackAtMs': 6849,
        'targetDownbeatMs': 8000,
      },
      'transitionPlan': {
        'transitionType': 'BEAT_CROSSFADE',
        'crossfadeDurationMs': 8000,
        'preBufferAtMs': 293624,
        'volumeBalanceGainDb': -3.5,
        'tempoRatio': 1.0,
        'compatibilityScore': 95.5,
      },
    };

    test('parses full backend JSON payload correctly', () {
      final response = AutoDjTransitionResponse.fromJson(rawJson);

      expect(response.currentTrack.id, '2d4e9b6b-4885-4586-a8e8-b2a5f1b880ed');
      expect(response.currentTrack.triggerTransitionAtMs, 303624);
      expect(response.currentTrack.stopPlaybackAtMs, 313862);

      expect(response.nextTrack.id, 'cbda8cd0-45ad-4b49-9f22-32767f002302');
      expect(response.nextTrack.title, 'Không');
      expect(response.nextTrack.artists, ['Elvis Phương']);
      expect(response.nextTrack.startPlaybackAtMs, 6849);
      expect(response.nextTrack.fileUrl, 'https://cdn.example.com/audio/khong.m4a');

      expect(response.transitionPlan.transitionType, 'BEAT_CROSSFADE');
      expect(response.transitionPlan.crossfadeDurationMs, 8000);
      expect(response.transitionPlan.preBufferAtMs, 293624);
      expect(response.transitionPlan.volumeBalanceGainDb, -3.5);
      expect(response.transitionPlan.compatibilityScore, 95.5);
    });

    test('converts NextTrackTransition to TrackEntity', () {
      final response = AutoDjTransitionResponse.fromJson(rawJson);
      final trackEntity = response.nextTrack.toTrackEntity();

      expect(trackEntity.id, 'cbda8cd0-45ad-4b49-9f22-32767f002302');
      expect(trackEntity.title, 'Không');
      expect(trackEntity.artistName, 'Elvis Phương');
      expect(trackEntity.coverImageUrl, 'https://cdn.example.com/cover/khong.jpg');
      expect(trackEntity.fileUrl, 'https://cdn.example.com/audio/khong.m4a');
      expect(trackEntity.durationMs, 245000);
    });

    test('calculates correct linear gain from dB', () {
      const plan0Db = TransitionPlan(
        transitionType: 'BEAT_CROSSFADE',
        crossfadeDurationMs: 8000,
        preBufferAtMs: 200000,
        volumeBalanceGainDb: 0.0,
      );
      expect(plan0Db.linearGainMultiplier, closeTo(1.0, 0.001));

      const planMinus3_5Db = TransitionPlan(
        transitionType: 'BEAT_CROSSFADE',
        crossfadeDurationMs: 8000,
        preBufferAtMs: 200000,
        volumeBalanceGainDb: -3.5,
      );
      final expectedMinus3_5 = math.pow(10.0, -3.5 / 20.0).toDouble();
      expect(planMinus3_5Db.linearGainMultiplier, closeTo(expectedMinus3_5, 0.001));

      const planPlus6Db = TransitionPlan(
        transitionType: 'BEAT_CROSSFADE',
        crossfadeDurationMs: 8000,
        preBufferAtMs: 200000,
        volumeBalanceGainDb: 6.0,
      );
      // Clamped to 1.0
      expect(planPlus6Db.linearGainMultiplier, 1.0);
    });

    test('serializes and deserializes back faithfully', () {
      final original = AutoDjTransitionResponse.fromJson(rawJson);
      final serialized = original.toJson();
      final roundTrip = AutoDjTransitionResponse.fromJson(serialized);

      expect(roundTrip.currentTrack.id, original.currentTrack.id);
      expect(roundTrip.nextTrack.id, original.nextTrack.id);
      expect(roundTrip.transitionPlan.transitionType, original.transitionPlan.transitionType);
      expect(roundTrip.transitionPlan.preBufferAtMs, original.transitionPlan.preBufferAtMs);
      expect(roundTrip.transitionPlan.volumeBalanceGainDb, original.transitionPlan.volumeBalanceGainDb);
    });

    test('handles snake_case and camelCase field variations smoothly', () {
      final snakeCaseJson = {
        'current_track': {
          'id': 'uuid-1',
          'trigger_transition_at_ms': 120000,
          'stop_playback_at_ms': 130000,
        },
        'next_track': {
          'id': 'uuid-2',
          'title': 'Track B',
          'file_url': 'https://example.com/b.m4a',
          'artists': ['Artist B'],
          'start_playback_at_ms': 5000,
        },
        'transition_plan': {
          'transition_type': 'SMOOTH_FADE',
          'crossfade_duration_ms': 6000,
          'pre_buffer_at_ms': 115000,
          'volume_balance_gain_db': -1.2,
        },
      };

      final response = AutoDjTransitionResponse.fromJson(snakeCaseJson);
      expect(response.currentTrack.triggerTransitionAtMs, 120000);
      expect(response.currentTrack.stopPlaybackAtMs, 130000);
      expect(response.nextTrack.fileUrl, 'https://example.com/b.m4a');
      expect(response.nextTrack.startPlaybackAtMs, 5000);
      expect(response.transitionPlan.transitionType, 'SMOOTH_FADE');
      expect(response.transitionPlan.preBufferAtMs, 115000);
      expect(response.transitionPlan.volumeBalanceGainDb, -1.2);
    });
  });
}
