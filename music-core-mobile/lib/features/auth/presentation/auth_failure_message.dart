import '../../../core/result.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/failures/auth_failure.dart';

/// Maps authentication failures to user-facing localized text.
String authFailureMessage(AppFailure failure, AppLocalizations localizations) =>
    switch (failure) {
      InvalidCredentialsFailure() => localizations.invalidCredentials,
      StorageFailure() => localizations.storageError,
      _ => localizations.unexpectedError,
    };
