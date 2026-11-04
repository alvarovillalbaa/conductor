# One real UI acceptance case — source preparation

Original preparation: 31 October 2026. Update: 4 November 2026. The current owner
instruction covers one public `macos-15` job, capped at 20 minutes.
[Attempt 1](../results/2026/10-31/ui-acceptance-attempt-1.md) reached the first
installed-runtime query's 30-second deadline before simulator creation or UI
execution. That timeout does not establish runtime absence or a transient cause.
That bounded repair raised only the first query to 90 seconds.
[Attempt 2](../results/2026/11-02/ui-acceptance-attempt-2.md) then completed
runtime checks and create/boot commands, but the post-boot and cleanup inventories
each reached their 30-second bounds before any app build or UI test. Explicit
simulator deletion was unverified; the cause of the inventory timeouts is unknown.
The device-wait repair retained 90-second device inventories, a 180-second cleanup
reserve and created identity before boot. [Attempt 3](../results/2026/11-02/ui-acceptance-attempt-3.md)
then reached the first runtime query's 90-second deadline before simulator
creation, app build or UI execution. All three failed UI attempts remain preserved.

The [metadata-only probe](../results/2026/11-02/simulator-environment-probe.md)
passed on 2 November and was recorded on 3 November. Its ordered runtime queries
used the runner's original `TMPDIR`, a fresh owned `TMPDIR`, then the original
value again: 24,072 ms, 824 ms and 263 ms, each with the same 16 runtimes and
available iOS 18.5. This ordering can include service/cache warming; it does not
establish that `TMPDIR` caused the earlier timeouts or prove repeatability.

Apple tools use the runner's actual `TMPDIR` string for
Apple tools after validating that it is absolute and names an existing directory.
It preserves that string exactly, including aliases or a trailing separator.
Controller scratch, DerivedData, xcresult and ledgers retain their existing owned
paths. Other environment values, process/cleanup budgets, toolchain/device pins
and the one UI case are unchanged. There is no retry or direct-UUID fallback.
[Attempt 4](../results/2026/11-03/ui-acceptance-attempt-4.md) completed metadata,
simulator creation/boot and verified owned deletion, but Xcode exited 64 before
app build or the authored case: `-test-iterations 1` requires more than one
iteration. The xcresult's failed node is an argument-error placeholder, not an
execution of the authored UI case. Successful bootstrap on this runner does not
establish a `TMPDIR` cause for earlier timeouts.

The single-execution CLI repair removed that argument pair and uses Xcode's default
single execution, with no repetition or retry flag. The exact selected UI case,
parallel-testing setting, actual exit check, strict one-passed-case xcresult
identity/totals gates and all other resources remain unchanged.
[Attempt 5](../results/2026/11-03/ui-acceptance-attempt-5.md) stopped at the initial
runtime query. Its one terminal-job retry, [attempt 6](../results/2026/11-04/ui-acceptance-attempt-6.md),
created and booted the owned simulator and verified deletion, but Xcode exited 70
because it could not match the destination. Neither attempt ran the authored UI case.

The complete 37-byte create-stream hash matches the native uppercase UUID plus
newline; the controller had normalized that same numeric UUID to lowercase.
The interoperability repair returns canonical uppercase UUIDs while retaining
all numeric identity, metadata/ledger comparisons, exact runtime/device pins and
the single case. Casing causality remains unproven because the old complete Xcode
destination list was not retained.

Diagnostic-only failure evidence retains a bounded destination-error head and up
to four lines matching only the owned UUID/name, with original source line indices
and Available/Ineligible section labels. Its serialized field remains below
three KiB, after existing path/control sanitization, and never affects acceptance.
The [seventh attempt](../results/2026/11-04/ui-acceptance-attempt-7.md) selected its
owned destination but Xcode warned that both arm64 and x86_64 matched. Compilation
failed because `ConductorCore` was available for arm64 but missing for the x86_64
simulator target. Xcode exited 65; xcresult contained zero cases, and both source
guards and verified owned deletion passed. No authored UI case executed.

This next bounded profile requires the actual `os.uname().machine` value to be
exactly `arm64` at prepare entry, before Apple tool or simulator operations, and
records it in toolchain evidence. The existing owned controller scratch lifecycle
is unchanged. Xcode receives the same owned UUID with explicit iOS Simulator and
arm64 destination qualifiers, `ARCHS=arm64` and `ONLY_ACTIVE_ARCH=YES`. This aligns
the app, UI target and local SwiftPM package for one architecture without changing
the project, Swift source, package or UI case. There is no architecture fallback
or portability claim. All other flags, environment, deadlines, output limits and
identity/source/cleanup gates remain unchanged. This revision has not executed
and supplies no build or UI pass.
Root publishes this preparation and
seal first, then pins separate activation. Both temporary UI and metadata-probe
workflows must be absent from the pinned preparation commit.

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
iPhoneSimulator SDK **18.5**, an actual **arm64** host, available runtime
`com.apple.CoreSimulator.SimRuntime.iOS-18-5` and explicit supported-device
intersection with `com.apple.CoreSimulator.SimDeviceType.iPhone-16`.
It never downloads a runtime/SDK/package or substitutes a device/version.
`DEVELOPER_DIR` selects the preinstalled toolchain without changing global settings.

The [source seal](../results/2026/11-04/ui-acceptance-source-arm64.json) is
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
The created-identity snapshot is emitted even if a later inventory fails; it is
evidence of creation, not evidence of shutdown/deletion, and never bypasses
current metadata verification for cleanup.

The exact `xcodebuild test` selection uses default single execution without any
repetition/retry flag, parallel testing off, the owned arm64 simulator destination,
`ARCHS=arm64`, `ONLY_ACTIVE_ARCH=YES`,
`CODE_SIGNING_ALLOWED=NO`, no code coverage or package update/resolution, and
owned DerivedData/result paths. Commands have bounded time/output and dedicated
process groups. The first runtime-list query and normal/cleanup device inventories
are bounded to 90 seconds; other JSON commands retain their 30-second limit.
The boot-status bound remains 120 seconds. Cancellation/deadline sends TERM
followed by KILL after three
seconds, with a further three-second pipe-drain bound and bounded reap attempts.
Any unreaped command makes acceptance fail, including optional metadata work;
`processesReaped` is reported separately from scratch removal. The controller
reserves 15 minutes for work and 180 seconds for cleanup and the final source guard.
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
