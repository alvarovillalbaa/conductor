# App-icon compilation — passed

The [single native run](https://github.com/alvarovillalbaa/conductor/actions/runs/41242781804) passed the unchanged icon renderer, project metadata and **unsigned generic iOS Simulator build**. The generated asset catalog and AppIcon metadata were present. **No core tests were rerun.**

- Tested preparation source: [e278b0798faaea57df97a5d2b63b910340b55e0c](https://github.com/alvarovillalbaa/conductor/tree/e278b0798faaea57df97a5d2b63b910340b55e0c), tree `4165b190f7533e5091d7f672ededf4ca8faf8195`. Its 47 non-results files are unchanged from product base `151a50f59a40bde5ff4a6fff068812b19008a10b`.
- Workflow: `e90b60f4c007a0a79e4d45c6ab0cfe8f0021d060`, SHA-256 `584e61965a823c27d7e5b3c5dc4b48d0d08422df26846e1f59025a9b7a4cafe6`.
- Run `41242781804`, attempt 1, push/main; 2026-10-31T21:16:05Z–21:18:49Z. [Job `124659928340`](https://github.com/alvarovillalbaa/conductor/actions/runs/41242781804/job/124659928340) succeeded; controller report emitted at 21:18:44.1312580Z. No retry, signal or timeout occurred.

The actual standard `macos-15` runner was **macOS 15.8.2 (24H232), arm64**, with **Xcode 16.4 (16F6), Swift 6.1.2 and iOS Simulator SDK 18.5**. The renderer used **Python 3.15.2 / zlib 1.2.12** and returned “AppIcon.png matches the SVG export.” No SVG/PNG or renderer bytes changed. Info.plist, privacy manifest, project plist and whitespace checks returned zero.

The exact build used `xcodebuild` for scheme Conductor, Debug, `iphonesimulator`, destination `generic/platform=iOS Simulator`, owned DerivedData and `CODE_SIGNING_ALLOWED=NO`. Actual exit was **0**, with **BUILD SUCCEEDED** observed. Build command duration: **140,338 ms**; combined output: **177,523 bytes**, SHA-256 `1322389778ab98bd1992f38b4b5235a46acfd5e01ef0809b3151fc57b926cc5e`. The controller retained the stream hash and bounded outcome rather than uploading build logs or artifacts.

| Selected generated file | Bytes | SHA-256 |
| --- | ---: | --- |
| `Info.plist` | 1,301 | `d51b45d3e483a4f83a4ae39433152be416a09a80a82edf0ba5be79a4ed4ddf8b` |
| `Assets.car` | 44,319 | `843d924e08556861097d783d2ff24cb305fdd86a5c6a88673b0f0c7299048871` |
| `Conductor` | 72,232 | `0b9e778d50fac0b92e7b4cf8e479de002e4f221239f9971ead167f011637b964` |

Generated metadata selected `AppIcon` as the primary icon and `Conductor` as the executable. These are selected output hashes, not a complete bundle manifest or rendered-icon proof. All outputs were removed with scratch afterward.

All **47 non-results source files /156,325 bytes** matched their modes, Git blobs and SHA-256 values before and after. Complete guard objects are identical. The checked-out seal matched its Git bytes and regular-file mode; seal SHA-256 `0bff884a622010acae9cd1a48201d1db559481b62a69cf4520240945462c5afa`. Both `commandsReaped` and `ownedScratchRemoved` are true, with no reported problem or signal. Renderer/build limits remained 120/900 seconds, output caps 64 KiB/2 MiB, TERM→KILL grace three seconds and overall job limit 20 minutes.

The [machine receipt](app-icon-build.json) retains the controller's source guards, toolchain results, per-command hashes and compiled-output evidence. Its interpreter executable display is normalized to portable `python3`; actual Python version and all outcomes are preserved. The original 23,148-byte report remains in the canonical job log, SHA-256 `ccf28a6f6034410c7d4d034bfa7eb29d8f389979994c8dcd35463f7138b01154`.

The [earlier 40 core tests/build](../10-27/native-checks.md) remain historical and were not repeated. This closes the [later icon compilation packet](../../../proposals/app-icon-build.md), while preserving [icon source evidence](../10-28/app-icon.md). It does not establish Home Screen/default/dark/clear/tinted appearance, simulator/device behavior, UI/accessibility, persistence, notifications, trusted signing or store distribution. No simulator was booted, app launched, notification prompted, identity/account enrolled, dependency installed or model/provider called. No artifact was uploaded. The final publication updates the README and removes the temporary workflow; its app/core, artwork, renderer and project bytes retain the checked identities. The full delivery goal remains unfinished.
