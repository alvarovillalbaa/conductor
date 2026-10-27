# Conductor product scope

Source intent is the inline “(ios) Conductor — coordinar tareas que deben terminar a la vez” brief in [Alvaro's project page](https://app.notion.com/p/311a1ee8bd06805caa21c5306dd315ac), fetched 2026-10-27. The search found only this parent entry for Conductor. The parent reports truncation/three unknown blocks elsewhere; no full-parent completeness claim is made. The workflow below is an implementation choice.

Create a native iOS 17+ app that coordinates estimated-duration tasks around a shared finish time. It works locally with no account, hosted service, Expo account, model call or paid provider.

1. Create/edit/delete reusable named plans with up to 20 independently timed tasks, each lasting 1 second to 24 hours. Keep plans on the device. Plan edits use revision checks.
2. Choose a shared finish time or the soonest feasible target, where the longest task is due immediately. Show each planned start, reject impossible finish times and freeze the definitions into a new run. Creating the schedule does not claim a physical task has started; users confirm each start.
3. Show start cues and remaining time. Explicit actions start, pause, resume, complete or skip tasks. Overdue timers remain unfinished until the user confirms completion. Show late/early estimates without silently moving the shared target.
4. Keep the current run between visits. Editing its reusable plan does not change it. A stopped/finished run remains visible until an explicit replacement; no historical archive is promised.
5. Offer optional local reminders only after user authorization. Schedule future start cues, running-task time-elapsed cues and the shared target. Cancel/reconcile owned requests after changes and foreground return. Past cues appear in-app rather than being repeatedly replayed.
6. Export local data and preserve unread/corrupt/unsupported saved files. Failed saves do not claim success or schedule new reminders. A complete reread/validated import is required before normal writes resume.

The app coordinates people; it cannot control physical tasks or guarantee simultaneous completion. Times are absolute Date instants, recomputed for display; device clock changes affect elapsed estimates and reminder timing. iOS can delay or suppress notifications. No continuous background timer, remote push, collaboration, iCloud sync, Live Activity or App Store release is implied.
