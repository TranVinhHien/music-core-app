# Development guide

## Toolchain and dependency baseline

The current baseline targets Flutter `3.47.5` stable, Dart `3.13.4`, Gradle
`9.3.1`, Android Gradle Plugin `9.1.0`, Kotlin Gradle Plugin `2.4.0`, and Java
`17` source/JVM targets for Android. The lockfile is committed and the manifest
uses compatible stable constraints. Confirm the installed toolchain before
changing code:

```bash
flutter --version
dart --version
flutter pub get
dart run build_runner build
flutter gen-l10n
```

The generated `.g.dart`, `.freezed.dart`, and localization Dart files are build
outputs. Change their source declarations and regenerate; do not edit them by
hand.

## Manual dependency maintenance

There is no Dependabot or Renovate configuration. Dependency maintenance is a
human-reviewed change, performed at least monthly and immediately for a
Flutter stable release or relevant security advisory:

1. Check Flutter stable and Pub stable releases.
2. Run `dart pub outdated --no-transitive` and inspect the direct dependencies.
3. Upgrade related runtime/generator packages together, especially Riverpod,
   Drift, and Freezed groups.
4. Read the relevant migration notes before changing source code.
5. Run generation, formatting, analysis, unit/widget tests, and both platform
   flavor build gates.
6. Review the lockfile and documentation, then keep the upgrade only if the
   complete local verification matrix passes.

Do not describe a dependency combination as a verified baseline until all
required gates pass. Do not auto-merge upgrades.

## Run flavors

Both platforms expose the same two flavors and entry points:

| Flavor | Entry point | Android application ID | iOS bundle ID | Database |
| --- | --- | --- | --- | --- |
| `dev` | `lib/main_dev.dart` | `com.example.flutter_clean_architecture_example.dev` | `com.example.flutterCleanArchitectureExample.dev` | `flutter_clean_architecture_example_dev` |
| `prod` | `lib/main_prod.dart` | `com.example.flutter_clean_architecture_example` | `com.example.flutterCleanArchitectureExample` | `flutter_clean_architecture_example_prod` |

```bash
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor prod -t lib/main_prod.dart
```

The flavor changes app identity, local database name, and diagnostic logging.
It does not change business rules or select a backend.

## Adding a feature

Start with the user-visible behavior and its domain vocabulary.

1. Add or refine the domain entity, value object, failure, and repository
   contract.
2. Add the smallest data implementation and storage mapping.
3. Register the implementation in `lib/app/dependencies.dart`.
4. Add a Riverpod controller for asynchronous/shared state or a query selection
   consumed by another provider. Keep lifecycle-only objects in the widget.
5. Add the page and localized text.
6. Add tests at the lowest useful seam and an integration assertion only for a
   critical cross-layer user journey.
7. Regenerate and run the verification commands.

Do not add a network client, environment loader, secure token store, generic
base class, or platform service until a concrete requirement needs it.

## Deliberate next-step triggers

The baseline stops at the local product boundary. Extend it only when a real
requirement appears:

- change the Drift schema only with a versioned migration and upgrade test;
- add a remote adapter only after a concrete backend contract exists;
- design synchronization and conflicts only when local and remote sources of
  truth coexist;
- add a named use case only when one behavior coordinates multiple repositories
  or a transaction;
- add release notes, signing, contribution, or security policy when the
  project actually starts that operating process.

Until then, do not add token refresh, secure storage, biometric login, generic
repositories, event buses, telemetry, release automation, or extra platforms.

## Localization

Edit `lib/l10n/app_en.arb` first for the canonical key set and keep
`lib/l10n/app_zh.arb` in sync. Generated localization Dart files are outputs.
Translate intent rather than English word order: Simplified Chinese text must
read naturally in its UI context, use the actual domain meaning, and receive a
human review before generation. For example, the incomplete-task filter is
`未完成`, because the product models completion rather than progress.
Regenerate them with:

```bash
flutter gen-l10n
```

## Storage and migrations

The task schema is in `lib/features/tasks/data/tasks_table.dart`, query behavior
belongs in `TaskDao`, and mapping belongs in `TaskRepositoryImpl`. The current
candidate schema is version 1 and uses Drift's default creation behavior. A
future released schema change must increase the version, add a real upgrade
step, preserve existing data, and include an upgrade test.

The session preference contains only the active Demo account ID. There are no
environment files, runtime secrets, signing credentials, or production data in
this example.

## Platform configuration

Android uses Flutter-provided SDK and NDK values, Java 17 source/JVM targets,
AndroidX, and the `dev`/`prod` application identity suffix. On iOS, Flutter
3.47.5's generated
Swift Package Manager integration supplies the current plugins; there is no
Podfile or CocoaPods include to maintain. iOS keeps the two shared flavor
schemes and simulator builds without signing. Team IDs, certificates,
provisioning profiles, and release signing are intentionally absent.

## Code style

Use `dart format`, fatal analysis, explicit public return types, and direct
control flow. Comments should explain a boundary or invariant, not restate an
obvious line of code. Keep platform files focused on platform identity and
build behavior; product rules stay in Dart.

Place each `ref.watch` at the smallest widget that renders that value and use
`select` when only one field or loading flag matters. A page shell should use
`ref.listen` for one-off feedback without rebuilding. Do not use `setState` for
state already owned by Riverpod, and do not move text controllers, focus nodes,
form keys, or dialog results into providers.

Keep stable Widget test keys in their owning feature's presentation scope.
Production widgets, Widget tests, and integration tests should share those
typed keys; do not create an application-wide key registry in `core`.

Handwritten Dart source must not use postfix null assertions. Use nullable
access, pattern checks, or an explicit fallback instead. Localization access is
centralized so a missing delegate falls back by supported locale and then to
English; generated files remain generator-owned and are not manually rewritten.

## Verification

Run the shared quality gates after code changes:

```bash
dart run build_runner build
flutter gen-l10n
# After staging the intended source and generated output:
git diff --exit-code -- lib
git diff --check
dart format --output=none --set-exit-if-changed lib test integration_test
dart analyze --fatal-infos --fatal-warnings
flutter test
```

After the intended source and generated changes are staged, the generated-diff
check proves that regeneration leaves no additional `lib/` changes. It does not
replace reviewing the final diff. Run Android and iOS flavor builds when
platform or shared application code changes, and run the Android integration
flow when a user journey changes. The exact platform commands and verification
responsibilities are listed in [the testing strategy](testing.md).
