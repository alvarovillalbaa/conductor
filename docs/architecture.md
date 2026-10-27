# Architecture and boundaries

ConductorCore uses Foundation value types to calculate a task's planned start
from a common finish, retain run snapshots, apply explicit transitions and
validate complete workspace JSON. It performs no network, disk or notification
operations. The iOS app owns atomic local persistence, UI and UserNotifications.

Mutable app state is owned on the main actor and shared by scenes. Candidate
mutations must validate and persist before committing UI success or starting
reminder reconciliation. Plan forms carry expected revisions; task controls
carry the active run ID. Invalid saved data gates writes and remains exportable.
Notification authorization is an explicit user action, not an initialization
side effect.

The notification adapter reconciles only future cues for the current run. Its
requests use operation-qualified identifiers and generation checks around awaits.
Late results may remove their own stale identifiers, not newer requests. System
permission denial, disabled presentation and scheduling errors stay visible.
See Apple's [authorization API](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/requestauthorization(options:completionhandler:))
and [pending request API](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/getpendingnotificationrequests(completionhandler:)).

The foreground timeline recomputes from persisted dates instead of depending on
a continuously running background process. Planned/estimated/user-confirmed times
remain distinct. Reaching zero is a cue, not proof of physical completion.

The Xcode target imports the local Swift package and includes its own privacy
manifest. The initial manifest declares no tracking, collection or required-reason
API use; it must be reviewed against actual APIs and release requirements before
distribution. A manifest file is not App Store approval or privacy certification.

Source parsing cannot validate iOS SDK linkage, actor isolation, persistence,
notification races, simulator/device behavior or distribution. Native checks
remain separate evidence, with no implicit permission to boot or automate a device.
