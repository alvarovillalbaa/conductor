# Installed simulator runtime probe

The [single metadata-only run](https://github.com/alvarovillalbaa/conductor/actions/runs/41244816480) succeeded. It observed installed runtimes and device-type metadata; **no simulator was booted and no app was built, installed or launched**.

- Workflow source: `0ddd8b3f7f50eca9bb6a424408ab95fa78ead28f`, tree `a93a3ff5f931778321cfdf66fe915627ed74b468`; workflow SHA-256 `d63f627fd7f3ab7b8085ae16cb6d49deecfe00423fa4c6eceaeff0efaa102c40`.
- Run `41244816480`, attempt 1, push/main; 2026-10-31T21:42:13Z–21:42:36Z. [Job `124665932710`](https://github.com/alvarovillalbaa/conductor/actions/runs/41244816480/job/124665932710) and metadata step succeeded. Projection emitted at 21:42:35.0038390Z. No retry.
- Actual selected Xcode: **16.4 (16F6)**. The standard public runner label was `macos-15`.

Exactly three checked subprocesses completed: `xcodebuild -version`, `xcrun simctl list runtimes --json` and `xcrun simctl list devicetypes --json`. Their individual full output hashes/durations were not recorded. The emitted projection contains **16 available runtime entries** and **41 iPhone device-type identifiers**; explicit per-runtime supported-device intersections are retained in the [JSON receipt](simulator-runtime-probe.json).

| Runtime family | Available metadata versions |
| --- | --- |
| iOS | 18.5, 18.6, 26.0.1, 26.1, 26.2 |
| tvOS | 18.5, 26.1, 26.2 |
| watchOS | 11.5, 26.1, 26.2 |
| visionOS | 2.3, 2.4, 2.5, 26.1, 26.2 |

A metadata-supported candidate for later Conductor UI work is:

- Runtime: `com.apple.CoreSimulator.SimRuntime.iOS-18-5` (`isAvailable=true`, version 18.5).
- Device type: `com.apple.CoreSimulator.SimDeviceType.iPhone-16`, explicitly included in that runtime's supported-device intersection.

This pair matches the prior unsigned build's SDK18.5 baseline. It has **not** been created, booted or exercised here. The global type list is inventory rather than universal compatibility; availability of other iOS/visionOS entries does not prove that selected Xcode can boot or test them.

The exact path-free projection is **12,936 bytes**, SHA-256 `251d820f53b9b01d57b29a27e3eba0d7a4bc81e119fc46a6ac076b206852e9d3`, excluding log timestamp/prefix/newline. Only Xcode version/build, runtime identifiers/names/versions/availability and iPhone identifiers were printed. This is not a hash of full simctl output or tool binaries.

Each command was bounded to 30 seconds, 1 MiB stdout/64 KiB stderr, with TERM then three-second KILL escalation on abort. Final projection was capped at 64 KiB; the job limit was three minutes. No repository checkout, product import, source guard, test target, simulator-create/boot, build/install, runtime download, launch, permission prompt, notification acceptance, signing, store/account action or provider/model call was in scope. Ordinary metadata-query service/cache activity is not a claim of a general system-write sandbox.

This identifies a candidate environment for a later authored plan/save/run/persistence UI journey. It supplies **no UI acceptance proof**. Existing source/artwork and prior results remain unchanged. The final metadata publication removes the probe workflow before UI-test implementation.

A separate read-only inspection through the connected local XcodeBuildMCP
`list_sims` tool returned `xcrun: error: unable to find utility "simctl", not a
developer tool or in PATH`. No local toolchain change, build or boot followed.
The installed-runtime evidence above belongs to the disposable GitHub runner.
