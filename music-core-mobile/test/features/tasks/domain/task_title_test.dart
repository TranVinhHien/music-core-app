import 'package:flutter_clean_architecture_example/core/result.dart';
import 'package:flutter_clean_architecture_example/features/tasks/domain/failures/task_failure.dart';
import 'package:flutter_clean_architecture_example/features/tasks/domain/value_objects/task_title.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('trims a non-empty task title', () {
    final result = TaskTitle.create('  Read the docs  ');

    expect(result, isA<ResultOk<TaskTitle>>());
    expect((result as ResultOk).value.value, 'Read the docs');
  });

  test('rejects an empty task title', () {
    final result = TaskTitle.create('   ');

    expect(result, isA<ResultError<TaskTitle>>());
    expect((result as ResultError).failure, isA<InvalidTaskTitleFailure>());
  });
}
