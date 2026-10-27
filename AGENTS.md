# Conductor

- Native, local iOS task-finish coordinator. SwiftUI, Foundation and UserNotifications only; no account, telemetry, hosted dependency or model call.
- Read docs/specs/product.md and docs/specs/core-contract.md before changing behavior.
- ConductorCore owns deterministic scheduling, run transitions, validation and JSON codec. App/Conductor owns UI, local storage and native notification boundaries.
- Planned finish, estimated finish and user-confirmed completion are different. Never mark a task complete merely because its timer reached zero.
- Freeze task definitions into each run. Editing/removing a reusable plan must not mutate an existing run. Guard stale task/run/form actions.
- Persist validated candidate state before presenting an action as saved or scheduling its reminders. Failed/unread data must remain recoverable; never silently filter or overwrite it.
- Ask notification permission only after explicit user action. Fence late authorization/add results and remove only this feature's owned requests. Local reminders are best effort, not guaranteed background execution.
- No app launch, simulator boot, notification delivery/permission prompt, signing or store submission as an incidental check. Native build/tests respect Storage Guard; CI requires the workspace approval gate.
- Source publication is authorized by the owning all-project task. No Apple/Expo account or paid enrollment is authorized.
- Manual edits use apply_patch; run git diff --check and narrow syntax/static checks. Do not claim parsing proves compilation, persistence, notification or UI behavior.
