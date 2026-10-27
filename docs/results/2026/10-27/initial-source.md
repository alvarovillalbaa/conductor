# Conductor initial source implementation

27 October 2026. Status: source implementation complete; native checks and
publication are not yet verified. The all-project goal is active.

## Source intent

The [parent project page](https://app.notion.com/p/311a1ee8bd06805caa21c5306dd315ac)
contains “(ios) Conductor — coordinar tareas que deben terminar a la vez”. A
fresh scoped search found only that parent entry. The parent fetch reports
truncation/three unknown blocks elsewhere, so no complete all-project audit is
claimed. The local-first iOS 17 workflow is an implementation choice from this
one-line brief; see [product scope](../../../specs/product.md).

Personal repository search for `conductor` returned no match and the local
destination did not exist. SIDE is not a Git repository. A separate `main`
checkout was initialized without changing another app's worktree.

## Intended implementation

Foundation core owns backward scheduling, frozen run snapshots, explicit task
transitions, complete validation and a bounded JSON codec. The app owns SwiftUI
forms/timeline, atomic local persistence, raw recovery/export and optional native
notifications. Creating a run does not claim physical work has begun; timer zero
never claims completion. The shared deadline stays fixed when a task is late.

Candidate state is intended to save before UI success/reminder reconciliation.
Failed/unread data must remain recoverable. Notification request IDs and
generation guards must fence late permission/scheduling work. These contracts
have not been established by native execution yet.

## Execution boundary

Storage Guard reported **28.7 GiB free / 38.0 GiB required**, exit 2, for the estimated
iOS build workload. `xcode-select -p` reports Command Line Tools. No native build,
test, simulator boot, app launch, notification authorization/delivery, signing,
store submission, dependency install, model call or paid enrollment ran.

The [native-check proposal](../../../proposals/native-checks.md) remains inactive
pending explicit approval. This local app needs no Vercel/Supabase deployment or
Expo account. Apple ownership and physical/store distribution remain separate.

## Source checks

All 25 Swift files passed individual `swiftc -frontend -parse` checks. This is
syntax checking, not type checking or compilation. The 40 authored in-memory
XCTest cases remain unrun. An independent source review covered the core,
storage/recovery/export, reminder lifecycle and native project wiring.

Static metadata checks passed: 17 app files appear exactly once in the Xcode
Sources phase; the local ConductorCore package link, shared scheme target,
privacy resource and Info.plist build setting agree. All three property lists,
the native helper's shell syntax, environment action and inactive workflow YAML
with its four shell blocks passed. All 41 owned text files passed newline and
trailing-whitespace checks; eight local Markdown links resolve. No active
workflow is installed. `git diff --check` passed.

Source publication will be recorded after GitHub readback. No all-project
completion is claimed.
