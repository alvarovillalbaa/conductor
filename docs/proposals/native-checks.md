# Proposed Conductor native checks

Status: inactive and pending explicit approval. No workflow is installed.

The local preflight on 2026-10-27 found 28.7 GiB free against 38.0 GiB required for
the estimated iOS build workload. Command Line Tools is the selected developer
directory; a full Xcode/iOS build has not been established locally. No build,
test, simulator boot, app launch or notification prompt ran.

After approval, install the [prepared workflow](native-checks-ci.yml.example)
under `.github/workflows/conductor-native-checks.yml`, publish it and dispatch
once on `main`. The temporary workflow is removed after terminal execution and
its exact commit/job/results are recorded. Do not relax checks to get a pass.

## Execution scope

- One standard public `macos-15` GitHub runner, 20-minute timeout, read-only
  repository token, shallow checkout, no persisted Git credentials.
- Record source/toolchain; check helper/XML/project syntax; run the authored
  in-memory ConductorCore tests with SwiftPM.
- Build the Conductor Xcode scheme for the generic iOS Simulator SDK using
  `CODE_SIGNING_ALLOWED=NO`, with temporary DerivedData owned by the runner.
- Do not boot a simulator, launch/automate the app, request permissions, deliver
  notifications, access user data or call any model/provider.
- No dependency install, cache, artifact upload, IPA/archive/store release,
  Apple/Expo account, certificate, paid/larger runner or billing change.

The [standard public runner](https://docs.github.com/en/actions/how-tos/write-workflows/choose-where-workflows-run/choose-the-runner-for-a-job)
uses an existing GitHub service capability. No artifact storage is proposed.
Provider rejection is not permission to change plans/accounts or use larger
runners.

This would prove core behavior on that runner and unsigned iOS compilation.
It would not establish rendered UI, recovery/storage behavior, notification
races/delivery, simulator/device behavior, clock changes during real use,
physical-device signing, app icon/store assets, privacy approval or distribution.
