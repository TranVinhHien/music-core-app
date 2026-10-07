import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Returns the loaded strings or a deterministic supported-locale fallback.
AppLocalizations appLocalizationsOf(BuildContext context) {
  final localizations = AppLocalizations.of(context);
  if (localizations != null) return localizations;

  final locale = Localizations.maybeLocaleOf(context);
  final fallbackLocale = switch (locale?.languageCode) {
    'zh' => const Locale('zh'),
    _ => const Locale('en'),
  };
  return lookupAppLocalizations(fallbackLocale);
}
