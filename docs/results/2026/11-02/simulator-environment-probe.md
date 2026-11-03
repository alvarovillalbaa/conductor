# Simulator environment probe — three profiles passed

The [same metadata-only run 41417969431](https://github.com/alvarovillalbaa/conductor/actions/runs/41417969431) passed on **2 November 2026**. This receipt was observed and authored on **3 November**; no new run or UI retry was started. [JSON receipt](simulator-environment-probe.json) retains the complete controller report, subprocess hashes and independent run/job metadata.

- Published workflow source: [`e38366c1ed51ad1044f9d06283d069b1436b331f`](https://github.com/alvarovillalbaa/conductor/tree/e38366c1ed51ad1044f9d06283d069b1436b331f), tree `25261136b42e4f194a0c0e82d5ef7207e5791efd`.
- [Metadata job 125186350962](https://github.com/alvarovillalbaa/conductor/actions/runs/41417969431/job/125186350962), attempt 1, push/main; actual job **2026-11-02T09:11:58Z–2026-11-02T09:12:48Z**, conclusion **success**.
- [Workflow](https://github.com/alvarovillalbaa/conductor/blob/e38366c1ed51ad1044f9d06283d069b1436b331f/.github/workflows/simulator-environment-probe.yml) SHA-256 `1de2557e0c43e6985a6f69445833a7e3d7165a567881bd36e9f15bc5ed815624` (15,477 bytes). No checkout or app-source execution occurred.

The public `macos-15` runner reported macOS **15.8.2 (24H232)**, image `macos-15-arm64 /20261028.0489.1`. Exact **Xcode 16.4 (16F6)** and **iOS Simulator SDK 18.5** checks passed. Python's version was not printed. Controller execution was **2026-11-02T09:12:08.704465+00:00–09:12:35.422704+00:00**, **26,705 ms**.

The three fixed runtime-list queries used the UI controller's same minimal child environment. Only the middle query's `TMPDIR` changed to a fresh owned directory; the two outer queries used the runner's actual original value. No environment values or private paths were dumped.

| Ordered profile | Elapsed | Exit / stop | Runtime projection |
| --- | ---: | --- | --- |
| Runner-system 1 | 24,072 ms | 0 / none | 16 runtimes; one iOS 18.5, available |
| Fresh owned TMPDIR | 824 ms | 0 / none | 16 runtimes; one iOS 18.5, available |
| Runner-system 2 | 263 ms | 0 / none | 16 runtimes; one iOS 18.5, available |

Each query produced **133,117 stdout bytes** with the same complete-stream SHA-256:
`c559e98279e8529b8b431a5400e4bd4f107ec2dce807d2c701cd8f654e1788b6`.
All stderr streams were empty. All five subprocesses started, exited zero and were reaped; their streams were complete and within caps. No timeout, output stop or interruption was reported. The GitHub controller step succeeded; a separate numeric controller exit was not printed.

The work/query/cleanup limits remained **270/60/30 seconds**, with 1 MiB stdout /64 KiB stderr, dedicated process groups, three-second TERM escalation and three-second post-KILL drain bounds. Overall acceptance required all three valid, available, zero-exit profiles and successful cleanup. The report records **`processesReaped=true`** and **owned-root removal passed**, after nonce/device/inode checks.

The exact compact controller JSON was **4,654 bytes**, SHA-256
`d53c22f1a8c041fa640f043cf5566468d84b8eec810cea5850d8114681414d09`, excluding the log timestamp/prefix/newline. Only the path-free projection and stream fingerprints survive; complete raw runtime metadata was not exported.

The first query was slower than both later queries. **The ordered result does not establish a TMPDIR cause**: the initial successful query may have warmed CoreSimulator services or caches before the middle query. It does not prove independent cold-profile behavior, repeatability or a general system-write sandbox.

No simulator was created, booted, shut down or deleted by this probe; no build, test, runtime installation, app launch, notification, signing, store, provider/model or paid action occurred. Cleanup concerns only this probe's owned temporary root. This does not repair or supersede the [earlier UI attempt 3 failure](ui-acceptance-attempt-3.md) or its failed simulator cleanup, and it supplies **no UI acceptance proof**. The full delivery goal remains unfinished; root owns independent review, the next bounded action and workflow retirement/publication.
