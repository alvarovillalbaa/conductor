# Startup observer attempt 1 — failed before Xcode

[Run 43332030657](https://github.com/alvarovillalbaa/conductor/actions/runs/43332030657),
job `131578820471`, checked source
`0b9e4055bf3cff679bac438e05e8c7f1c7e009b9` from owned QA commit
`be05bc49282ba254cea373f620b47e7ee50c204c`. The job failed; artifact upload passed.

The newly added filename expression allowed lowercase labels only, while the
existing source guard calls use `beforeSourceGuard-head` and
`afterSourceGuard-head`. The observer raised `stream_filename_invalid` before
recording those rows. No Xcode command, build, Simulator creation, startup probe
or UI case was reached. Neither source guard completed.

The [terminal JSON extracted from the original job log](ui-startup-attempt-1.json)
is 877 bytes, SHA-256
`718d4ffcf08d496fc84f5504648950cfde49d205a66cbddc4bf6118b9ade31bb`.
The [original decoded job log](ui-startup-attempt-1.log) is 19,864 bytes, SHA-256
`ffa04130bae9812cc9684313f9651a414c0916b19d50808a945cbd5ae1c19ab9`.
The JSON says scratch cleanup passed and no Simulator was created. Its empty
`commands` list makes `processesReaped: true` vacuous: it does not provide
individual receipts for the source-guard subprocesses. No missing stdout/stderr
content is reconstructed. GitHub artifact `13994294267` was reported as 643 bytes,
digest `6199aa2065a8c62f4be2e34533398feefe6c6b146eb3bab111cb525c104bd0f8`;
that ZIP is not used as the retained JSON's byte provenance.

The second preparation validates bounded ASCII command labels before spawning,
accepts uppercase, and appends the completed command row before artifact writes.
Static AST parsing and all literal labels plus both dynamic guard prefixes were
checked locally. App/project/package/test source, toolchain, original UI
assertions and deadlines are unchanged. The failed verdict is retained.
