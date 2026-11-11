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

The controller selects this toolchain, its new source seal and
its task-owned CI branch. The startup change below uses Xcode's test action.
App, core, project and XCTest source stay at their
current bytes. The new seal includes all non-results source paths, including
this proposal and the inactive workflow template. The active workflow lives
in a separate activation commit and checks out the sealed source.

Standing all-work approval covers this necessary native verification. No
notification permission, signing identity, store submission, provider call,
account or paid enrollment is involved. Local Storage Guard prevents local
native builds and simulator work, so execution uses the hosted runner.

## Xcode-owned startup

The [second profile](https://github.com/alvarovillalbaa/conductor/actions/runs/42990748224)
verified the installed Xcode 27.0 tools and runtime/device intersection,
created its simulator and issued a successful boot request. The subsequent
manual boot-status command timed out after 120 seconds. The cleanup inventory
also timed out, leaving explicit simulator deletion unverified. Scratch cleanup
and all subprocess reaps passed. Its [original JSON](../results/2026/11-11/ui-acceptance-current-toolchain-2.json)
is 7,299 bytes, SHA-256 `f1a33c396ce7fa35a20c38317758a9a641c095cb2ae70b7c1b729dfa3563de15`.

The third preparation removes the separate manual boot and boot-status calls.
Xcode's test action starts the specified destination as part of running tests.
The controller still creates a fresh simulator, verifies its exact identity and
Shutdown state, and passes only its UUID to the same test command. All test
assertions, verdict checks, command bounds and metadata-based cleanup remain.
This changes startup ownership and supplies no acceptance from the earlier
failed jobs. [Apple test automation](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/chapters/08-automation.html)

## Failed editor evidence

The [third run](https://github.com/alvarovillalbaa/conductor/actions/runs/42992082373)
executed the actual case and failed at the Stepper lookup. The failure-only
projection found the New Plan navigation bar and no matching plan identifier.
Both source guards and owned simulator/scratch cleanup passed. Its
[original JSON](../results/2026/11-11/ui-acceptance-current-toolchain-3.json)
is 12,006 bytes with SHA-256 `4aaaee09587128dd57348621be071039e0fcce68ce1cde5d183ec183ad486ee7`.

The fourth source retains every assertion and action, adds a failure screenshot,
and admits a fixed list of editor labels into the bounded diagnostic. After an
actual failed test, the controller verifies the installed attachment-export help
and exports failure attachments into its owned scratch. It retains at most eight
PNG images, each at most four MiB, in the job artifact before removing scratch.
The simulator contains only the authored test. No user account or existing data
is present. The diagnostic is intended to determine whether the form is rendered
and how its controls appear to accessibility. It does not qualify a failed case
as accepted.
