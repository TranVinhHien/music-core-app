import '../../../core/result.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/failures/task_failure.dart';

/// Maps task failures to user-facing localized text.
String taskFailureMessage(AppFailure failure, AppLocalizations localizations) =>
    switch (failure) {
      InvalidTaskTitleFailure() => localizations.taskTitleRequired,
      TaskNotFoundFailure() => localizations.taskNotFound,
      StorageFailure() => localizations.storageError,
      _ => localizations.unexpectedError,
    };
