# Repository guide

Read [CONTEXT.md](CONTEXT.md) before changing product behavior and consult the
focused documents under `docs/` for architecture, development, and testing.

## Documentation ownership

- `CONTEXT.md` defines product vocabulary only.
- `docs/adr/` records durable decisions with meaningful trade-offs.
- `docs/architecture.md` explains dependencies, state, and data flow.
- `docs/development.md` owns the toolchain and development workflow.
- `docs/testing.md` owns verification responsibilities and manual gates.
- `docs/tasks-walkthrough.md` follows the implemented product journey.
- `docs/ux-ui.md` ux-ui design partent for this application.

Update the owning document when behavior changes. Link to it from other
documents instead of copying detailed rules across files.

## Local conventions

- Keep the three-layer feature structure: `domain`, `data`, and
  `presentation`; keep application composition under `lib/app`.
- Domain code must not import Flutter, Drift, or platform adapters.
- Define repository contracts in `domain`; implement them in `data`.
- Use Riverpod for shared/reactive state and query selections that drive other
  providers. Keep lifecycle objects such as text controllers, focus nodes, and
  form keys inside their owning widget; do not place them in providers.
- Limit provider watches to the smallest widget that renders the selected
  value. Avoid `setState` when Riverpod already owns the state, and do not use
  postfix null assertions in handwritten Dart source.
- Add a concrete use case only for real business orchestration. Do not add
  generic use-case, repository, event-bus, or service-locator abstractions.
- Treat the generated `.g.dart`, `.freezed.dart`, and localization Dart files
  as build outputs: regenerate them with `dart run build_runner build` and
  `flutter gen-l10n`, then commit the resulting files.

## Verification

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

Run both platform flavor builds when platform or shared application code
changes. Run the Android integration test on a device or emulator when changing
a user flow. Pure documentation changes do not require repeating platform
builds. Do not add secrets or machine-specific paths to the repository.
