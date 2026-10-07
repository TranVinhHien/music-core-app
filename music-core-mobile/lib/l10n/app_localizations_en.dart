// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginSubtitle =>
      'Use one of the public Demo accounts to explore the app.';

  @override
  String get demoCredentials => 'Demo credentials';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get emailRequired => 'Enter an email address.';

  @override
  String get passwordRequired => 'Enter a password.';

  @override
  String get loginButton => 'Sign in';

  @override
  String get invalidCredentials => 'The email or password is incorrect.';

  @override
  String get storageError => 'Local data is temporarily unavailable.';

  @override
  String get unexpectedError => 'Something went wrong. Please try again.';

  @override
  String get retry => 'Retry';

  @override
  String get tasksTitle => 'Tasks';

  @override
  String get logout => 'Sign out';

  @override
  String get filterAll => 'All';

  @override
  String get filterActive => 'Active';

  @override
  String get filterCompleted => 'Completed';

  @override
  String get emptyTasksTitle => 'No tasks yet';

  @override
  String get emptyTasksMessage => 'Create a task to see it here.';

  @override
  String get addTask => 'Add task';

  @override
  String get editTask => 'Edit task';

  @override
  String get deleteTask => 'Delete task';

  @override
  String get taskTitleLabel => 'Task title';

  @override
  String get taskTitleRequired => 'Enter a task title.';

  @override
  String get deleteTaskConfirmation => 'This task will be permanently deleted.';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get taskNotFound => 'This task no longer exists.';

  @override
  String get pageNotFound => 'Page not found.';
}
