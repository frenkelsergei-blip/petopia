# Graybox smoothness follow-up

The 16 October 2026 report of sticking/stuttering was investigated before adding final artwork.

## Reproduced cause

Routine pickups, checkpoints and the 30-second autosave wrote, flushed, verified and backed up the full save on the gameplay thread. In a headed Godot run on the local Apple M4 Pro, one write took 562 ms; the corresponding worst observed frame was 567 ms. The level had only graybox art. Twelve repeated home/adventure scene changes kept the node count at 90, so this sample did not show scene-object accumulation.

## Change

Routine progress now uses one background writer plus at most one newest waiting snapshot. A burst replaces the waiting snapshot with the full latest state; it cannot stack an unbounded queue. The worker receives an independent dictionary and only accesses persistence, never scene nodes. GameState polls completion on the main thread, reports failure and retains a retry snapshot.

Purchases, rewards, explicit saves and shutdown remain ordered behind the writer. Purchases publish only after their complete transaction is durable. Closing normally joins the writer and saves the latest pending state. An abrupt process termination can lose a just-collected pickup that has not finished writing; previously durable purchases and rewards remain protected by the snapshot/backup protocol.

Physics interpolation is enabled. A shared camera follows after character physics without rounding its target to whole pixels. Checkpoint/companion recovery resets interpolation to prevent a sweep across the level. Moving-platform drawings are attached to their physics bodies so visuals and collision move together. Idle-driven home and fetch visuals opt out of physics interpolation.

## Local comparison

The same headed Windmill sample used an isolated save, a 120 FPS cap, 1,569 post-warmup frame intervals, pickup saves, an autosave and twelve scene changes. These are single-machine samples, not device certification or a guarantee that every source of jitter has been eliminated.

| Wall-clock frame measure | Before | After |
|---|---:|---:|
| Mean | 8.94 ms | 8.64 ms |
| 95th percentile | 14.86 ms | 15.34 ms |
| 99th percentile | 16.55 ms | 17.00 ms |
| Worst observed | 566.81 ms | 23.15 ms |
| Frames over 25 ms | 4 | 0 |
| Nodes after each of twelve scene cycles | 90 | 90 |

The improvement is removal of large outliers; normal frame percentiles are similar. Raw reports: `test-results/performance-before.json` and `test-results/performance-after.json`. Reproduce a new sample with:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/sfrenkel/Petopia --script res://tools/profile_gameplay.gd -- new-sample
```

The profiler's process/physics monitors are Godot's periodically refreshed counters. Use its directly sampled `frame_ms` field for the frame comparison above.

## Verification

All 146 checks pass across five suites. The 16 smoothness checks introduce a deliberate 180 ms write delay and verify live movement, bounded coalescing, latest-state persistence, purchase ordering/idempotency, failed-write recovery, shutdown joining and camera reset. Existing adventure, cooperation, care and economy checks also pass.

The next graphics batch should preserve this harness: integrate the approved child/Foxy animation and meadow kit in small parts, then compare the same movement sample with real art. Keep the capsule rendering available for mechanics diagnosis. Physical devices, longer sessions and child playtests remain outstanding.

## First runtime art follow-up

`test-results/performance-art-pilot.json` repeats the headed sample with the generated explorer/Foxy sprites, terrain, foliage and panorama. It records 1,569 post-warmup frame intervals: mean 8.52 ms, p95 14.68 ms, p99 16.92 ms, worst 23.34 ms and zero above 25 ms. Twelve scene cycles keep 94 nodes, including new sprite/tool/UI nodes. This single-machine sample supports continuing the visual pilot; it does not close the user’s intermittent-glitch report or certify long sessions/devices.

## Portrait layout sample

`test-results/performance-portrait.json` samples the 390×844 portrait window with art enabled after the prior game was closed and automated suites completed. Across 1,569 post-warmup frames: mean 8.68 ms, p99 17.59 ms, worst 19.12 ms, zero above 25 ms. Twelve home/adventure cycles retain 135 nodes. The initial concurrent run is retained separately in `performance-portrait-concurrent.json`; its overlap with other checks is not an unloaded comparison. Phone frame time, long-session behavior and the broader intermittent-glitch report remain open.

## Concept-fidelity art revision

The clean portrait sample in `test-results/performance-concept-fidelity.json` uses the larger hero camera, organic terrain and revised art after other game/check/encoding work was closed. Across 1,569 post-warmup frames: mean 8.46 ms, p99 17.12 ms, worst 38.19 ms and two frames above 25 ms. Twelve scene cycles stay at 135 nodes. The earlier overlapping run is retained as `performance-concept-fidelity-concurrent.json`. Keep the intermittent-glitch report and physical-device performance gate open; this sample is not a zero-stutter claim.

## v4.1 portrait rendering sample · 16 October

`test-results/performance-world-rebuild.json`: 1569 wall frames, mean8.52ms, p9917.39ms, worst58.90ms, three frames above25ms. Twelve scene cycles remain at123nodes. This sample used isolated save data, but existing game/editor and background processes remained running; capture/encoding and automated suites had finished. It is not a clean hardware-isolation comparison or mobile-device certification. Godot process monitor includes stale startup peaks; wall timing is primary. Intermittent-glitch feedback remains open.


## Interaction/story follow-up · 16 October

`test-results/performance-interaction-story.json`, captured with `tools/profile_gameplay.gd -- interaction-story`: headed390×844, cap120, 1,569 measured frames after warmup, mean8.463ms, p9916.705ms, worst24.801ms, zero >25ms. Twelve scene cycles held126nodes. Captures and automated suites had completed; the existing game/editor and unrelated desktop background load remained. This is one Mac sample, not a phone guarantee or proof that intermittent stutter is fully resolved. Wall-frame measurements are primary; process monitor values can retain startup peaks.

`test-results/parallax-clock.json` checks deliberately exaggerated10Hz physics/120Hz render origins. The background now uses the interpolated canvas transform instead of physics camera ticks. This addresses scrolling consistency independently of total FPS. `motion-before-focus.json` and `motion-after-focus.json` are retained diagnostics; the latter overlapped a separate experiment renderer and does not establish a speedup.


## Water contact foam · 16 October

`performance-water-foam.json`: headed390×844,120FPS cap,1,569 measured wall frames after warmup;mean8.578ms,p9917.335ms,worst22.318ms,zero>25ms.126 nodes remain stable over12 scene cycles. Average draw calls approximately163. Captures/checks had finished; existing editor/game/background load remained. One Mac sample, no speedup or phone certification claim.
