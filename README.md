# Conductor

A native iOS coordinator for tasks that need to finish together. Define the
tasks and their durations, choose a shared finish time, and Conductor works
backward to show when each task should start.

**Initial source implementation. Native compilation, tests,
simulator/device behavior, notifications and distribution are not verified.**
This is not a released iOS application.

## Intended workflow

- Save reusable plans with up to 20 tasks, each lasting 1 second to 24 hours.
- Pick a feasible common finish time or the soonest target; confirm each task's
  actual start yourself.
- Start, pause, resume, complete or skip tasks explicitly; inspect late/early
  estimates without silently moving the shared target.
- Keep the current run locally between visits. Plan edits affect future runs.
- Enable optional local reminders in context. In-app cues work without them.
- Export data and retain unread/failed data for recovery.

A timer reaching zero does not mark a physical task complete. Local reminders
depend on iOS permissions/settings and may be delayed or suppressed. There is no
continuous background execution, server, remote push, account, model provider,
collaboration or iCloud sync. Device clock changes affect Date-based estimates.

## Project layout

- `Conductor.xcodeproj`: native iPhone/iPad app project, shared Conductor scheme.
- `App/Conductor`: SwiftUI views, app state, local storage and notification adapter.
- `Sources/ConductorCore`: scheduling/state/validation/codec, Foundation only.
- `Tests/ConductorCoreTests`: authored deterministic core tests.
- `Resources`: bundle metadata and provisional privacy manifest.

The app links the local Swift package; there are no external package dependencies.
The default bundle ID is `com.alvarovillalbaa.Conductor`. No Apple team or signing
identity is embedded. An Expo account is not used.

## Development checks

Use Xcode 15 or newer with an iOS 17+ SDK. Open `Conductor.xcodeproj` and select an
appropriate simulator for manual development. Respect the local Storage Guard
before native builds/tests; never delete unrelated data to bypass it.

```sh
./script/check_native.sh core-tests
./script/check_native.sh ios-simulator
```

The second command builds an unsigned generic Simulator target and never boots
a simulator or launches an app. The Codex action is explicitly a build action.
Physical-device signing, notification delivery and store distribution need their
own account/acceptance steps; no paid enrollment is created by these scripts.
App icon/store assets and App Store publication are not prepared by this initial
source slice.

## Scope and evidence

- [Product brief](docs/specs/product.md)
- [Core/app contract](docs/specs/core-contract.md)
- [Architecture](docs/architecture.md)
- [Prepared native checks](docs/proposals/native-checks.md)
- [Initial source receipt](docs/results/2026/10-27/initial-source.md)

This local app needs neither Vercel nor Supabase. Source publication does not
establish working native delivery; the broader all-project goal remains active.
