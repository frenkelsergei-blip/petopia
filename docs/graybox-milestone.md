# Playable graybox milestone

The 16 October 2026 build follows GDD §27's Phase 1 implementation order using capsule stand-ins and gray terrain, as requested. It is a mechanics sandbox rather than a final-art slice. The accepted concept images remain the eventual visual target.

## Start playing

Double-click **Play Petopia.command** in the project folder, or import `project.godot` into Godot 4.7.2 and press **F5**. The installed macOS Godot runtime is used; this is not a signed standalone export.

The sandbox hub offers four activity entries (including two adventures):

| Activity | What works |
|---|---|
| Movement lab | Immediate play without adoption; blue player capsule and orange pet; low obstacles, a generous 56px gap, steps, bridge crank, checkpoint, sensing and finish marker; six course goals and live diagnostics |
| Adventures · The Lost Picnic | Adopt/name Foxy first; movement, collected coin IDs, child-operated bridge, checkpoint, gentle fall recovery, optional cache and raised overlook, basket marker, return gate, picnic result, replay, saved coins and one usable meal |
| Adventures · Windmill Walk | W01 L02 early mechanics preview: hill/step jumps, slow platforms, upper coin trail, broad lower route, three food bags, two checkpoints, requested pet dig opening a lift/bridge and saved food/coin delivery |
| Pet home | Free feed, clean, pet, water and rest; five need meters and bond; capsule reactions; basic growth labels/sizes; shop and owned toy placement preview/confirm/cancel/remove |
| Catch the Ball | Practice plus ten throws, visible child-controlled throw, wide gold aim band, automatic pet chase/catch/return, friendly misses, pause, results and idempotent happiness/bond rewards |

The lab's sample coins never enter the wallet. Normal Lost Picnic runs award the document's 50 completion coins, up to 20 pickups and the first discovery's unique 10 coins. The 100-coin toy normally takes two outings; the sandbox does not silently grant spending money. Free essential care remains available at zero coins.

## Controls

| Input | Action |
|---|---|
| A/D or arrows | Move |
| Space | Jump; throw during the ball game |
| E | Interact with crank, basket, gate or picnic; throw in ball game |
| Q | Ask Foxy to find/dig near marked ground |
| R | Return to current checkpoint |
| F | Recall companion to validated safe ground |
| Escape | Pause/resume |
| Tab | Pet details from the hub/home after adoption |

On-screen controls support independent fingers and desktop pointer clicks. Mouse/touch releases, pausing and focus loss clear held actions. Controller bindings exist but have not been checked on a physical controller.

In the lab, **Block / unblock pet** creates a small enclosure around the companion. Walk onward to observe automatic recovery after about two seconds without horizontal progress. It tests the real recovery path rather than awarding fake progress. **Restart lab** resets only the reward-free course; R uses its current checkpoint.

## Structure and state

`Main` composes `AppServices/GameState`, a 640×360 world viewport and a separate 1280×720 reference UI. `MovementLab`, `TheLostPicnic`, `WindmillWalk`, `PetHome` and `CatchTheBall` are independent world scenes. `Explorer` and `Companion` use `CharacterBody2D` and capsule collision shapes; `GrayboxActor` supplies replaceable rendering.

Level layouts are typed `LevelDefinition` Resources under `data/levels/`. They contain terrain, pickup positions, authored companion jump links and safe anchors. Recovery tests both clear body space and ground support before placing the pet. Item Resources under `data/items/` supply shared shop/service prices, categories and descriptions.

The graybox uses `user://graybox_v1/`. The older `user://profile/` stays intact. Automated tests and rendered captures use separate profile directories. Saves retain schema/revision, backup snapshots, reward IDs, room layout and current run. UTC plus a session high-water mark supports clock rollback and one-time background reconciliation; real-time age is separate from capped need decay.

## Verification

Run `python3 tools/run_checks.py`. The wrapper rejects engine script errors even when Godot exits with code zero. Three suites exercise system rules, scene transitions and actual continuous-input routes, including simulated two-finger input and a deliberately blocked companion. Results and logs are saved in `test-results/`; durable milestone evidence is in `docs/verification.json`.

Own-project rendered screenshots are under `docs/screenshots/`. They show actual running scenes, not generated concept art. After the Mac was unlocked, native click-through verified running, obstacle/gap jumps, coin/course feedback, fall reset, companion recovery, pause/resume and hub navigation. An enclosure that could trap an overlapping player was corrected to use companion-only collisions; a regression check verifies escape. Eight automated suites now pass 225 checks, including both Windmill routes, a real moving-platform rider, automatic fetch, food use and room preview/commit. Physical touch/controller testing and child playtesting remain outstanding.

## Remaining work

The Lost Picnic graybox is about six screens wide and shorter than the proposed final 12–18-screen, 5–8-minute adventure. There are two graybox levels and one minigame; Windmill Walk is an early Phase 2 preview rather than a completed Phase 2 gate. Bathing is a simple free action, not the full soap/rinse/swipe sequence. Growth uses labels and capsule proportions, not approved animated pet art. Final audio, full accessibility settings, localization, remaining worlds/pets, save-schema migration fixtures and platform export/signing are unfinished. These remain visible in the main phase tracker.

Next, play the graybox and tune movement, companion behavior, goal readability and care interactions before replacing capsules with the accepted art.

## Follow-up design decisions

The user clarified that the child throws and the pet catches. This supersedes the GDD §17 catch-input wording while keeping its practice, ten-throw structure, broad timing and participation rewards. No input controls the pet in fetch.

GDD §§9–11 require a cooperative moment, an accessible main route and an exploration level named Windmill Walk with slow platforms and a pet-marked cache. The implemented layout, food bags and buried switch are concrete graybox proposals. Foxy must reach the marked ground and dig before the shortcut geometry appears. A longer jumping route works without the ability.

Adventure supplies connect play to home care: one meal for picnic completion; two for Windmill delivery and one extra for the first Windmill cache. Meals are the existing Berry bowl inventory item and can be consumed from the shop. These amounts need playtesting. Rewards publish with completion once; switching between levels archives/restores unfinished runs rather than discarding them.

Routine pickups and checkpoints now save through a single background writer with a bounded latest-state queue. Purchases, rewards and normal shutdown stay ordered and durable. Camera/physics interpolation addresses motion jitter. See [the performance investigation](performance.md) for the local before/after sample and slow-disk tests.

The same build now includes an Art pilot/Graybox renderer switch and the B-key reusable crate bag. See `art-pilot.md`, `trail-tools.md` and amendments A05–A08. The chosen high ledge is physically reachable with three tested crate-step jumps; broader route/animation/playtest gates remain open.

## Portrait mobile iteration

Mobile-first portrait is now the default play layout (A09). Use left movement and right Jump/Use/Foxy simultaneously, Bag for tools and Reset for recovery. Pause → Touch controls saves size, spacing and vertical position. Menus scroll; the independent adventure camera adapts to screen ratio without stretching sprites or restarting the current run. Thirty-four mobile checks and eleven actual portrait renders supplement the existing mechanics evidence. Physical Android/iOS exports, lifecycle, keyboard, performance and child touch-reach checks remain pending; see `mobile-layout.md`.
