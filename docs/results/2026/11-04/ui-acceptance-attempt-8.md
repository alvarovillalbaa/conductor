# Conductor UI acceptance — attempt 8

**The exact authored UI case executed and failed.** [Run 41817606501](https://github.com/alvarovillalbaa/conductor/actions/runs/41817606501), job `126532254460`, ran on 4 November 2026, 10:57:08–11:06:19 UTC. The [full receipt](ui-acceptance-attempt-8.json) retains the actual controller report and stream fingerprints.

Activation `7278f694fbdaf3047458cdfe31215de8968c23ef` checked source `c0ceae6943ca7428acabba632a5695e5be973fef` against the [51-input arm64 seal](ui-acceptance-source-arm64.json). Actual `uname` architecture was **arm64**, with Xcode 16.4 (16F6), SDK/runtime 18.5 and iPhone 16. The sealed invocation selected its owned UUID with `platform=iOS Simulator,arch=arm64`, `ARCHS=arm64`, `ONLY_ACTIVE_ARCH=YES` and signing disabled. Those flags are source configuration evidence; actual architecture is recorded by the controller.

Build/launch progressed into `testPlanAndRunSurviveRelaunchWithExplicitCompletion()` under the expected scheme/target/class. Its first failure was **line 21**, `XCTAssertTrue(minutes.waitForExistence(timeout: 10))`, querying the `plan.task.minutes.` Stepper immediately after Create Plan. The report does not establish why the query failed. The UI command exited **65**, with no timeout/output stop. Actual xcresult totals are **1 test / 0 passed / 1 failed / 0 skipped**. This is an authored failure, not a synthetic Xcode node.

Both source guards passed: **51 files / 205,670 bytes**. Owned simulator `45A26BFA-6785-41C7-AD63-EEED4244843F` was revalidated, shutdown/deleted with exit 0, and verified absent. Scratch cleanup and all **26** subprocess reaps passed; only the UI command was nonzero. No separate post-shutdown state projection was retained.

No end-to-end pass is claimed: save/relaunch, run transitions, persistence and explicit completion were not reached. Screenshots, physical-device behavior, notifications and distribution remain unverified. The [previous failure](ui-acceptance-attempt-7.md) stays preserved. No source change, repair, rerun or publication accompanies this receipt.
