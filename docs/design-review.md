# PETOPIA design review

This review translates the complete 31-section game design document v1.1 into screens, asset sets and review steps. It records the user's current visual direction and separates that direction from earlier generated proposals. The user approved the overall Batch 1 visual direction on 16 October 2026, with an explicit requirement for consistent coins and shared menus.

## Current decisions

| Subject | Direction | Evidence |
|---|---|---|
| Overall visual style | Follow `sources/visual-style-reference.png`: bright, charming, expressive pixel art, colorful worlds, soft rounded characters and layered scenery | User's reattached first image and latest instruction |
| Logo | Follow the PETOPIA logo in `sources/logo-and-worlds-reference.png`; remove the floating heart over the I. Preserve the playful chunky multicolor lettering, paw motif and wood/leaf treatment | User's reattached second image and latest instruction |
| Gameplay identity | Child and pet explore together in a side-scrolling run-and-jump adventure. Care, minigames, cooperation, customization and progression are connected parts of the game | GDD §§1–2, 9–10, 16–20; user's clarification |
| Authority | User decisions govern. GDD defines mechanics, roster and milestones. Supplied images define visual direction where compatible. Generated images are proposals | GDD introduction; user instructions |
| Current activity | Standardize shared UI and create Batch 2 screens within the accepted direction | User approval and consistency requirement |
| Tracking | Separate concept production, design approval, implementation and verification. Bars count completed checklist items; they are not time estimates | User's progress request |
| Workflow | Plain project documentation and dashboard. No Waypoint | Explicit user instruction |

The colorful reference is not a mandate to invent another palette. The accepted V01 character direction uses the GDD's green-jacket meadow explorer and Foxy baby/child forms. Do not silently treat the current procedural prototype as the visual target.

## Differences resolved by the document

| Image content | GDD requirement | Consequence for concepts |
|---|---|---|
| Puppy, penguin, unicorn and other sample pets | Canonical roster: Foxy, Mochi, Bubbles, Ember, Sprout, Frosty, Bolt, Luna, Poppy, Pebble, Sunny, Cloudy (§4) | Keep the image's charm, use the GDD species and personalities |
| Egg followed by four stages | Four living stages: baby, child, teen, adult; egg/adoption is introductory (§§5–6) | Never display egg as a fifth living growth stage |
| Red-shirt sample child | Four proposed explorer identities with identical gameplay (§3) | Review appearance and palette before making animation sheets |
| Repeated enemies, question blocks, boss battle panels | Original cooperation, repair, discovery, rescue and celebration; gentle setbacks (§§1, 9–10) | Preserve run-and-jump readability with original obstacles and pet puzzles |
| Different pets imply required movement abilities | Every starter can finish every main path; pet routes are optional (§10) | Draw main path and alternative route clearly |
| Hunger meter | Internal fullness; child-facing label Food (§7) | Show Food increasing when fed |
| Unspecified evolution pace | Real elapsed days 0, 7, 30, 60; growth does not depend on grinding (§6) | Keep age, needs, bond and training visually distinct |
| Many simultaneous worlds | 1 adventure in Phase 1; 5 levels in Phase 2; 15 in Phase 3; 75 in Phase 4 (§27) | Distinguish vision concepts from available content |

## Screen coverage and generation order

Each screen needs a normal state, meaningful feedback, keyboard focus, touch layout and a clear exit. Screens with coins or progress also need saving/error feedback. Text remains outside final art assets (§§21, 24–26).

| ID | Screen or sheet | Required content and states | Source | Review batch |
|---|---|---|---|---|
| V01 | Explorer and Foxy direction | Front/side proportions, expression studies, scale, equipment anchors; Foxy baby and child are visually distinct, with idle/run/jump/ability/care poses | §§3, 5, 25–26 | 1 |
| V02 | The Lost Picnic gameplay | True 2D side view; child and Foxy, three adventure hearts, coins, goal, movement/jump/interact/ability, crank bridge, checkpoint, secret, basket and visible fallback route | §§9–10, 16, 21 | 1 |
| V03 | My Pet room | One room; bowl, bed, wash area, toy; expressive wandering pet; care toolbar, coins, details, travel and free recovery at zero coins | §§7–8, 19, 21 | 1 |
| V04 | Main menu and correct logo | Play/Continue, My Pet, Adventures, Collection, Settings; welcoming animated child and pet scene; first-run and continuing states | §21; user logo reference | 2 |
| V05 | Adoption | Foxy portrait, editable/default name, confirm, greeting and Back; only Foxy available in slice | §§2–4, 21 | 2 |
| V06 | Pet details and growth | Five needs and bond, age/stage, preferences, growth eligibility and celebration; real-time age separate from XP | §§5–8, 21 | 2 |
| V07 | World map and level selection | Colorful world navigation, five nodes per world, selected companion, completion/secret records, locked reason, Start and Home; only actual slice level enabled | §§11–16, 20–21 | 2 |
| V08 | Pause and settings | Resume/Home, volume categories, controls, reduced motion, readable text, adjustable timing; timers frozen | §§17, 21, 26 | 2 |
| V09 | Adventure results and memories | Shared picnic celebration, coins earned, sticker, unique discovery, replay and Home; distinct already-claimed state | §§16, 18, 20–21 | 2 |
| V10 | Minigame hub and Catch the Ball | One complete activity initially; practice, ten throws, broad catch zone, success/miss, pause, results, replay and Home | §17 | 3 |
| V11 | Shop and inventory | Preview, price, affordable/unaffordable, Buy, ownership, equip/use, transaction feedback and clear exit | §§18, 21, 24 | 3 |
| V12 | Decorate and cosmetics | Explicit mode, placement ghost, valid/invalid, confirm/cancel, remove to inventory; reachable bed/bowl/wash/travel | §19 | 3 |
| V13 | Collection, quests and achievements | Owned pets/stages, silhouettes, known unlock requirements, counters, complete versus claimed states; no streak loss | §§4, 20–21 | 4 |
| V14 | Starter expansion sheet | Foxy, Ember and Bubbles, all four living stages, distinct behavior and ability targets; production poses and equipment fit | §§4–6, 8, 25–27 | 4 |
| V15 | Minigame expansion | Memory Cards and Cooking Challenge for Phase 2; Fruit Match, Pet Racing, Fishing for Phase 3; Rhythm Time and Treasure Hunt later | §17 | 4 |
| V16 | World environment atlas | All 15 canonical worlds, different palettes/mechanics/landmarks, side-scrolling layouts; full first-three kits prioritized | §§11–15, 25 | 4 |
| V17 | Remaining roster concepts | Mochi, Sprout, Frosty, Bolt, Luna, Poppy, Pebble, Sunny, Cloudy; personalities, preferences, abilities, silhouettes and growth direction | §§4–5 | 4 |

Batch 1 establishes the character, platform adventure and home together in the supplied style. Review these connected screens before producing the remaining menus. Approval applies only to the specific design shown; it does not imply playable content or approval of the entire catalogue.

## The Lost Picnic visual beats

1. Arrival clearing: resident and basket goal are recognizable without a paragraph.
2. Flower trail: walking, jumping a low log and initial coins on safe ground.
3. Stream: visible child-operated crank aligns stepping planks; checkpoint nearby.
4. Discovery: Foxy's ears and sparkle cue soft ground; ability reveals a shorter trail and optional keepsake.
5. Basket hollow: longer visible main path still reaches the basket.
6. Return shortcut: gate opens from the far side; basket objective cannot be lost.
7. Picnic: shared celebration, one committed reward and a clear Home action.

## Environment coverage

| World | Distinguishing visual and mechanic |
|---|---|
| Green Meadows | Warm hills, wildflowers, windmill, shallow stream; movement and discovery |
| Sunny Beach | Bright shallows, shells, pontoons, lighthouse; swimming and floating objects |
| Mystic Forest | Layered foliage, luminous flowers, clearings; plant and hidden-path puzzles |
| Crystal Caves | Visible dark floors, reflective stones, luminous pools; light/prism symbols |
| Snowy Peaks | Soft snow, ice and warm shelters; clear braking areas |
| Lava Volcano | Amber rocks, warm machinery, glowing channels; readable heat cycles |
| Sky Islands | Floating gardens, ribbons, clouds; wind and generous landing surfaces |
| Desert Ruins | Sandstone, shaded mosaics, oasis; symbols and switches |
| Dreamland | Pastel storybook shapes and cushions; telegraphed layout changes |
| Haunted Manor | Warm windows, friendly ghosts; light puzzles without scares |
| Robot Factory | Rounded gears, toy machines, conveyor arrows; mechanical puzzles |
| Rainforest | Broad leaves, waterfalls, roots; readable vines and swinging |
| Candy Land | Invented sweets and patterned materials; bounce and sticky surfaces |
| Underwater World | Coral, currents, glowing ruins; unlimited-breathing exploration bubble |
| Sky Castle | Welcoming cloud castle; familiar mechanics and final celebration |

## Asset production after design approval

Concept sheets are not game-ready spritesheets. The slice needs one child and Foxy baby/child with consistent frame canvases, feet/hand anchors, equipment offsets and actual used animations; one modular meadow kit; a room kit; UI components; effects; music and sound. The full roster implies 48 living-stage sets and up to 576 core clips before costumes (§§25–26). Approve proportions, palette and representative cycles before multiplying assets.

Use the proposed 640×360 world, 16×16 terrain and 32–48px child as testable starting values, not visually approved facts. UI must remain readable, touch targets at least 48 logical pixels, and essential clues work without sound or color alone. Export sprites with transparent backgrounds and metadata; never crop a concept board and label it a finished asset pack.

## Current limitations

Early generated boards are unapproved; the broad logo/menu direction was rejected, and the two-palette exercise was superseded by the user's explicit source-image direction. The earlier Phase 1 board was liked in part but judged insufficient and its logo rejected. The current Batch 1 proposals are V01 characters v1, V02 adventure v4 and V03 home v5. The home screen uses a simple My Pet title; the main-menu logo remains a separate review item following the supplied second reference without its floating heart.

Prototype code uses original procedural placeholders. It passes 47 system checks and 20 automated scene checks on Godot 4.7.2, recorded in `verification.json`. This does not pass the complete Phase 1 acceptance matrix. No platform exports, child playtests, approved animation sheets or final audio exist yet.


## Approval update 16 October 2026

The user approved the overall Batch 1 direction and authorized continuing, while requiring consistent coins and menus. This supersedes earlier pending-direction statements in the review history. Shared controls are specified in `ui-design-system.json` and `ui-consistency.md`. New layouts and production assets still require review; do not treat this as acceptance of unfinished implementation.


## Shared UI and Batch 2 production

`UI-shared-components-v1.png` defines one coin/counter treatment, cream-and-wood panels, navy rounded type, gold primary actions, blue focus states, navigation icons and six meter mappings. V02 and V03 received interface-only consistency revisions. V04–V09 now have full-size layout proposals derived from the same sheet. New layouts remain awaiting review. The canonical RGBA coin is reused by the prototype's home badge, adventure run badge and world pickups, with a resource-identity check in the automated scene suite. Generation prompts are retained in `concept-prompts-batch-2.json`.
