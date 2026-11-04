# UI acceptance attempt 5 — runtime query timeout

The [same run 41738433727](https://github.com/alvarovillalbaa/conductor/actions/runs/41738433727), job `126273530467`, failed on **3 November 2026 UTC** before simulator creation, build or UI execution. **0 of 1 authored UI cases ran.** This receipt was authored on 4 November in Europe/Madrid; no new run was started.

Checked source: `928c70ca31b1b2d2631da5df23439cc7b32a0d35`; activation: `2f87c04ee156836a9f3ee30ca06d20f51ccb1473`. Exact Xcode 16.4 (16F6) and SDK 18.5 checks completed. The first `xcrun simctl list runtimes -j` query then reached its configured **90-second deadline**, produced no stdout/stderr and exited **-15 (SIGTERM)**. It was reaped. Error: `Refused:runtimes_failed`.

Both source guards passed **51 files /200,788 bytes**, seal SHA-256 `91c37ee95f612802ecd162fa207687039d34e24a601006e898681f10322dd6a6`. All 11 command processes were reaped; scratch cleanup passed. Simulator cleanup was a no-op because no simulator or owned identity was created. No device inventory/create/boot, app build, UI-test or xcresult command ran. The single-run CLI repair was not reached or verified.

[Machine receipt](ui-acceptance-attempt-5.json) preserves the complete report, command hashes, source checks and cleanup. Runtime absence, a permission/transient cause and TMPDIR causality remain unproven; the runner-standard value did not prevent this failure. The [fourth attempt's](ui-acceptance-attempt-4.md) bootstrap and verified deletion remain separate evidence. No UI, visual, notification, physical-device or distribution acceptance is claimed. Root owns the next review and workflow retirement.
