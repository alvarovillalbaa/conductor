# UI acceptance attempt 4 — Xcode argument rejection

The [same run 41736678251](https://github.com/alvarovillalbaa/conductor/actions/runs/41736678251) failed on **3 November 2026 UTC**, job `126267549783`, after creating and booting its owned simulator. **0 of 1 authored UI cases ran.** This receipt was authored on 4 November in Europe/Madrid; no new run was started.

Checked source: `8499877a8033ecc5054e823578e639998cbe3f8e`; activation: `bc6538e5117a2fa2ddd6c22b00cecda5ae40939b`. Both source guards passed **51 files /200,096 bytes** with seal SHA-256 `aee668f1d0fef9547038b84cd610e31ca2b3b479b68d7cefcc2f333d6d80422b`.

Exact Xcode 16.4 (16F6), SDK 18.5, runtime/device-type checks, simulator creation, boot and boot-status completed. The UI command then exited **64**, with no stdout and 77 stderr bytes:

> xcodebuild: error: Must specify -test-iterations with more than 1 iteration.

No app build or authored UI test began. The xcresult's one failed node is the synthetic “xcodebuild encountered an error (64)” placeholder; strict case identity/status validation correctly refused it. It is not a failed execution of the authored journey.

Owned simulator: `1e04361c-a87c-4c28-97fd-1497f0057722`, named `conductor-ui-17a48822fb24445bbb7bbcc3ec5b5e8e`, exact iOS 18.5/iPhone 16. Shutdown exited 0; ownership was revalidated; delete exited 0 and the final guarded inventory verified absence. All 26 subprocesses were reaped, scratch removal passed and no interruption/timeout occurred. No separate post-shutdown state projection was retained.

[Machine receipt](ui-acceptance-attempt-4.json) preserves the complete controller report, all command hashes, created identity, xcresult, both guards and cleanup. The runner-standard temporary environment coincided with successful bootstrap; it does **not establish a cause** for prior timeouts or repeatability. No UI/visual, notification, physical-device or distribution acceptance is claimed. Earlier attempts and the separate metadata probe remain preserved.
