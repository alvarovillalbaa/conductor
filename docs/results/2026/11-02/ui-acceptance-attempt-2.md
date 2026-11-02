# UI acceptance attempt 2 — post-boot inventory timeout

The [single repaired-source run](https://github.com/alvarovillalbaa/conductor/actions/runs/41414866879) failed **after simulator create/boot commands but before app compilation or UI execution**. **0 of 1 authored UI cases ran. Simulator shutdown/deletion is unverified.**

- Tested source: `38c7a06d0dcd6fbe555bb4a98945a15be0752bdd`, tree `0ca92dc89bcf01ae507194565568b3d650278f6e`.
- Workflow: `7d62bb9db3d4b444b2f21936564a961718bcde36`, SHA-256 `87cbe645495645491484df1d7c2c6f8c76cd9d58e77f5e093f6828a7cffa615a`.
- Run `41414866879`, attempt 1, push/main; 2026-11-02T08:41:12Z–terminal update 08:45:10Z. [Job `125176157650`](https://github.com/alvarovillalbaa/conductor/actions/runs/41414866879/job/125176157650) and controller failed; actual report emitted 08:44:05.5866070Z. No retry.

Exact Xcode **16.4 (16F6)**, SDK **18.5**, available iOS 18.5 and explicit iPhone 16 support passed preflight. The runtime-list query now completed within its 90-second bound. Initial device inventory, simulator creation, fresh-device identity check, boot and boot-status commands each exited 0.

The next `xcrun simctl list devices -j` call (command 14, the post-boot identity/state check) reached its **30-second deadline**, returning empty stdout/stderr and **SIGTERM exit -15**. Cleanup's equivalent inventory call (command 19) also timed out. Reported errors: `Refused:devices_failed` and `Refused:cleanup-devices_failed`. This evidence does not establish the underlying cause or justify calling it transient, a missing runtime or a permission failure.

Cleanup reported **`simulatorCleanup=failed`**, with no shutdown or delete command issued: current metadata could not verify ownership, so deletion was refused. The controller had written the created UUID/name to an owned ledger, but did not emit them in its report; `scratchCleanup=passed` removed that ledger. Explicit simulator deletion cannot be confirmed. The ephemeral hosted-runner boundary is separate from owned cleanup and is not recorded as deletion proof.

All recorded command processes were reaped (`processesReaped=true`); no global interruption occurred. Both source guards passed **51 files /197,998 bytes**, seal SHA-256 `a044c9ec503cb14322f7fe0db757020987f784db9c3887506526af5ab897d37f`. Controller SHA-256 `a28238f2ad9f047f5d07360853818a77d5a8f689feac584c37aa7a8143d1793d`. These successes do not replace the missing UI result or failed simulator cleanup.

The [machine receipt](ui-acceptance-attempt-2.json) retains the actual 19-command report: **7,314 bytes** raw JSON, SHA-256 `ee8246cc082202018489225a55a2908fcd867fa247d459898b8bbca6a995f9bc`, excluding log timestamp/newline. Timeout streams were empty; command elapsed times and raw inventory JSON were not retained. Existing limits were 15 minutes for work, 120 seconds for cleanup, 3-second TERM/KILL and drain bounds, 20-minute job cap.

[Attempt 1](../10-31/ui-acceptance-attempt-1.md) failed earlier, before runtime JSON or creation. Both failures remain historical. No app/test/image/project change or new run was made while preserving this attempt. No app build/install/launch, core-test repeat, xcresult, screenshot, notification acceptance, signing, account, model or paid action occurred. Root owns any next bounded repair/activation; the UI journey and full delivery goal remain unfinished.
