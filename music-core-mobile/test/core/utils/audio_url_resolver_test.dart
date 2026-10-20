import 'package:flutter_clean_architecture_example/core/utils/audio_url_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AudioUrlResolver', () {
    test('resolves Google Drive viewer link to direct stream link', () {
      const raw =
          'https://drive.google.com/file/d/1rpIJ5pNTmgWxtDq43O4-gWWr3xklCz6B/view?usp=sharing';
      final resolved = AudioUrlResolver.resolve(raw);

      expect(
        resolved,
        'https://drive.google.com/uc?export=download&id=1rpIJ5pNTmgWxtDq43O4-gWWr3xklCz6B',
      );
    });

    test('resolves Google Drive open query link', () {
      const raw =
          'https://drive.google.com/open?id=14gOVwlVm2Rpiu7pfPAW6Dqg5d3l2VoZW';
      final resolved = AudioUrlResolver.resolve(raw);

      expect(
        resolved,
        'https://drive.google.com/uc?export=download&id=14gOVwlVm2Rpiu7pfPAW6Dqg5d3l2VoZW',
      );
    });

    test('preserves already-direct Google Drive download links unchanged', () {
      const raw =
          'https://drive.google.com/uc?export=download&id=14gOVwlVm2Rpiu7pfPAW6Dqg5d3l2VoZW';
      final resolved = AudioUrlResolver.resolve(raw);

      expect(resolved, raw);
    });

    test('preserves direct mp3 or CDN links unchanged', () {
      const raw = 'https://my-cdn.com/songs/track_01.mp3';
      final resolved = AudioUrlResolver.resolve(raw);

      expect(resolved, raw);
    });

    test('handles empty or whitespace strings safely', () {
      expect(AudioUrlResolver.resolve(''), '');
      expect(AudioUrlResolver.resolve('   '), '');
    });
  });
}
