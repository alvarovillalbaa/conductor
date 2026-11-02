# UI acceptance attempt 1 — preflight timeout

The [single run](https://github.com/alvarovillalbaa/conductor/actions/runs/41246942006) failed **before simulator creation, compilation or UI execution**. **0 of 1 authored UI cases ran**; this is not a failure of that UI case.

- Tested source: `c034063fea3a513df0b20210b41e32fb163ae15c`, tree `8945faf1c4b03ae811f577f3c92d0600f27e2e0f`.
- Workflow: `bc4030fc141aeda6f8f9d326dd23d29f843ecdd1`, SHA-256 `c29e5fd50ce0cec00a6247f262a3899e52aefbfb6d4c52098dd34233b253333c`.
- Run `41246942006`, attempt 1, push/main; created 2026-10-31T22:10:08Z, updated terminal failure at 22:10:53Z. [Job `124672222910`](https://github.com/alvarovillalbaa/conductor/actions/runs/41246942006/job/124672222910) failed with controller exit 1. Actual report timestamp: 22:10:49.1468290Z. Observed on 2 November without restarting the run.

The failure is `Refused:runtimes_failed`. The first `xcrun simctl list runtimes -j` command reached its configured **30-second deadline**, returned no stdout/stderr and terminated with **SIGTERM (exit -15)**. Its process was reaped. The captured empty streams each have SHA-256 `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`. Individual command elapsed time was not recorded.

The preceding exact Xcode16.4(16F6) and Simulator SDK18.5 checks completed. Runtime availability in this attempt remains **unobserved**. Empty timeout diagnostics do not establish missing runtimes, a transient condition, a permission issue or permanent CoreSimulator failure. The [earlier metadata probe](simulator-runtime-probe.md) remains separate evidence and cannot replace this call's missing result.

Both source guards passed: **51 inputs /197,510 bytes**, unchanged seal SHA-256 `f1367540f1dc1fb15dc80912111c9776475f9baf8edda7401017888643d57a3a`. Actual controller SHA-256: `1e1b7351dbafe733732bdbc96360d645fc574d4ca0f1be6f017af2f5d14fa959`. No create, boot, build, UI-test or xcresult command ran; the 40 core tests were not repeated.

Cleanup reported `processesReaped=true`, `simulatorCleanup=passed` and `scratchCleanup=passed`. No simulator had been created, so simulator cleanup was a no-op; owned scratch was removed. No screenshot pixels, UI result or persistence acceptance was produced.

The [machine receipt](ui-acceptance-attempt-1.json) retains the complete actual controller report. Its exact raw JSON is **4,542 bytes**, SHA-256 `99f5db9f96be4e19a7f7501e49af5a6b85834871a25b29e5ef5661de9903dca0`, excluding log timestamp/newline. The original work/cleanup budgets remained 15 minutes/120 seconds, TERM→KILL grace three seconds, and job cap 20 minutes.

Only these receipts were written while observing the attempt. No source repair, new run, local build/boot/launch, notification prompt/scheduling/delivery, import/export, signing, store/account, model or paid action was undertaken. The failure is preserved before a future bounded preflight repair; root owns review and any next activation. The UI journey and full delivery goal remain unfinished.
