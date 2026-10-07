import 'package:flutter/widgets.dart';
import 'package:flutter_clean_architecture_example/l10n/app_localizations.dart';
import 'package:flutter_clean_architecture_example/l10n/app_localizations_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('uses the context locale when the delegate is absent', (
    tester,
  ) async {
    late AppLocalizations localizations;

    await tester.pumpWidget(
      Localizations(
        locale: const Locale('zh'),
        delegates: const [DefaultWidgetsLocalizations.delegate],
        child: Builder(
          builder: (context) {
            localizations = appLocalizationsOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(localizations.loginSubtitle, '使用以下任一演示账号登录，即可体验应用。');
  });

  testWidgets('falls back to English for an unsupported context locale', (
    tester,
  ) async {
    late AppLocalizations localizations;

    await tester.pumpWidget(
      Localizations(
        locale: const Locale('fr'),
        delegates: const [DefaultWidgetsLocalizations.delegate],
        child: Builder(
          builder: (context) {
            localizations = appLocalizationsOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(localizations.loginTitle, 'Sign in');
  });
}
