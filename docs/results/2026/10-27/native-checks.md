# Approved native checks

27 October 2026. The owner approved the published proposal in the active
conversation: “Approve Conductor native checks”.

## Observed results

[Run 40592964162](https://github.com/alvarovillalbaa/conductor/actions/runs/40592964162),
[job 122501632367](https://github.com/alvarovillalbaa/conductor/actions/runs/40592964162/job/122501632367),
completed successfully at `2026-10-27T22:13:56Z` on source
`43ad8d071592f5e196bbcd36d75de53ebf2ef70f`. That commit only installed the
approved example as `.github/workflows/focused-native.yml`; app/core source is
unchanged from the initial published implementation.

- Standard `macos-15` runner, observed arm64 image, macOS 15.7.9.
- Swift 6.1.2, Xcode 16.4, build 16F6; Swift 5 language mode from the project.
- Metadata checks passed: helper shell syntax, Info.plist, privacy manifest,
  project property list and `git diff --check`.
- `swift test` executed **40 tests with zero failures**, as confirmed from the
  job logs, not inferred only from the green step.
- The generic iOS Simulator build with `CODE_SIGNING_ALLOWED=NO` reported
  **BUILD SUCCEEDED**. The expected AppIntents metadata-extraction warning
  reports that this app has no AppIntents dependency; no such feature is claimed.

There was one dispatch and no source-fix rerun. No dependency/cache/artifact
installation workflow, model/provider call, paid runner, signing identity,
Apple/Expo account or billing change was introduced. The temporary active
workflow is removed after terminal execution; the inactive example remains in
`docs/proposals` as approved-scope evidence.

## Limits

This proves core tests on that runner and unsigned iOS compilation. The app was
not launched; no simulator was booted. SwiftUI appearance, physical task flow,
real local-file recovery/persistence, notification authorization/races/delivery,
clock changes in use, accessibility, physical-device signing, app icons, store
assets and distribution remain unverified or unfinished. The local Storage
Guard restriction remains in force. The all-project goal is active.
