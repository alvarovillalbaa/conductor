# UI acceptance attempt 3 — runtime query timeout

The [single device-wait packet run](https://github.com/alvarovillalbaa/conductor/actions/runs/41416379248) failed **before simulator creation, app build or UI execution**. **0 of 1 authored UI cases ran.**

- Tested source: `0330112e74f9f06c10ae951d57ba44cb1524e6a2`, tree `0eaad323a30e053c097af0c9b2210da646ac7c5c`.
- Workflow: `73bc9c595eeca2a9df9e77a8eef9bdbb63ec4997`, SHA-256 `8e2dbe96612d5746726fb0197feaa3a48b5e659c94f79769e47d1d4b54edeec4`.
- Run `41416379248`, attempt 1, push/main; created 2026-11-02T08:53:46Z, terminal failure updated 08:55:56Z. [Job `125181126760`](https://github.com/alvarovillalbaa/conductor/actions/runs/41416379248/job/125181126760) failed with controller exit 1. Actual report emitted 08:55:50.3099280Z. No retry or observation-timeout restart.

The exact Xcode 16.4 (16F6) and SDK 18.5 checks completed. The first `xcrun simctl list runtimes -j` command then reached its configured **90-second deadline**, returned no stdout/stderr and terminated with **SIGTERM exit -15**. Error: `Refused:runtimes_failed`. Its process was reaped. The underlying cause remains unknown; runtime absence, a transient condition and a permission problem are not established. The earlier 30-second bound alone cannot be treated as a complete explanation of all failures.

Both source guards passed **51 files /198,871 bytes**, seal SHA-256 `e3a377293f034a423c3e61b0c8a16ac940a5ebb8a9375c6bd51b91f9469faa1b`. Controller SHA-256 `bb86da55c467cb26c1344edeef372a6ecd9b7226967459aac6f81343f727123b`. The runtime list produced no JSON in this attempt, so runtime availability remains unobserved.

No device inventory/create/boot, build, UI-test or xcresult command ran. No `createdSimulator` or `ownedSimulator` snapshot exists. Cleanup reported `processesReaped=true`, `simulatorCleanup=passed` and `scratchCleanup=passed`; simulator cleanup was a no-op because none was created. This does not establish deletion for the separately failed [attempt 2](ui-acceptance-attempt-2.md).

The [machine receipt](ui-acceptance-attempt-3.json) preserves all 11 actual command rows and the complete report: **4,542 bytes** raw JSON, SHA-256 `26488944eb033de79951f9c082230eb45b9cefe4199c62bc0dce409519149f1d`, excluding log timestamp/newline. Empty runtime streams each hash to `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`. Individual command elapsed times were not recorded. Work/cleanup limits remained 15/3 minutes under the 20-minute job cap; boot-status 120 seconds was not exercised.

[Attempt 1](../10-31/ui-acceptance-attempt-1.md) and attempt 2 remain preserved. No source, case, image, project or further run was changed while observing this result. There was no local simulator action, core-test repeat, app launch, notification acceptance, export/import, signing, account, model or paid action. Root owns review before any next step. UI and full delivery acceptance remain unfinished.
