import 'package:flutter_clean_architecture_example/core/result.dart';
import 'package:flutter_clean_architecture_example/features/auth/domain/failures/auth_failure.dart';
import 'package:flutter_clean_architecture_example/features/auth/presentation/auth_failure_message.dart';
import 'package:flutter_clean_architecture_example/l10n/app_localizations_en.dart';
import 'package:flutter_clean_architecture_example/l10n/app_localizations_zh.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps authentication failures to English messages', () {
    final localizations = AppLocalizationsEn();

    expect(
      authFailureMessage(const InvalidCredentialsFailure(), localizations),
      'The email or password is incorrect.',
    );
    expect(
      authFailureMessage(const StorageFailure(), localizations),
      'Local data is temporarily unavailable.',
    );
    expect(
      authFailureMessage(const _UnknownFailure(), localizations),
      'Something went wrong. Please try again.',
    );
  });

  test('maps authentication failures to natural Chinese messages', () {
    final localizations = AppLocalizationsZh();

    expect(
      authFailureMessage(const InvalidCredentialsFailure(), localizations),
      '邮箱或密码不正确，请重新输入',
    );
    expect(
      authFailureMessage(const StorageFailure(), localizations),
      '暂时无法访问本地数据，请稍后重试',
    );
    expect(
      authFailureMessage(const _UnknownFailure(), localizations),
      '出了点问题，请稍后重试',
    );
  });
}

final class _UnknownFailure extends AppFailure {
  const _UnknownFailure();
}
