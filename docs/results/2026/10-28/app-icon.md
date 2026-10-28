# App-icon source

28 October 2026. Original icon artwork and asset-catalog registration are
published as source. This does not establish a native release.

The artwork uses three staggered white duration bars with a shared right edge
beside a gold finish marker, on an indigo background consistent with the app's
tint. The [editable SVG](../../../../artwork/app-icon.svg) contains simple solid
rectangles. The [standard-library renderer](../../../../script/render_app_icon.py)
exports an opaque, full-square 1024 by 1024 RGB PNG with sRGB metadata and
antialiased foreground edges. It adds no text, pre-rounded outer corners,
external image, dependency or model call. The SVG is the source of truth.

The asset catalog declares the single iOS universal size. Xcode's Resources
phase includes the catalog, and the Debug/Release target configurations select
`AppIcon`. Signing/team/bundle identifiers, app/core code, tests, native-check
scripts and CI configuration remain unchanged.

Apple's [asset-catalog guide](https://developer.apple.com/documentation/xcode/configuring-your-app-icon)
supports a single 1024-square iOS/iPadOS image and automatic appearance variants.
The current [app-icon HIG](https://developer.apple.com/design/human-interface-guidelines/app-icons)
also accepts flattened artwork and requires unmasked square source edges.
Both primary documents were read through their linked Markdown representations.
No Icon Composer migration or toolchain upgrade is implied by this source step.

## Checks and limits

- Renderer export and `--check` agree. PNG structure/CRC, decompressed pixel
  dimensions, RGB/no-transparency format, sRGB metadata and representative solid
  colors were inspected independently. `sips` reports 1024 by 1024, RGB, no alpha.
- SVG dimensions and supported geometry, catalog JSON/file references, Xcode
  resource/target references, unchanged pre-existing project settings and local
  documentation links were checked. `plutil -lint` and `git diff --check` pass.
- The exported PNG was viewed directly: the three broad bars and common finish
  marker are distinct, with square full-bleed outer edges. This is an artwork
  inspection, not iOS Home Screen or appearance-variant acceptance.

No install, compile, app/core test, simulator boot, app launch, notification
prompt, signing, screenshot capture, CI dispatch or store action ran. The earlier
[40 core tests and unsigned build](../10-27/native-checks.md) predate this resource
change. They do not prove icon compilation or current target-build acceptance.
Native asset compilation and rendered default/dark/clear/tinted appearances
remain unverified. App Store screenshots require a real approved app run;
distribution, owner accounts and store metadata remain separate work.

The inactive [app-icon build proposal](../../../proposals/app-icon-build.md)
prepares one unsigned compilation run for explicit approval. It adds no active
workflow and does not repeat the unchanged core tests.

## Publication

Source [`42a483e1fd7407ad2df92c069dea44acac343fe0`](https://github.com/alvarovillalbaa/conductor/commit/42a483e1fd7407ad2df92c069dea44acac343fe0)
was pushed to personal-repository main. Immutable GitHub reads match the local
project blob (`c3878dc26d148184381a544ffe84ceb53794ea7f`), PNG blob
(`20f8dd18e4cf75a0fe00efe56e60b3817dd7b6f7`) and build-proposal blob
(`2baf351d11c40fbc4f79beb95fdc144cde03d5c3`). The later receipt-only commit
does not change artwork, project, app/core/tests or CI. No active workflow is
present. The new compilation approval remains pending; the initial approval
does not authorize a second dispatch.
