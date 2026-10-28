# Proposed app-icon compilation check

Status: awaiting explicit approval. The [workflow example](app-icon-build-ci.yml.example)
is inactive. The previous native-check approval covered one dispatch, which
[already completed](../results/2026/10-27/native-checks.md); this is a new run
for the later [icon resource addition](../results/2026/10-28/app-icon.md).

After approval, install the example as
`.github/workflows/app-icon-build.yml`, publish and dispatch once on main.
Use one standard public `macos-15` GitHub runner with a 20-minute timeout,
read-only repository token, shallow checkout and no persisted Git credentials.
Record the exact source/toolchain, compare the PNG with its editable SVG,
check project/resource metadata, and build the generic iOS Simulator target
with `CODE_SIGNING_ALLOWED=NO`. Record the actual asset-compiler/build outcome.
Remove the temporary workflow after terminal execution and publish a result
receipt. A failed run is not authority to alter checks, dependencies or plans.

The core/app code and tests are unchanged; the 40 core tests are not repeated
for this resource-only addition. No simulator boot, app launch, UI automation,
notification prompt/delivery, user data, account, signing identity, store
submission, model/provider call, external dependency install, cache, artifact
upload, larger runner or billing change is proposed. Temporary DerivedData
belongs only to the runner. Local builds remain subject to Storage Guard.

Success would prove unsigned target and asset-catalog compilation at the
recorded source. Home Screen/default/dark/clear/tinted appearance, accessibility,
real app behavior, screenshots, physical-device signing and distribution would
still require their own acceptance steps.
