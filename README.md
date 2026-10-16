# PETOPIA

An original pixel-art pet and side-scrolling adventure game for ages 5–12, following the supplied game design document v1.1.

**The mechanics build is playable; production art remains under review.** V2, localized v3 and first thin-grass v4 were rejected. Revised v4.1 addresses continuous surfaces, source detail, locomotion, grounded shadows and crank/river contact; no visual gate is approved. Switch **Visuals: Art pilot / Graybox** on the hub or in Pause to compare rendering on the same mechanics. Full production animations and remaining art are unfinished.

## Play

Phone/browser build: **[PETOPIA](https://petopia-dqi.pages.dev/)** · version **0.1.0** (prototype prerelease). Tap Start, adopt Foxy, then use the round stick to move and Jump / Use / Find with the other finger. Browser progress stays on that device. Versioned publishing and rollback: [release process](docs/releases.md).


Double-click **Play Petopia.command** in this folder. It uses the installed Godot **4.7.2** runtime. Or import `project.godot` into Godot and press **F5**.

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/sfrenkel/Petopia
```

For the current focused playable review, double-click **Play Art Review.command**. It opens directly at the crank in a separate reward-free profile, with portrait touch controls. Press **Use / E** to open the bridge, then move and jump. Original personal progress stays separate.

The hub offers four activities:

- **Movement lab:** play immediately without adoption; six goals test running, jumping, a gap, bridge interaction, companion sensing and reaching the finish. Use the pet enclosure button to test automatic recovery.
- **Adventures:** The Lost Picnic is the gentle introduction. **Windmill Walk** adds hill jumps, slow platforms, three food bags and a pet-assisted shortcut. Both award coins and usable food; unfinished progress saves separately. Level two is an early Phase 2 graybox preview.
- **Pet home:** free care, needs/bond and real-time growth; shop purchases and owned toy placement.
- **Catch the Ball:** you control the visible child and throw with Space/E when the aim marker is in the gold band. Foxy chases, catches and returns automatically. Practice plus ten throws awards happiness/bond.

A/D or arrows move; **Space** jumps/throws; **E** interacts/throws; **Q** asks Foxy to find or dig; **R** returns to the checkpoint; **F** recalls the companion; **Escape** pauses. On-screen controls support separate simultaneous fingers and desktop pointer clicks. Controller bindings are present; physical device tests remain pending.

The development save is `user://graybox_v1/`. Older `user://profile/` data stays intact. Lab samples do not enter the wallet. Tests and captures use separate profiles.

See [the graybox guide](docs/graybox-milestone.md) for document mapping, controls, persistence and limitations. The current picnic is a shorter six-screen test route; full bathing, final art/audio, accessibility completion, migration fixtures and physical-device testing remain unfinished.

## Progress and design

Open `docs/progress.html` for a separate graybox checklist, phase progress bars, current/next work, actual screenshots and accepted concepts. `docs/progress.json` is its source; regenerate with `python3 tools/build_progress.py`.

- `docs/design-review.md` maps all 31 GDD sections to visual requirements and review batches.
- `docs/ui-design-system.json` and `docs/ui-consistency.md` define shared coins, buttons, icons, panels, colors and navigation.
- `assets/ui/coin-gold-v1.png` is the same texture used for wallet counters and world pickups.
- `assets/concepts/` contains visual proposals; `docs/screenshots/` contains actual running graybox scenes.
- `docs/sources/` retains the original document, extracted text and supplied references.

Phase bars count completed document outcomes. A playable graybox does not complete the final-art Phase 1 gate.

## Verification

```bash
python3 tools/run_checks.py
```

**415 checks pass across12 suites**, including native ordered slow-disk saves, duplicate rewards, shutdown, scene routes, mobile multitouch/controller ownership, menu/adoption, four-stage room growth and the browser idle writer. Logs are under `test-results/`; scope and remaining checks are in `docs/verification.json`.

Actual scene captures run through `tools/capture_graybox.gd`. Automated checks and renders do not replace manual, physical-device or child playtests. Native macOS checks verified sampled lab mechanics, companion recovery, pause/resume and hub navigation. A player-trapping bug in the pet enclosure was fixed with a companion-only collision layer and a regression check.

## Structure

`Main` composes `AppServices/GameState`, an independent world viewport and separate responsive UI. Portrait uses a 390px logical reference with a camera that adapts to the available play area; landscape desktop keeps the 1280×720 presentation. `PortraitInterface` presents the same authoritative actions and live state as the desktop UI. `MovementLab`, `TheLostPicnic`, `WindmillWalk`, `PetHome` and `CatchTheBall` are independent scenes. `Explorer` and `Companion` use capsule collision shapes and replaceable `GrayboxActor` rendering. Typed level Resources live under `data/levels/`; shared item definitions under `data/items/`. Pure rules and snapshot persistence are separated from UI. There are no autoloads.

## Document phases

1. One child, Foxy baby/child, one room, care, Catch the Ball, The Lost Picnic, economy, toy and reliable saves.
2. Three starter pets, four stages, three minigames and five Green Meadows levels, quests and customization.
3. Six pets, three worlds, fifteen levels, six minigames and completed mobile controls.
4. Twelve pets, fifteen worlds, seventy-five levels and further rooms/mechanics.

These are outcome gates, not promised dates. The dashboard records completed work and remaining acceptance criteria.

## Current cooperation rules

Treasure Sense means **asking Foxy to find buried objects**. Approach marked ground and press Q / Find. A clue connects Foxy to the target; a digging gesture and a changed object show the result. In Windmill Walk, Foxy approaches and digs up a switch that starts a bonus lift and spans the last gap. The longer main path remains traversable without this ability.

The picnic awards one meal; Windmill delivery awards two, plus one for its first hidden cache. These are provisional graybox reward values. At home, open Shop and choose **Use** on an owned Berry bowl to feed the pet. The owned Sunshine ball has **Place**: choose a spot, inspect the translucent ghost and confirm. Cancel leaves the room unchanged; removing returns the item to the bag. Foxy approaches and nudges a placed ball. Shop, room and fetch reuse the same item drawing.

See [the performance investigation](docs/performance.md): a local headed sample reduced the worst observed frame from 567 ms to 23 ms after moving routine saves off the gameplay thread. The comparison is a single-machine sample; final-art and device profiling remain pending.

## Working design record

See [design amendments and open feedback](docs/design-amendments.md) and the [workspace change log](docs/change-log.md). These distinguish user direction, provisional mechanics, implemented behavior and remaining verification. The original GDD is preserved.

## Adventure tools and runtime art

Find the crate bundle along Windmill Walk’s lower trail and press **E**. **B** opens the adventure bag. Place reusable crates freely where they help you; there are no prescribed numbered building spots. **Pack all placed crates** returns them for reuse in either adventure. The direct-jump and crate-step routes, ownership, packing and cross-level reuse are verified. Current crate limits are provisional.

See [the tool guide](docs/trail-tools.md) and [art pilot notes](docs/art-pilot.md). Exact generation prompts, original PNGs, atlas metadata and provenance are saved in the project. The first art frame sample had a 23.34 ms worst observed frame on this machine; remaining intermittent glitches and broader device/long-session testing stay open.

## Mobile-first portrait

Launch defaults to a 390×844 portrait window. Use the round movement stick with one finger and Jump / Use / Find with the other; Bag opens tools and Reset returns to the checkpoint. **Pause → Touch controls** saves button size, spacing and vertical position. Home care and menus scroll when needed. Keyboard controls remain active; resizing to a wide desktop window preserves the current level. See [mobile layout and remaining device checks](docs/mobile-layout.md). A Web build runs in the phone browser; native Android/iOS packaging and physical device certification remain pending.

## Runtime art rejected

The user rejected v2, including character detail, terrain silhouettes, water/bridge integration and scene depth. The garden setting is relatively improved but not accepted. The concepts define quality, identity and style; new playable layouts do not need to duplicate them.

See [the rejected comparison](docs/art-review.html), [rejection audit](docs/art-rejection-audit.md) and [production inventory](docs/art-production-matrix.md). Mechanics tests do not establish visual approval. No replacement playable art result is declared complete.
