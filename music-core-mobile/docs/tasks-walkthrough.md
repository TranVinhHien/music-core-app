# Tasks feature walkthrough

This is the shortest path through the implemented product behavior.

## 1. Restore and gate the session

`lib/main_dev.dart` or `lib/main_prod.dart` passes an `AppConfig` to
`bootstrap`. The provider graph is created in `lib/app/dependencies.dart`.
`AuthController.build` asks `AuthRepository.restoreSession` for the stored
account ID. The router keeps the user on `/splash` until that work finishes,
then routes to `/login` or `/tasks`.

## 2. Sign in

`LoginPage` validates that both fields are present. `AuthController.signIn`
delegates to `DemoAuthRepository`, which looks up a known email and compares it
with the public Demo password. On success it stores only the account ID and the
router moves to `/tasks`. On failure the controller returns the typed failure,
the auth presentation mapper chooses localized text, and the page displays it
without leaving `/login`.

## 3. Load the account's tasks

`TaskFilterController` owns the auto-disposed filter for the task route. The
task list provider reads that filter and the current `DemoAccount`, then
subscribes to `TaskRepository.watchTasks(ownerId: ..., filter: ...)`. The DAO
applies the owner and active/completed predicates and orders by most recently
updated. Changing the filter rebuilds only the filter/list boundaries and
replaces the scoped stream subscription. The first view is a real empty state;
loading the list does not insert hidden rows or perform another write.

## 4. Create a task

The add button uses `TaskEditorSheet.show` to open the shared title form.
`TaskTitle.create` trims the submitted input and rejects an empty value.
`TaskActionsController.create` passes the validated value to
`TaskRepositoryImpl`, which creates an ID and initial `updatedAt` timestamp,
then inserts a Drift companion. The active DAO stream emits the new row, so the
page updates without a second fetch or manual list cache.

## 5. Complete or rename a task

The checkbox calls `setCompleted`, and the editor sheet calls `rename`. Both
operations find the row with the current owner ID, update the row and
`updatedAt`, and return `TaskNotFoundFailure` if the owner cannot access it.
The segmented control changes the owner-scoped stream query rather than
filtering an unscoped list in the widget.

Task data adapters convert operational persistence exceptions to
`StorageFailure`. The command controller transports the failure as state; the
task presentation mapper converts it to localized text, and the page shows a
SnackBar. Stream failures use the same mapper in an inline retry state.

## 6. Delete and sign out

Delete requires a confirmation dialog, then calls the owner-scoped DAO delete.
Sign-out clears the preference only. The task rows remain in the flavor's
local database and appear again when the same Demo account signs in later.
Alice and Bob use different owner IDs, so each sees only its own rows.

## Useful inspection points

- Domain invariant: `lib/features/tasks/domain/value_objects/task_title.dart`
- Repository contract: `lib/features/tasks/domain/repositories/task_repository.dart`
- Persistence boundary: `lib/features/tasks/data/tasks_table.dart`,
  `task_dao.dart`, and `task_repository_impl.dart`
- Reactive query boundary: `lib/features/tasks/presentation/task_filter_controller.dart`
  and `task_list_provider.dart`
- Task-list UI boundary: `lib/features/tasks/presentation/task_list_view.dart`
- Command and error boundary:
  `lib/features/tasks/presentation/task_actions_controller.dart` and
  `task_failure_message.dart`
