import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feature imports preserve the documented layer direction', () {
    final features = Directory('lib/features');
    expect(features.existsSync(), isTrue);

    for (final file in _dartFiles(features)) {
      final path = file.path.split(Platform.pathSeparator);
      final layerIndex = path.lastIndexWhere(
        (segment) => const {'domain', 'data', 'presentation'}.contains(segment),
      );
      expect(layerIndex, isNonNegative);

      final layer = path[layerIndex];
      final imports = file
          .readAsLinesSync()
          .where((line) => line.trimLeft().startsWith('import '))
          .join('\n');

      if (layer == 'domain') {
        expect(imports, isNot(contains('package:flutter/')));
        expect(imports, isNot(contains('package:flutter_riverpod/')));
        expect(imports, isNot(contains('package:drift')));
        expect(imports, isNot(contains('package:shared_preferences')));
        expect(imports, isNot(contains('/data/')));
        expect(imports, isNot(contains('/presentation/')));
        expect(imports, isNot(contains("'../../../app/")));
      }

      if (layer == 'data') {
        expect(imports, isNot(contains('/presentation/')));
        expect(imports, isNot(contains("'../../../app/")));
      }

      if (layer == 'presentation') {
        expect(imports, isNot(contains('/data/')));
      }
    }
  });
}

Iterable<File> _dartFiles(Directory directory) sync* {
  for (final entity in directory.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) yield entity;
  }
}
