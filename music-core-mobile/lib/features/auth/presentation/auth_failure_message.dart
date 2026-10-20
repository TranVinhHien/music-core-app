import '../../../core/result.dart';
import '../../../l10n/app_localizations.dart';

/// Maps authentication failures to user-facing localized text or clear messages.
String authFailureMessage(AppFailure failure, AppLocalizations localizations) =>
    switch (failure) {
      UnauthorizedFailure(message: final msg) =>
        msg.isNotEmpty ? msg : localizations.invalidCredentials,
      ConflictFailure(message: final msg) =>
        msg.isNotEmpty ? msg : 'An account with this email already exists.',
      NetworkFailure(message: final msg) =>
        msg.isNotEmpty ? msg : 'Network connection error. Please try again.',
      ServerFailure(message: final msg) =>
        msg.isNotEmpty ? msg : 'Server error. Please try again later.',
      ValidationFailure(message: final msg) => msg,
      StorageFailure() => localizations.storageError,
      _ => localizations.unexpectedError,
    };
