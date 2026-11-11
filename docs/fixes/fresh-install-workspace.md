# Fresh-install workspace loading

A fresh install entered recovery for its absent `workspace.json`, leaving Create
a Plan disabled. The [actual iOS screenshot](../results/2026/11-11/fresh-install-recovery.png)
and XCTest activity log established that the editor had never opened; the missing
minutes Stepper was a later symptom.

`WorkspaceFileStore.load()` now handles both Foundation missing-file categories,
then confirms absence through throwing filesystem metadata. It returns an empty
workspace without writing a file only when that lookup also reports absence.
Existing paths rethrow the open error; other lookup/read/decode errors propagate.
This preserves recovery for malformed, oversized and unreadable data. A directory
at the workspace path is also rejected. The app's storage location and save logic
are unchanged.

The same Foundation-only file is compiled by a small internal SwiftPM target for
isolated tests. [Run 43000742926](https://github.com/alvarovillalbaa/conductor/actions/runs/43000742926)
at source `cb542661210e28d6b2396cec9f7aa06845c2483a` passed seven actual cases:
missing file and missing parent without writes, saved-workspace reload with exact
bytes, malformed and oversized original retention, directory rejection and an
unavailable data location. The [retained xUnit XML](../results/2026/11-11/workspace-file-store-tests.xml)
has seven cases and no failures, errors or skips. Its bytes, digest and names were
independently verified. The older forty core cases were not selected.

The following iOS case failed during Xcode app launch before any plan action.
The [original controller report](../results/2026/11-11/ui-acceptance-current-toolchain-8.json)
records the actual failed case and simulator service errors. Both 54-input source
guards, all 26 subprocess reaps and owned simulator/scratch cleanup passed.
This verifies the macOS storage regressions, while iOS first launch, save/relaunch,
run transitions and explicit completion remain unaccepted. Physical-device,
notification and distribution checks also remain open.

The [preparation history](../proposals/ui-current-toolchain.md) retains all earlier
failures, including the initial directory-regression failure and one unverified
simulator deletion. Original reports and source seals are immutable. This final
documentation edition preserves all application, package, test and controller
bytes from the checked source; its temporary active workflow is omitted.
