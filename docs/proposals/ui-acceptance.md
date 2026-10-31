# One real UI acceptance case — source preparation

31 October 2026. The current owner instruction and root's exact assignment cover
one public `macos-15` job, capped at 20 minutes. These files are authored only:
no local build, test, simulator boot, app launch, installation or dispatch ran.
Root publishes a preparation commit containing the new source seal, replaces
the workflow's base placeholder with that full SHA, then activates separately.
The active workflow must be absent from the pinned preparation commit.

The sole scheme is `ConductorUIAcceptance`; the sole selection is
`ConductorUITests/ConductorUITests/testPlanAndRunSurviveRelaunchWithExplicitCompletion`.
The existing 40 core tests, old scheme, package and assets are not rerun or altered.

The authored UI journey uses real controls to create/save one plan with one
two-minute task, relaunch and verify the plan, create the soonest run and verify
Waiting/Ready, explicitly Start then Pause, relaunch and verify Paused, Resume,
tap the explicit Done control, and relaunch to verify Done/completion count.
There is no seeded workspace, fake clock, launch backdoor, import/export, generic
alert approval, notification permission prompt, delivery test or TCC change.
Normal startup may query notification status/pending requests and remove owned
requests; reminders remain disabled by default.

## Exact resources and guards

[`script/run_ui_acceptance.py`](../../script/run_ui_acceptance.py) uses Python
stdlib only. Before creating a simulator it requires exact Xcode **16.4 (16F6)**,
iPhoneSimulator SDK **18.5**, available runtime
`com.apple.CoreSimulator.SimRuntime.iOS-18-5` and explicit supported-device
intersection with `com.apple.CoreSimulator.SimDeviceType.iPhone-16`.
It never downloads a runtime/SDK/package or substitutes a device/version.
`DEVELOPER_DIR` selects the preinstalled toolchain without changing global settings.

The [source seal](../results/2026/10-31/ui-acceptance-source.json) is
`conductor.ui-acceptance-source.v1`: complete `files` entries
`{path,mode,gitBlob,bytes,sha256}`, `fileCount`, `totalBytes`,
`excludedPrefixes:["docs/results/"]` and the exact scope recorded by the controller.
All tracked non-results paths, index modes/blobs and current bytes/modes must
match before and after; the seal's own bytes must match `git show HEAD`.
Only results are excluded. Neither this workflow nor an arbitrary caller ref
may silently enter the approved source set.

A fresh nonce name and exact runtime/type are recorded before `simctl create`;
the returned UUID is recorded before boot. Every later simulator lookup and
cleanup requires the same name/runtime/type/UUID. A lost creation response can
be reconciled only by that unique recorded name, never a generic device list
deletion. Cleanup attempts shutdown/delete of only the owned simulator, then
removes only marker/device/inode-verified scratch, including failure paths.
No existing simulator is erased, reused or granted a permission.

The exact `xcodebuild test` selection has one iteration, parallel testing off,
`CODE_SIGNING_ALLOWED=NO`, no code coverage or package update/resolution, and
owned DerivedData/result paths. Commands have bounded time/output and dedicated
process groups; cancellation/deadline sends TERM followed by KILL after three
seconds, with a further three-second pipe-drain bound and bounded reap attempts.
Any unreaped command makes acceptance fail, including optional metadata work;
`processesReaped` is reported separately from scratch removal. The controller
reserves 15 minutes for work and 120 seconds for cleanup and the final source guard.
The job's independent cap remains 20 minutes. Actual command exits, stop reasons,
captured/observed sizes and SHA-256 hashes remain visible; errors are not turned
into successful cases.

## Result and limits

Acceptance requires actual `xcodebuild` exit 0, exactly one matching passed UI
case and xcresult totals 1 passed/0 failed/0 skipped, plus both source guards
and cleanup. Unknown/malformed xcresult schemas fail closed. No core-case count
or static build is substituted for this UI result. The pinned tool's modern
`xcresulttool get test-results summary/tests/activities` commands provide bounded
metadata. Apple's [Xcode 16.3 notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-16_3-release-notes)
document these interfaces and their command help; actual schema compatibility
still requires the future recorded CI run.

The UI test attaches `paused-after-relaunch` and `done-after-relaunch` screenshots.
If available, the controller retains only matching attachment metadata and the
activities JSON hash. Screenshot pixels are discarded with the owned xcresult,
unviewed; no visual appearance/accessibility acceptance is claimed. No raw broad
xcresult, screenshot, diagnostic archive or environment dump is uploaded.
The final stdout receipt is capped at 64 KiB.

This one authored simulator journey cannot establish physical-device behavior,
notifications, backup/import/export recovery, corrupt/save-failure behavior,
clock changes, accessibility or distribution. It does not complete Conductor
or the portfolio goal. Root retains canonical publication and result ownership.
