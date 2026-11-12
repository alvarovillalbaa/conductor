# Startup observer attempt 2 — failed help-stream probe

[Run 43332324653](https://github.com/alvarovillalbaa/conductor/actions/runs/43332324653),
job `131579807621`, checked source
`8f649d8ecdebe5674224105e582bfccc09a3563a` from owned QA commit
`25217838dad846616d9d63d46740b0bf7360f457`. The overall job failed.

Xcode 27.2 / 27B52 on arm64, SDK 27.2 and the selected iPhone 17 / iOS 27.2
intersection matched. The original UI scheme's unsigned `build-for-testing`
completed with exit 0. Both complete 57-input / 252,559-byte guards passed with
seal SHA-256 `5263b35e36bc3faa464c28dd63f3d78ee8a0a728f30d3e24c63c06e58c74e9f8`.
The new Simulator `ED2EE9E7-5CD8-47A0-820C-F6E7768163FC` was verified Shutdown.

`simctl help bootstatus` exited 0, emitting zero stdout bytes and 442 stderr
bytes. That stderr documents `Usage: simctl bootstatus <device> [-bcd]` and the
boot-if-needed option. The observer checked stdout alone and incorrectly raised
`bootstatus_flag_unavailable`. No boot, install, launch, screenshot or UI case
was attempted. This is an observer failure, not an absent tool feature or an
application failure. No storage/core cases were selected.

The [original terminal JSON](ui-startup-attempt-2.json) is 12,305 bytes, SHA-256
`db64c051b13afb64168a9848e1c4bafb001f7b91f05ee45de54f6186c59d3fa4`.
The [original artifact ZIP](ui-startup-attempt-2.zip), artifact `13994414963`, is
69,733 bytes, SHA-256
`8cae4386ddd4829720c6df970d781e028e7f165e51d79e7deac1ee6c2e8768a2`, matching
GitHub metadata. All 43 ZIP entries were read: the receipt plus 42 streams for
21 commands. Every stream's captured and observed lengths and SHA-256 matched;
no content was reconstructed. All commands reaped, and exact owned-device
deletion, absence readback and scratch cleanup passed.

The next preparation reads stdout plus its already retained stderr for help.
It preserves this failed verdict, app/project/package/tests, timeouts, toolchain
and all UI acceptance assertions. The accepted storage regressions remain at
their original source; this new build is not iOS behavior acceptance.
