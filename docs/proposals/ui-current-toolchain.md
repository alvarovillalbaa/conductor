# UI verification on Xcode 26.2

The previous diagnostic stopped before XCTest on the macOS 15 image
`20261028.0489.1`. Its UI case and diagnostic remain available. The public
macOS 26 image lists Xcode 26.2 build 17C52, iOS Simulator SDK 26.2 and an iOS
26.2 runtime supporting iPhone 17. This is a different simulator environment.
The previous failures remain evidence for their original environment.
[Previous run](https://github.com/alvarovillalbaa/conductor/actions/runs/41820365843) · [Published runner inventory](https://github.com/actions/runner-images/blob/releases/macos-26-arm64/20261102/images/macos/macos-26-arm64-Readme.md)

Use one public `macos-26` job, capped at twenty minutes, with the existing
test `testPlanAndRunSurviveRelaunchWithExplicitCompletion`. It creates and
saves a plan through the UI, checks it after relaunch, starts and pauses its
run, relaunches, resumes, explicitly confirms completion and relaunches again.
The failure-only Stepper diagnostic stays in place.

Pin Xcode 26.2/17C52, SDK/runtime 26.2 and iPhone 17 on arm64. The controller
checks the actual installed versions and device support. Keep the existing
timing, exact test verdict, source seal and owned-simulator cleanup gates.
There is one execution, with no alternate locator or device fallback.

The only controller changes select this toolchain, its new source seal and
its task-owned CI branch. App, core, project and XCTest source stay at their
current bytes. The new seal includes all non-results source paths, including
this proposal and the inactive workflow template. The active workflow lives
in a separate activation commit and checks out the sealed source.

Standing all-work approval covers this necessary native verification. No
notification permission, signing identity, store submission, provider call,
account or paid enrollment is involved. Local Storage Guard prevents local
native builds and simulator work, so execution uses the hosted runner.
