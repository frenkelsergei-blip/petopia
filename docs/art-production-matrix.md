# PETOPIA production art inventory

The accepted visual target is V01–V09 and the shared UI sheet, with the user's repeated V02 gameplay reference taking precedence over generic platform-game examples. The original GDD §§25–26 supplies the animation and kit inventory. A generated image, runtime integration and final visual approval are separate states. No new game theme or replacement logo is approved here.

## Rejection status

The user rejected v2, localized v3 construction and the first thin-grass/grainy v4 material on 16 October. Revised v4.1 is a review candidate; no final art gate is accepted. The current-state descriptions below record implementation, not accepted quality. Garden setting is relatively improved only. See [the rejection audit](art-rejection-audit.md). The concept is a quality/style reference, not an exact layout to reproduce.

## Scale and visual contract

- The child should occupy approximately 18–23% of gameplay-view height, as in the repeatedly supplied concept. Current 42-world-pixel sprite with camera zoom 1.7 occupies 19.8%; the physics capsule stays 30px and existing jumps/tools remain unchanged. Camera tracks upper routes to keep the avatar visible.
- Garden child and Foxy use the same relative proportions at scale 2; portrait uses a closer 440×360 camera view with ball tracking, the cottage sits behind the fence, instead of a huge cropped foreground porch. The dedicated garden contains no adventure platforms, cranks, checkpoints or coins.
- Rich fine pixel detail is required. Large crude pixel blocks, small unreadable avatars and repeated framed earth cubes were rejected.
- Ground must have continuous grass, organic rock faces, rounded ledge caps and hanging roots. The former cropped/mirrored rectangular fill failed that requirement. The current contour candidate removes shared internal edges and uses deeper vegetation; overall composition remains open. Scenery roots require a continuous supporting bank. Decorative art never silently changes collision.
- Background retains village, castle, trees and windmill, but has lower contrast and atmospheric depth. The empty blocky sky/hills alternative was explicitly rejected. Contextual runtime review is required before approval.
- Use the same canonical coin, shared wood/cream/navy controls and accepted PETOPIA lettering/wording. Final texture-based UI chrome and animated UI states are still pending.

## Character and animation inventory

| Subject | GDD / concept target | Runtime state | Remaining work |
|---|---|---|---|
| Explorer turnaround | V01; front, side, back user requirement | Side-view identity in pilot assets | Production front/back views, anchors and selected outfits remain missing |
| Child idle / walk / run | §26:4/6/8 frames | One idle pose; eight measured run poses with consistent warm skin/boot colors and source baselines, distance-driven even under reduced motion | Separate idle, walk and run clips; review weight and foot timing |
| Child jump / fall / land | §26:3/2/3 frames | One jump pose; independent sparse pixel shadow projects onto actual terrain | Anticipation, ascent/apex/fall and landing clips |
| Child interact / pet / celebrate | §26:4–8 each | One throw pose; interaction mechanics work | Real action clips and attachment anchors |
| Child hazard response | §26:3–4 where used | Recovery mechanics, temporary acting | Gentle response and recovery clip |
| Foxy baby / child turnaround | V01; species/stage identity | Side-view pilot poses at two stages | Front/back sheets and all equipment anchors |
| Foxy idle / walk / run / jump | §26:4/6/6/3 per stage | One idle/jump pose and six distinct gallop-phase candidates per stage | Separate clips and approved stage-by-stage frame timing |
| Foxy sleep / eat / play | §26:4–8 for used care | A38 two independent curled-sleep poses; four room sizes, fixed mattress and bolster | Mature identities, sleep/wake transitions, bath/feeding/play acting and contacts |
| Foxy expressions / ability / celebrate | §26:3–10 | One dig pose, temporary effects | Real sniff/dig, mood and celebration clips |
| Greeting / waking / growth | §26:4–10 or shared effect | State transitions implemented | Production transition acting/effects |
| Other pets/stages | Phase2–4 gates | Not implemented | Do not infer full roster completion from Foxy assets |

## Scene and interface inventory

| Group | Approved source | Current candidate / implementation | Remaining / approval |
|---|---|---|---|
| Grass banks and natural earth | V02 foreground | `meadow-system-v4/` continuous contour material/fringe; rejected noisy material and thin scale retained as superseded | Contextual review; more authored corner variants and deeper rock kit |
| Floating ledges | V02 upper-right shape | Rounded end caps, scalloped underside and roots | Review art overhangs against every used collider |
| Trees / shrubbery | V02 grounded foliage | Root-aware placement plus trimmed source alpha gutters; gaps/unsupported ledges excluded | More variants and layered foreground composition |
| Wooden platforms / bridge | V02 crossing | One bridge deck source; timber posts enter water with foreground river occlusion; baked floating rock feet excluded | Full mechanism animation, bridge end dressing and per-level variants |
| Water / holes | V02 foreground river | River texture with animated sample; diagnostic gray gap hidden in art | Falls, splash, rock/foam edge dressing and per-world variants |
| Crates | A06 reusable tools | Proper wood sprite, 24×24 unchanged physics, stackable | More tools and production placement feedback |
| Crank / checkpoint / chest / food / basket | V02; GDD used objects | Separate anchored rotating crank kit; original shared checkpoint/chest/food/basket atlas | Crank interaction candidate under review; flag/open-chest animation and polish unfinished |
| Three background depth layers | GDD §25 | One combined panorama with parallax and separate foreground props | Independent distant/middle/near layer art remains pending |
| Adventure background | V02; user contrast feedback | Village/castle/windmill retained, quieter depth and scale | Rejected runtime integration; quality and depth need rebuilding |
| Home garden / fetch | A12 dedicated home garden | Scaled cottage behind fence; larger child/pet; shared throw meter | Rejected actors/finish; care/play action clips and sound remain unfinished |
| Room / adoption / details | V03/V05/V06 | A36 native adoption, separate room/portrait sources; A37 larger home actors and independent empty/sleeping bed states | Review corrected phone floor/scale; native V03 care layout, feed/wash choreography, individual bowl/tub and V06 panels |
| Main menu / logo | V04 + supplied second logo, no floating heart | A33 pixel icons, taller compact phone buttons, illustrated wallet/gear, bundled font, four-pose petting loop and fixed pixel ground contact; static frames and motion clip | User visual review, physical-device checks, remaining shared typography rollout; four menu poses do not complete the gameplay animation inventory |
| Map / pause / result | V07/V08/V09 | Functional responsive prototype | Final shared icon/chrome assets, selected/pressed/focus states and transitions |
| Shop / decorate / inventory | Shared kit; V11/V12 pending | Functional prototype with shared props | Detailed screen review and furniture/equipment art |
| Coin / prompts / effects | Shared UI sheet | Canonical coin, larger 20px pickups, current prompts | Production interaction effects and accessible icon language |
| Audio / ambience | §26 | Not complete | Home, meadow, minigame loops and enumerated effects |

## Current evidence and gate

`tools/capture_art_review.gd` renders the reported gap, joined steps, wooden bridge, crate stairs, airborne child and home garden from isolated game state. The art regression suite checks support, exposed surfaces, source regions, hero scale, gait, shadow state and garden fetch. Those checks do not approve the visual result.

The previous generic square-terrain and oversized-house passes were rejected. Their files remain as superseded work; the subsequent reference-derived bank and scaled garden were also rejected. The full Phase1 art/animation/UI/audio gate remains open. Review the actual scene against the approved concept before bulk asset production continues.

## v4.1 evidence and limits

`tools/capture_world_rebuild.gd` records eleven runtime views across lab joins, river, both adventures, dedicated garden and portrait; `--fixed-fps 60` keeps PNG-write time from distorting the recorded run cadence. The reduced-motion clip includes a real crank action, movement, jump and landing. This samples existing shared rendering, not completed unique level art. Further unreviewed content rollout is stopped. The decoration sheet is a retained study, not another integrated patch. See `rendering-research.md`, `meadow-system-v4-prompts.json` and the asset manifest.

## Interaction/story follow-up

- Original river cascade/rocks restored after the water-only plane was rejected. Bridge deck, crossbeams and timber pile regions are independently placed; last beam/pile avoids the rock. Water contact remains under visual review.
- Trees now reject raised-step intersections across their root footprint and reserve clearance for interactive props. User reported some grounding improvement; do not infer whole-route acceptance.
- Checkpoint uses the existing flag with a one-time cloth/particle reaction, no floating title. Crank focus affects only the wheel. Floating action words are removed; the real Use/Find controls and HUD explain actions.
- Chest has separate reveal/open states and visible canonical coin contents; original source lid/body are rendered separately. Complete open animation is still a small runtime construction, not a newly approved production chest sheet.
- `resident-v1/moss-reactions.png`: generated transparent 2172×724 source; measured idle/wave/celebrate regions and foot pivots in `resident-production.json`. Candidate only; no complete NPC locomotion or visual approval.
- Story result uses shared native cream/gold controls, canonical coin and existing food visual. It reflects the durable reward receipt. V04 main menu is now a native runtime candidate; final V09 illustration/chrome and the remaining shared UI rollout remain unfinished. See [menu review](menu-review.html) and [production metadata](menu-production.json).
- Free crate placement replaces the authored numbered spots. Same 24×24 physics/art and save writer; world position, preview/confirm/cancel and legacy layout recovery are verified. Physical phone playtests remain open.


A29 water contact effect: `WaterContactFoam` adds native half-pixel-snapped white/cyan ribbons, fading wakes and side splashes at existing pile waterlines, layered behind/in front of timber. No bitmap replacement or new landscape. See `water-foam-motion.json` and actual desktop/portrait captures. Visual candidate only.

A36/A37 adoption/room sources and feedback: `adoption-production.json`. V05 native name/back/settings and durable adoption are implemented. The bed is independent furniture with two authored states; resting Foxy is drawn inside it, and state persists. User rejected the first room scale/bed placement and phone window contact; corrected actual captures are candidates, not approval. Full V03 care UI, transitions, growth-specific sleep poses and physical mobile keyboard/device checks remain open.

A38: room age proportions no longer collapse child/teen/adult into one size, and sleeping Foxy is independent of the fixed furniture. Numeric height ratios are provisional; only baby/child source identities exist, and teen/adult still reuse child art at distinct sizes. `home-growth-production.json` records regions/pivots and `home-growth-review.html` shows actual four-age standing/sleep comparisons.
