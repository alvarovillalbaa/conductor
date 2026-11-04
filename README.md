# Conductor

A native iOS coordinator for tasks that need to finish together. Define the
tasks and their durations, choose a shared finish time, and Conductor works
backward to show when each task should start.

**Initial native implementation. Forty core tests and an unsigned generic iOS
Simulator build passed in approved CI. The full simulator journey, physical-device
behavior, notifications and distribution remain unverified.**
The later app icon passed its SVG/PNG comparison, metadata checks and
[unsigned asset-catalog compilation](docs/results/2026/10-31/app-icon-build.md).
Its system appearance remains unverified.
This is not a released iOS application.

On 4 November, [UI attempt 8](docs/results/2026/11-04/ui-acceptance-attempt-8.md)
executed the exact authored case and failed waiting for the minutes Stepper:
1 test, 0 passed, 1 failed. [Attempt 9](docs/results/2026/11-04/ui-acceptance-attempt-9.md)
then stopped at the post-boot device inventory's 90-second deadline, before any
UI case or Stepper diagnostic. Both attempts verified owned-resource cleanup.
The query's cause and actual accessibility element type remain unknown.
Further Conductor execution is pending an external tool/service change or an
evidence-supported source repair; unchanged retries, longer timeouts and weaker
identity checks are not the next step.

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
- `Resources`: app-icon asset catalog, bundle metadata and provisional privacy manifest.
- `artwork/app-icon.svg`: editable original icon; `script/render_app_icon.py`
  exports its opaque 1024-square PNG using Python's standard library.

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
The app-icon source and Xcode resource wiring are prepared. Run
`python3 script/render_app_icon.py --check` to compare the PNG with its SVG
master, or omit `--check` to export changes. Icon compilation passed on Xcode
16.4 / iOS Simulator SDK 18.5 at immutable source
`e278b0798faaea57df97a5d2b63b910340b55e0c`. That asset receipt applies to its pinned
revision; later UI preparation has separate source seals and results. Reproduce
the guarded compilation at the receipt's revision. System appearance, screenshots
and App Store publication remain open.

The latest UI diagnostic source was checked at
`ca8fb846490fb587730ead0029644182b4013206`, but did not reach XCTest. This later
documentation edition changes only this README and the
[UI status/contract](docs/proposals/ui-acceptance.md); its other 49 sealed inputs
remain unchanged. Keep the original seal and reproduce that exact pinned source.

## Scope and evidence

- [Product brief](docs/specs/product.md)
- [Core/app contract](docs/specs/core-contract.md)
- [Architecture](docs/architecture.md)
- [Prepared native checks](docs/proposals/native-checks.md)
- [Initial source receipt](docs/results/2026/10-27/initial-source.md)
- [Approved native check results](docs/results/2026/10-27/native-checks.md)
- [App-icon source evidence](docs/results/2026/10-28/app-icon.md)
- [App-icon compilation results](docs/results/2026/10-31/app-icon-build.md)
- [UI acceptance status and source contract](docs/proposals/ui-acceptance.md)

This local app needs neither Vercel nor Supabase. Source publication does not
establish working native delivery; the broader all-project goal remains active.
