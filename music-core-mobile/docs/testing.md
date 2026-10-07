# Testing strategy

The suite follows behavior boundaries. It does not impose an arbitrary global
coverage percentage.

## Test levels

| Level | Scope | Examples |
| --- | --- | --- |
| Unit | Pure rules, providers, mappers, and adapters | title validation, filter selection, failure text, repositories |
| Widget | One screen's rendering and interaction | login validation/loading, task filters/actions, localized states |
| Architecture | The documented import direction | domain/data/presentation import checks |
| Integration | Critical Android user flow | sign in, create, complete, rename, delete, re-login |

Repository tests use Drift's in-memory database. Widget tests override the
repository and auth providers, so they do not depend on disk state. The
integration flow is deterministic in its inputs and does not use a network,
remote fixture, random service, or fixed delay.

## Local commands

```bash
dart run build_runner build
flutter gen-l10n
git diff --check
dart format --output=none --set-exit-if-changed lib test integration_test
dart analyze --fatal-infos --fatal-warnings
flutter test
```

Run the end-to-end flow on an Android target:

```bash
flutter test integration_test -d <device-id>
```

The unit tests cover session restoration, unknown-session cleanup, operational
storage failure mapping, propagation of programming errors, task title
validation, CRUD, filtering, owner isolation, filter-provider transitions, and
feature-local failure messages. Localization tests cover the deterministic
fallback when a delegate is unavailable. Widget tests cover login
validation/loading/error feedback, natural Chinese text, task empty/error
states, filter-driven subscriptions, shared create/rename editor flows, and
disabled task controls during a mutation. The integration flow covers the
critical task lifecycle and confirms that a signed-out account sees its task
after signing in again.

## Verification gates

Before treating a revision as a verified baseline, maintainers should run:

- code generation and localization followed by generated-diff and whitespace
  checks;
- formatting and fatal static analysis;
- unit, widget, and architecture tests;
- Android `dev` and `prod` debug builds;
- the Android `dev` integration flow in an emulator;
- iOS `dev` and `prod` simulator builds without signing.

These checks do not build a signed release or publish anything. Signing and
distribution require project-specific credentials and release policy. Passing
unit and widget tests alone does not establish a verified baseline; that label
requires every listed check to pass for the same revision.

## Adding coverage

When changing a rule, update the unit test at that rule's owner. When changing
a screen interaction, add a widget test if it can be isolated. Update the
integration flow only for a journey that crosses composition, persistence, and
UI. Keep tests deterministic and avoid time-based waiting.
