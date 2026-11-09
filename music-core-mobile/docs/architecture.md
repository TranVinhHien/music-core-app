# Architecture

The application uses a small three-layer feature structure. It applies Clean
Architecture's dependency direction where it protects a real boundary, without
adding a ceremony-only application framework.

## Layers and ownership

```text
Presentation ──uses──> Domain contracts and models
      │                         ▲
      └──uses providers──> App composition ──creates──> Data adapters
                                      │                       │
                                      └──────────uses──────────┘
```

- `lib/features/*/domain/` owns product vocabulary, invariants, failures, and
  repository contracts.
- `lib/features/*/data/` owns storage adapters, Drift schema/DAO code, and
  repository implementations.
- `lib/features/*/presentation/` owns pages and Riverpod state used by pages.
- `lib/app/` owns startup, dependency composition, routing, theme, and flavor
  configuration.
- `lib/core/` contains only `Result` and the shared `StorageFailure` needed by
  both features.

Domain code does not import Flutter, Riverpod, Drift, SharedPreferences, app,
data, or presentation. Presentation may use app-provided providers, but it
does not import a data implementation. A small architecture test protects
these documented boundaries.

## Why there is no application layer

The current workflows validate one value, call one repository operation, and
let the database stream update the page. A generic `UseCase`, base repository,
event bus, or service locator would add indirection without owning a current
business invariant. Add a named use case only when one behavior coordinates
multiple repositories, a transaction, or another explicit business policy.

## Composition and routing

`lib/app/dependencies.dart` is the composition root. It creates the session
storage, auth repository, flavor-specific Drift database, and task repository.
`bootstrap` overrides only the selected `AppConfig` and installs diagnostics
for `dev`.

`appRouterProvider` observes `authControllerProvider` and implements the route
gate:

```text
restore session
      │
      ├── loading/error without a session state → /splash
      ├── no account                          → /login
      └── account                             → /tasks
```

Command failures are returned to the page that started the command. A bad
login remains on `/login`, and a failed sign-out keeps the current account
state. Unknown route errors map to localized text rather than exposing an
internal exception.

## Result and feature failures

`lib/core/result.dart` contains the intentionally small typed boundary:

- `ResultOk<T>` carries a successful value;
- `ResultError<T>` carries an `AppFailure`;
- `StorageFailure` is the only cross-feature failure because both repositories
  map local persistence errors to it.

Authentication and task failures live in their owning domain feature. The
repository stream uses Dart's native error channel for storage failures:
`Stream<List<TaskItem>>` carries data, and a stream error carries
`StorageFailure`. Mutations return `Result<void>` because the existing Drift
stream is already the source of updated task entities.

Data adapters translate operational `Exception` values into these safe
failures but do not catch Dart `Error` values that indicate programming
defects. Controllers transport the failure without choosing user-facing text.
Each feature's presentation layer maps its own failures to localized messages,
and the page chooses an inline error for loading or a SnackBar for a command.
No UI renders an internal exception string. Presentation obtains localization
through the shared resolver, which uses the loaded delegate when available,
falls back by supported locale, and otherwise returns English. This fallback is
a UI concern and does not enter domain code.

## Presentation state and rebuilds

Riverpod owns screen/query state that affects another provider. Widget-owned
objects such as text controllers and form keys remain local because they have a
lifecycle but are not shared application state. The task filter is therefore an
auto-dispose `TaskFilterController`, while the login and task editor keep their
text controllers in `State` without calling `setState`.

Provider watches are placed at the smallest rendering boundary:

- the task page shell listens to command errors without watching command state;
- account text, sign-out, filter, task list, row controls, and the add button
  select only the values they render;
- changing the filter rebuilds the filter and task list, but not the app bar or
  add button;
- mutation loading rebuilds only task controls, sign-out, and the add button;
- the login button alone watches authentication loading.

## Task data flow

1. `TaskFilterController` owns the auto-disposed selection for the task route.
2. The `taskListProvider` reads the active account and filter providers.
3. It subscribes to `TaskRepository.watchTasks` with the account ID and filter.
4. `TaskRepositoryImpl` maps the owner- and filter-scoped Drift stream to
   domain `TaskItem` values.
5. A command validates `TaskTitle`, writes through the repository, and lets the
   Drift stream emit the updated list.

Every task read, update, and delete includes the owner ID. Inserts persist it,
so account isolation is enforced at the data boundary instead of by a UI-only
filter. There is no query-time seed write or other hidden read side effect.

## Storage schema

The version-1 table stores `id`, `ownerId`, `title`, `isCompleted`, and
`updatedAt`. The initial `updatedAt` is also the creation ordering timestamp.
Drift's default create/upgrade behavior is sufficient while the candidate
schema remains version 1. When a released schema changes, add a real versioned
`MigrationStrategy` and an upgrade test; never add an empty upgrade callback.

## Audio Playback & Auto-DJ Engine

The audio playback subsystem is managed by `SmartCrossfadeAudioPlayer` and `PlayerController`:

```text
PlayerController (Riverpod state)
       │
       ├── uses ──> SmartCrossfadeAudioPlayer (just_audio wrapper)
       │                    │
       │                    ├── Single-player engine (compatible with just_audio_background)
       │                    ├── Intro dead-air skip (cues to cueInMs / first downbeat)
       │                    └── Outro dead-air elimination (fades out 7s before end & advances)
       │
       ├── uses ──> AudioPrecacheService
       │                    │
       │                    └── Background pre-download of upcoming track via Dio to temp disk
       │
       └── queries ──> TransitionRepository
                            │
                            └── GET /api/v1/catalog/transitions/next (harmonic compatibility)
```

- **Single-Player Stability**: Operates on a single `AudioPlayer` instance to fully adhere to platform constraints of `just_audio_background` (lockscreen controls, Android AutoFocus, iOS RemoteCommandCenter).
- **Zero-Latency Pre-caching**: While track N is playing, `AudioPrecacheService` downloads track N+1 to local temporary cache (`precache_tracks/${trackId}.mp3`). When transition triggers, track N+1 plays directly from disk (`AudioSource.file`) with 0ms buffering delay.
- **Dead-Air Suppression**: Eliminates silence gaps at both boundaries — cues into initial audio soundwaves via `cueInMs`, and initiates smooth 1.5s volume fade-out 7s before track completion to seamlessly jump into the next song.

## Generated code

Riverpod providers, Freezed models, Drift accessors, and localization classes
are generated from source files and committed. With the current build_runner
version the conflict flag has been removed, so the canonical command is:

```bash
dart run build_runner build
flutter gen-l10n
```

Regenerate the same outputs before committing and check that the working tree
remains clean.

