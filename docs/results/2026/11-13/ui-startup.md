# Simulator startup remains unaccepted

The bounded startup investigation did not reach app installation or a UI case.
Two unsigned native `build-for-testing` invocations passed at their separate
sources. No new storage or core cases ran; their earlier accepted receipts stay
at their original revisions. Application, project, package, resources and the
original UI test were not changed during this investigation.

| Attempt | Checked source | Actual outcome |
| --- | --- | --- |
| [1: 43332030657](https://github.com/alvarovillalbaa/conductor/actions/runs/43332030657), job `131578820471` | `0b9e4055bf3cff679bac438e05e8c7f1c7e009b9` | New observer rejected mixed-case labels before Xcode. Command rows were lost; neither source guard completed. [Original report/log and limits](ui-startup-attempt-1.md). |
| [2: 43332324653](https://github.com/alvarovillalbaa/conductor/actions/runs/43332324653), job `131579807621` | `8f649d8ecdebe5674224105e582bfccc09a3563a` | Unsigned build passed. Help arrived on stderr; observer incorrectly read stdout alone. No boot/app/UI action. Both full guards, 21 command reaps and owned cleanup passed. [Original packet and repair](ui-startup-attempt-2.md). |
| [3: 43332815708](https://github.com/alvarovillalbaa/conductor/actions/runs/43332815708), job `131581436361` | `d6da982745c738aeb0e08ccc73b3acf2c3f6d0eb` | Unsigned build passed. Boot command exited 0, but the next device inventory and the later Git/cleanup queries timed out. No app install or UI test. Post-source guard and explicit Simulator deletion are unverified. |

The third run's original [JSON](ui-startup-attempt-3.json) is 10,094 bytes,
SHA-256 `6aad31eb1b57c9460e259bd1f92032796db950b8a908efaccda9dfcdf827c1f7`.
Its original [artifact ZIP](ui-startup-attempt-3.zip), artifact `13995284362`, is
48,343 bytes, SHA-256
`1ab5f057a2ee43e3b661f1263d839eeae87fe7b0b7c1bc1d3ebe8b1d88ae3296`, matching
GitHub's artifact digest and size. All 35 ZIP entries were independently read:
one receipt and 34 complete stdout/stderr streams for 17 commands. Every stream
matched its observed/captured lengths and SHA-256. All 17 command leaders reaped;
this does not prove every Simulator service or descendant stopped.

The starting guard verified 57 inputs / 253,146 bytes against seal
`9c5c82f5f3bc2a104d7d3f0f5ff86975b21e8badae10ee50c36feca0320e7250`.
Xcode 27.2 / 27B52, SDK 27.2, arm64 and the selected iPhone 17 / iOS 27.2
runtime/device intersection matched. Its owned device was
`32FDFD70-8134-4EEF-8C3C-03C2E1F3E3E7`, named
`conductor-ui-8960a725a10d412cbb3e761f6d521621`, initially Shutdown.

`bootstatus -b` emitted 15,205 stdout bytes and no stderr. It exited 0 after its
output reported elapsed 1:29, `Status=4294967295`, `isTerminal=YES`, and `Finished`.
That status is retained without interpreting its opaque value as readiness.
The following device listing timed out with no output; no Booted-state readback
was obtained. The later `git rev-parse HEAD` and cleanup inventory also timed
out without output. Their leaders exited -15 after the controller's deadlines.
These observations do not identify the cause of the post-boot timeouts or the
earlier Xcode service interruption. No product defect is inferred.

The third run's after-source guard failed at its first command, so there is no
full post-run source-integrity claim. Scratch cleanup passed. Explicit shutdown,
deletion and absence readback of this exact Simulator could not be reached;
deletion remains unverified. The historical second current-toolchain profile's
separate deletion gap also remains. Job completion is not explicit resource
teardown proof.

The UI test is unchanged, SHA-256
`81e7e74ffd3e3f6cd25e43691f011cbe71ed88c0ff2f766308c628a8fca79e00`.
There is no new first-screen PNG, app PID, plan action, save/relaunch, run
transition or completion evidence. The seven earlier macOS storage passes do
not supply these missing iOS observations. Physical devices, reminders and
distribution also remain open. No model/provider call, dependency, account,
signing, production setting, paid service or local native runtime was added.

Temporary workflow `416703065` was disabled and read back as `disabled_manually`.
All three exact task-owned QA refs were SHA-checked before deletion; the matching
refs API then returned `[]`. No active workflow was added to main. Source seals,
failed verdicts and original packets remain. The two local download copies were
removed only after hash equality with the retained originals and an empty open
file check; no unrelated source, data or Simulator was deleted.

Further UI execution needs an applicable startup/environment repair or new
diagnostic evidence. Do not rerun this unchanged profile, extend deadlines or
weaken the original case to obtain a green result. The portfolio remains active;
this is a closed diagnostic investigation, not a finished iOS release.
