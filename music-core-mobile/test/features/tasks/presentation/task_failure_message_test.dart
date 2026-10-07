import 'package:flutter_clean_architecture_example/core/result.dart';
import 'package:flutter_clean_architecture_example/features/tasks/domain/failures/task_failure.dart';
import 'package:flutter_clean_architecture_example/features/tasks/presentation/task_failure_message.dart';
import 'package:flutter_clean_architecture_example/l10n/app_localizations_en.dart';
import 'package:flutter_clean_architecture_example/l10n/app_localizations_zh.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps task failures to English messages', () {
    final localizations = AppLocalizationsEn();

    expect(
      taskFailureMessage(const InvalidTaskTitleFailure(), localizations),
      'Enter a task title.',
    );
    expect(
      taskFailureMessage(const TaskNotFoundFailure(), localizations),
      'This task no longer exists.',
    );
    expect(
      taskFailureMessage(const StorageFailure(), localizations),
      'Local data is temporarily unavailable.',
    );
    expect(
      taskFailureMessage(const _UnknownFailure(), localizations),
      'Something went wrong. Please try again.',
    );
  });

  test('maps task failures to natural Chinese messages', () {
    final localizations = AppLocalizationsZh();

    expect(
      taskFailureMessage(const InvalidTaskTitleFailure(), localizations),
      '请输入任务标题',
    );
    expect(
      taskFailureMessage(const TaskNotFoundFailure(), localizations),
      '找不到这条任务',
    );
    expect(
      taskFailureMessage(const StorageFailure(), localizations),
      '暂时无法访问本地数据，请稍后重试',
    );
    expect(
      taskFailureMessage(const _UnknownFailure(), localizations),
      '出了点问题，请稍后重试',
    );
  });
}

final class _UnknownFailure extends AppFailure {
  const _UnknownFailure();
}
