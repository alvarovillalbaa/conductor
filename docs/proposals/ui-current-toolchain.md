# UI verification on a current simulator environment

The previous diagnostic stopped before XCTest on the macOS 15 image
`20261028.0489.1`. Its UI case and diagnostic remain available. The public
macOS 26 image lists Xcode 26.2 build 17C52, iOS Simulator SDK 26.2 and an iOS
26.2 runtime supporting iPhone 17. This is a different simulator environment.
The previous failures remain evidence for their original environment.
[Previous run](https://github.com/alvarovillalbaa/conductor/actions/runs/41820365843) · [Published runner inventory](https://github.com/actions/runner-images/blob/releases/macos-26-arm64/20261102/images/macos/macos-26-arm64-Readme.md)

The [first current-toolchain run](https://github.com/alvarovillalbaa/conductor/actions/runs/42990021122)
timed out on the initial runtime list after ninety seconds. It created no
simulator and reached no app build or XCTest case. Both 53-input source guards,
process reaping and cleanup passed. Its [original JSON](../results/2026/11-11/ui-acceptance-current-toolchain-1.json)
is 4,604 bytes, SHA-256 `66ea0674cd88e4a95e78d43dc1d609d83eb14203b4597c21c1ec8984a21199e6`.

GitHub's runner-images issue 15247 documents cold-start runtime scans on the
CoreSimulator service shipped with Xcode 16/26. Its author reports a bounded
reproduction avoiding that scan on the Xcode 27 service. The report supports
testing that different service; it does not identify the cause of our timeout.
The published `xcode-27` image includes Xcode 27.0/27A266a, SDK/runtime 27.0
and iPhone 17. Use those preinstalled tools for a second profile.
[Primary issue](https://github.com/actions/runner-images/issues/15247) · [Published inventory](https://github.com/actions/runner-images/blob/releases/xcode-27-arm64/20261104/images/macos/xcode-27-arm64-Readme.md)

Use one public `xcode-27` job, capped at twenty minutes, with the existing
test `testPlanAndRunSurviveRelaunchWithExplicitCompletion`. It creates and
saves a plan through the UI, checks it after relaunch, starts and pauses its
run, relaunches, resumes, explicitly confirms completion and relaunches again.
The failure-only Stepper diagnostic stays in place.

Pin Xcode 27.0/27A266a, SDK/runtime 27.0 and iPhone 17 on arm64. The controller
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
