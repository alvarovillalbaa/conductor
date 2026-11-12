# Bounded Simulator startup and original UI journey

The 11 November run passed the seven storage cases but failed inside
`XCUIApplication.launch()`, with `DTServiceHubClient` connection interruptions.
The application never reached the first plan action. The original receipts stay
in [the current-toolchain record](ui-current-toolchain.md). On 13 November the
GitHub artifact API returned no retained artifacts for run `43000742926`; the
previous spindump contents cannot be recovered from the checked-in inventory.

The [current official image inventory](https://github.com/actions/runner-images/blob/main/images/macos/xcode-27-arm64-Readme.md)
still lists image `20261104.0337.1`, Xcode 27.2 / 27B52 and iOS 27.2. No toolchain
repair is inferred. [Runner issue 15247](https://github.com/actions/runner-images/issues/15247)
concerns first-call runtime mounting on older images; its reproduction does not
establish the cause of this app-launch failure.

This preparation uses Alvaro's standing approval to obtain new startup evidence
in one public `xcode-27` job, capped at 20 minutes. Local Storage Guard measured
3.6 GiB free against 38 GiB required on 13 November; no local native command,
Simulator boot, install or build is authorized by this preparation. Application,
project, package, icon, storage tests and the original UI test stay byte-identical
to `01acb6560244c9210edc6c34c72e46e57ecde736`.

The controller builds the original UI scheme for testing, creates exactly one
owned iPhone 17 / iOS 27.2 device, then checks `simctl bootstatus -b` readiness.
It installs and directly launches the app, verifies its reported PID is still
registered after three seconds, retains a PNG, and checks that launching an empty
workspace creates no saved workspace file. The screenshot must be viewed before
making any screen-content claim. These observations diagnose startup, not the
complete workflow or Xcode debugger-service health.

Only after those observations succeed does it terminate and uninstall its own
app, confirm the old data container is absent, and execute the original one-case
UI journey with `test-without-building`. Xcode must install a fresh app again.
There is no locator, expectation or timeout change: the case retains its
180-second allowance and explicit completion requirement. The prior seven
storage and forty core passes are carried, not replayed. This is a changed
startup procedure, not evidence that an unobserved infrastructure cause is fixed.

The 900-second work deadline, separate 180-second cleanup deadline, exact UUID,
runtime/name/device ledger and source guards remain. Commands retain bounded
stdout/stderr artifacts with original counts and hashes, including failures.
XCTest text diagnostics, if present, are retained as bounded deterministic gzip
files before PNG selection; missing PNGs cannot discard a new spindump again.
No background notification permission, signing, account, provider/model call,
dependency change or paid service is involved. No automatic retry is included.

The temporary active workflow lives only on the exact QA branch and checks out
the sealed source. After the terminal receipt is retained, disable that workflow
and delete only its owned QA ref. Keep every failed source seal and result.

The [inactive workflow template](ui-startup.workflow.yml.example) is reviewable
before dispatch. This document is preparation, not an execution result.

The first startup run stopped before Xcode: the new stream filename check
incorrectly rejected the existing `beforeSourceGuard-head` label. Its terminal
report and original job log are retained in [attempt 1](../results/2026/11-13/ui-startup-attempt-1.md).
The observer now validates labels, including ASCII uppercase, before spawning
and records each completed command before attempting artifact writes. The second
preparation changes this observer defect and its owned ref/seal only; there is
no app, test, expectation, toolchain or timeout change.

The second run completed the unsigned build and created/deleted its owned
Shutdown device, but the probe read help on stdout only. Actual `simctl` help
arrived on stderr and explicitly documented `-b`. Its [complete original packet](../results/2026/11-13/ui-startup-attempt-2.md)
is retained. The third preparation reads both retained streams for this help
probe. It keeps the startup operations and original UI assertions unchanged;
neither earlier startup run reached a boot or app launch.
