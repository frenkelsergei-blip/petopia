# PETOPIA design amendments and playtest feedback

This is the working amendment to the supplied GDD v1.1. The original DOCX and extracted source remain intact under `docs/sources/`. The user's direct instructions govern changes to the game; concepts and earlier document wording remain references. Status here distinguishes implemented behavior from unverified work and prototype choices.

## 16 October 2026 decisions

| ID | User direction or observed issue | Document relationship | Current state and evidence |
|---|---|---|---|
| A01 | The child throws the ball; the pet catches automatically | Refines GDD §17's catch-timing wording | Implemented. Child-controlled throw, pet chase/catch/return and practice/ten throws. Scene and graybox tests; native throw/return checked. |
| A02 | Adventures should give useful supplies for later play | Extends GDD §§16–18 rewards and inventory | Implemented. Picnic gives one meal; Windmill gives two plus a first-cache meal. Counts are provisional. Real shop food-use and reload are tested. |
| A03 | Next level needs more jumping, exploration and pet cooperation | GDD §§9–11 already specify cooperative puzzles and W01 L02 Windmill Walk | Implemented graybox. Hill route, slow platforms, food bags and Foxy dig opening lift/bridge. Lower fallback remains open. Both routes and a real moving-platform rider are tested; complete manual upper-route audit remains open. |
| A04 | Intermittent adventure glitches/sticking | Performance and playtest acceptance gate | A save-related pause was reproduced and addressed with background coalesced saves and camera interpolation. Local worst frame 567 → 23 ms. User clarified that glitches are intermittent and authorized continuing. Keep this report open through art integration; do not call every glitch fixed. See `performance.md`. |
| A05 | Some high ledges are not reachable with the current jump | Level layout/accessibility concern | Implemented and verified for the reported type of ledge: direct jump fails; three physical crate-step jumps reach the selected upper ledge. Continue the full upper-route audit. Do not make a main exit depend on a missing item. Screenshot feedback is retained under `docs/feedback/`. |
| A06 | An adventure bag should carry reusable boxes/tools, with stacking and use later elsewhere | New user-requested extension of GDD §§10,18–19 | Implemented and verified first tool: wooden crate pickup, bag controls, authored spots, stacking, packing, cross-level reuse and save/reload. Three total crates, two per spot and fixed build spots are prototype choices, not separately approved requirements. More accessories and free-form building are not implemented. |
| A07 | Continue to the approved visual style while retaining diagnostic graybox | GDD §§25–26; accepted V01/V02 concepts | Runtime art pilot integrated and rendered/profiled. Generated explorer/Foxy poses, terrain/foliage atlas and meadow backdrop. Incomplete animation inventory; generated assets are not automatically final production assets. |
| A08 | Keep every change in the project workspace, progress and documentation | Ongoing working process | This amendment, `change-log.md`, `progress.json`, `verification.json`, README and asset register form the durable record. Status and evidence must be updated before the iteration is reported complete. |
| A09 | Mobile-first, portrait play with adjustable on-screen buttons; keyboard remains for PC checks | Explicit user requirement refines GDD §§21,25,28; supersedes the earlier landscape-only prototype layout | Implemented portrait presentation: shared actions, scrollable menus, thumb controls, notch/gesture insets, saved button size/spacing/height and aspect-aware adventure camera. 35 mobile checks across four simulated sizes pass. Physical Android/iOS play and signed exports remain pending. |
| A10 | Runtime should match the repeatedly supplied V02 concept; tiles, floating trees, square ledges, prop gaps and jump shadows were rejected | GDD §§25–26 and accepted V01/V02 are the target, not generic platform-game art | Revision rejected by user: source-derived organic terrain, supported scenery, prop/water art, larger coins, grounded-only shadows and distance-driven movement cells. Prior square terrain pass rejected. Automated checks and captures do not imply visual approval. |
| A11 | Retain the lively village/castle background but reduce dominance; do not replace it with an empty coarse-pixel sky | Direct clarification of A10 | Empty background rejected and not integrated. Current candidate retains landmarks, softer contrast and distant scale. Visual review remains open. |
| A12 | Fetch belongs in a dedicated home garden; child, pet, house and scenery must be proportionate | Refines §17's minigame presentation and accepted home direction | Dedicated GardenPlayground and scaled cottage/bench/fence plate, larger child/pet, shared throw meter. First giant cropped-house plate superseded. Garden art and actors remain rejected; setting is relatively improved only. |
| A13 | Character detail/size must match concept; track front/side/back views, action clips, UI/menu/logo assets explicitly | GDD §§25–26 plus user's direct production-inventory requirement | Camera framing now targets 18–23% hero height; current 19.8%. Garden actors are 84/48px in a 360px view. Production matrix records missing turnarounds, separate action clips, UI chrome/logo and audio. The complete production set remains unfinished. |

| A14 | V2 runtime is rejected: low-detail child/Foxy, repeated water/rocks, square cuts, detached bridge and pasted layers; concept is a quality benchmark, not an exact layout to copy | Direct user correction of the previous implementation and proposed literal crossing reproduction | Visual gate failed. Retain mechanics work and source art; repair the renderer and coherent modular asset construction. Do not present a flat concept recreation as a game implementation or call a change closer without visual evidence. |

## 16 October · additional visual feedback and rebuild

| ID | User decision / feedback | GDD relationship | Current implementation / remaining gate |
|---|---|---|---|
| A15 | Localized art patches, thin grass, repeated square sections and hovering roots are rejected; build a coherent playable section first | GDD25 modular kit, consistent density and dimensional scenery; V02 quality target | Revised v4.1 continuous terrain contours, deeper fringe, broad illustrated rock material and alpha-trimmed roots are a review candidate. Earlier thin/grainy v4 is rejected. Unique composition/variation over full routes and final visual acceptance remain open. No completed art phase. |
| A16 | Child/Foxy must actually run; gray/purple fists and inconsistent skin colors look wrong | GDD26 locomotion poses, fixed pivots/material identity | Eight child source poses and six per Foxy stage, measured frame bounds/baselines, distance clock advances under reduced motion. Intermediate gray-limb sheet rejected; color-corrected sheet integrated. Full clip inventory, weight/foot timing and animation approval remain open. |
| A17 | Use the reference's broken pixel shadow rather than a smooth unrelated oval | User's supplied run/jump shadow crop | Sparse pixel clusters project onto ray-detected ground, fade/shrink with clearance and disappear over empty gaps. Garden uses its ground contact plane. Visual review remains open. |
| A18 | Crank must visibly do something; bridge feet must meet water; coin must not hide behind flag | Existing interaction/readability requirements | Lab crank now rotates and opens/closes the bridge; closure is blocked under either actor. Picnic retains durable one-way opening. Supports enter water and are occluded by river, excluding baked floating rocks. Three coin positions moved, array indexes/counts stable. Functional regressions pass; art is not approved. |

The source GDD is unchanged. The revised terrain renderer is shared by existing lab/adventure layouts to prevent mixing old and new drawing code, but this is not completion or approval of their art. Latest instruction stops further unreviewed content rollout. [Research and explicit implementation choices](rendering-research.md) distinguish source facts from our chosen contour renderer.

## Process for each playable iteration

1. Record the user direction here with its GDD relationship. Mark new implementation choices as provisional.
2. Update code, typed level/item data and any saved-state validation together.
3. Run relevant mechanics/persistence checks and inspect an actual runtime render. Performance-related changes also use a headed timing sample.
4. Update `docs/progress.json`, `docs/verification.json`, this amendment and the change log. Rebuild the tracker with `python3 tools/build_progress.py`.
5. Preserve pending work: unfinished graphics, new mechanics under test and unconfirmed playtest reports do not count as completed phase outcomes.

The phase roadmap remains the GDD's four phases. A user-requested early mechanics preview (such as level two or a reusable crate) does not complete its broader phase gate.

## 16 October · interaction, free tools and story follow-up (A19–A27)

These later direct instructions supersede the authored-slot prototype and the flat-water trial. The original GDD remains unchanged.

| ID | User direction / feedback | Implemented candidate and remaining gate |
|---|---|---|
| A19 | Trees still appear detached in motion; later user reports a grounding improvement, but a tree intersects a raised step | World-fixed roots sit into the foreground fringe; full root footprints reject steps and unsupported bank edges. Scenery reserves room for props. Parallax samples the interpolated render clock. Partial positive feedback is not full terrain approval. |
| A20 | Nearby usable objects need clear emphasis; wheel support must not glow; remove floating Foxy/Open/Use/Checkpoint words | Wheel-only alpha contour, no support outline or decorative pulse. Built bridge suppresses its outline; consumed actions clear focus. Real Use/Find buttons and objective HUD provide instructions. No floating action captions. |
| A21 | Flat replacement river ruined rocks/falls and flooded the composition; original looked better | Water-only plane is explicitly rejected and removed from runtime. Original cascade/rocks restored. Deck alignment retained; last beam and pile move 14 world pixels into current to avoid the rock, with original river samples in front of feet. Contact remains a visual review item. Isolated SmartShape trial was also rejected and never integrated. |
| A22 | Crates must go where the child chooses, rather than at prescribed numbered points | Free world-coordinate selection through Bag → Place a crate; ghost, touch/mouse choice, arrow adjustment, confirm/cancel, real collisions, stacking and packing. No numbered spots. Ownership remains three reusable crates; previous two-per-slot rule is superseded. Support, solid/actor overlap and nearby reach checks apply. Old numbered layouts load without reward/ownership loss and can be packed. |
| A23 | Checkpoint needs an arrival reaction, not overhead text | Fixed pole and short cloth flutter/star burst on first activation; static visited check afterwards. Reduced motion suppresses decorative motion. Loaded checkpoint does not replay arrival. Flag moved beside the recovery point; pickup positions adjusted with stable indexes/counts to prevent overlap. |
| A24 | Chest should be usable and show contents; commands must match the existing buttons | Find/Q reveals the cache and optional trail; Use/E opens it. Lid and canonical coin contents are visible. First treasure bonus remains +10 at durable adventure completion; opening again cannot duplicate it. Optional saved chest state is validated; old bonus eligibility is retained. Reward-free lab explains its practice chest and awards nothing. |
| A25 | Replace the unexplained capsule resident; finish cannot be an empty Use marker | Illustrated Moss rabbit with idle/wave/celebrate reaction poses, grounded picnic blanket/basket, visible practice finish and wooden return gate. Rabbit appearance is a provisional interpretation of the GDD's friendly forest resident, not a newly approved species concept. Complete NPC animation/art approval remains pending. |
| A26 | A clear story and successful-mission screen must explain rewards, including pet food | Moss asks for the missing basket. Returning it resolves the picnic; result shows actual completion/pickup/treasure coins, meals, bond XP, new/already-owned keepsake and saved wallet. Receipt commits in the existing durable completion transaction before UI publication. No invented extra points currency or changed base reward rates. Repeated treasure/keepsake cannot be presented as new. |
| A27 | Keep the first stage gentle; repair these issues before menus | Collision layout/challenge retained. Results are implemented as part of the story correction. Main menu, shared final chrome and remaining accepted menu screens still need production work; no overall visual phase is marked complete. |

Desktop launcher: `PETOPIA.app` on the user's Desktop runs `Play Petopia.command`. Close an old game window normally before reopening to load updated scripts while preserving progress. The dedicated art review command uses a separate practice profile.

The post's tools were investigated, not activated as a new production skill set. See [tool evaluation](tooling-evaluation.md). New source asset, prompt, poses and pivots: [resident production](resident-production.json). Current functional results and limits: [verification](verification.json).


## A28 · Waterfall-side support depth

User feedback: the rightmost pile stops midway down the waterfall and must reach the water below. Extended only that pile by32world pixels, preserving its horizontal position, bridge/deck, original river/rocks and all physics/save data. Foreground river samples now occlude its foot in the lower pool. Relevant52 art checks pass; actual desktop/portrait captures inspected. Overall water/art acceptance remains open.


## A29 · Animated foam where water strikes bridge piles

User explicitly requests white animated water collision/foam around the piles, as in the concept. Added a small native pixel-water wake per existing pile: rear bow behind timber, white/cyan broken crests in front, short dissolving wakes and small side splashes. Uses the existing waterline and meadow animation clock; original river, rocks, final pile depth, bridge/collisions and persistence remain unchanged. No glow or new generated landscape. Relevant52 art checks pass, actual desktop/portrait captures and60-frame motion sample retained. Functional movement and one headed timing sample do not imply visual/device approval.

## A30 · Continue the accepted menu plan: V04 runtime

User authorized moving on to the menus and subsequently said “Go on.” Implemented V04 first, following the approved concept and shared UI. This records implementation choices rather than new user art approval. The original GDD remains unchanged.

- Application boots to the main menu. Fresh profiles see Start adventure, then existing Foxy naming/adoption, then The Lost Picnic. Existing profiles see Continue: exact pending level/run/checkpoint resumes after restart; with no pending run it returns to My Pet. Existing durable ownership, rewards and saves remain authoritative.
- My Pet and Adventures use existing flows. Practice remains available before adoption and links back to Main menu; Pause also links back. Collection is disabled and explains Coming later. Wallet uses the canonical coin and real saved balance.
- Five reference-derived assets are separate from real native buttons/text/icons. Main menu uses shared nine-slice cream/wood/gold styles with keyboard focus, hover/pressed and locked states. Foreground friends sit on meadow in portrait and landscape. Existing playable terrain/river composition is retained.
- Settings currently includes reduced motion and touch size/spacing/height. Before adoption, a validated atomic preferences file in the same isolated save directory publishes only after write/readback/rename; adoption inherits it. After adoption, the existing ordered full-profile transaction saves settings. There is no second routine background writer or full-save schema change. Audio production/settings remain pending.
- One native responsive menu owns portrait and landscape, with safe insets, >=48px targets and live resize. Short portrait/tablet menu layouts use a minimum720 logical height; gameplay retains its prior camera/input layout. This is a provisional responsive implementation choice.
- Nine suites:323 checks pass, including36 menu checks exercising actual pointer/keyboard actions, failed preference writes, adoption, settings and exact Continue after restart. Seven headed captures inspected. Final art acceptance, physical-device checks and the remaining V05–V09 production UI remain open. See [native menu review](menu-review.html), [asset prompts/regions/pivots](menu-production.json) and [verification](verification.json).

## A31 · Preferred cream menu button

User explicitly preferred the second attached button: cream inset with the simpler wooden frame, rather than the gold first image. This establishes the menu-button style preference, not approval of the entire menu or all runtime art. References retained in `docs/feedback/2026-10-16-menu-buttons/`.

All illustrated menu buttons, including Start/Continue and Settings Done, now use the existing cream texture for normal, hover and pressed states. Hover/press use restrained brightness changes; keyboard focus stays blue and unavailable content remains desaturated with a lock. Gold source retained as unselected provenance, not used by menu buttons. Other UI selection colors and canonical coins are unchanged. Relevant36 menu checks pass; seven actual Godot captures refreshed and inspected. Original GDD unchanged.

## A32 · Menu proportions and shared-concept fidelity

User reports the implemented menu remains too elongated and unlike the approved reference: main buttons need shorter width/more height, better seated illustrated icons, faithful wood-framed wallet and bottom-right Settings with its blue gear tile. Existing small flat/vector symbols and generic wallet are not accepted as matching the concept. Two comparison references retained in `docs/feedback/2026-10-16-menu-fidelity/`. A31 cream preference remains; this feedback does not approve the entire menu.

- Desktop action bounds change from425x76 at112,244 to352x98 at150,230, with106px row spacing. Native rounded display font,58px aspect-preserving illustrated icons, aligned title area and separate Coming later caption follow the V04 hierarchy. Portrait keeps safe bounds, live resize and >=48px targets.
- Five transparent icon sources (play/paw/map/lock/gear) and an empty detailed wood/cream wallet frame were generated from the approved V04/shared sheet with the built-in image_gen tool. Full sources, exact prompts, alpha regions, pivots and states are retained in `docs/menu-v2-production.json`, the manifest and asset register. Buttons now sample the full cream source directly through independent source/logical nine-region corners rather than enlarging a360x90 intermediate texture.
- Wallet remains the canonical coin and actual native saved balance; its illustrated frame is212x90 at1044,20 with no extra Coins caption. Settings is164x76 at1100,628 with a44px blue gear tile. Practice remains accessible. No authored landscape, actor gameplay, reward/save rules or schema changed.
- Lilita One display font is bundled with its OFL license and official source metadata. It is a closer rounded-type candidate, not a claim of exact font identification. Other prototype screens still await shared production UI rollout.
- Full nine-suite323 checks pass; seven actual Godot captures inspected with child/Foxy. Previous frames retained under `docs/screenshots/menu-before-a32/`. New visual result and physical-device review remain open; no final phase/visual gate closed.

## A33 · Pixel icons, mobile balance and living menu

User says the A32 icons are too smooth and the paw/play/map/lock do not match the supplied pixel-art close-up. User also requests menu-button animation, an animated child/Foxy interaction and pixel ground contact shadow. Phone layout needs narrower buttons, smaller Settings icon and more space for the pair. Subsequent feedback asks for taller buttons with smaller icons/text so labels fit. The relative improvement reported by the user is not final art approval.

- Pixel-art icon sources replace the smooth V2 set, using the user's close-up: stepped dark contours, compact paw pad/toes, simple map route, squared blue lock and blue gear tile. Original sources and superseded alternatives remain recorded. New prompts/regions/pivots: `menu-v3-production.json`; active manifest under `assets/ui/menu-v3/`.
- Latest balanced bounds: desktop352x104; phone282x72/76, max304 on portrait tablet. Phone action icons36px, titles24px (fresh start22px), gear26px; desktop icons50px, gear36px. Larger child/Foxy region, smaller header/footers and safe bounds remain visible together. Final sizing occurs after font/content updates to avoid retaining the previous layout's minimum width.
- A31 cream remains the rest state. User explicitly requested gold when selected, so focus/hover now uses the gold source. Pointer moves native focus; labels and hitboxes stay fixed. Icon lift/press feedback is subtle and honors saved reduced motion. Continue is shown for a returning profile; Start adventure remains explicit for a fresh profile, with actual wallet values.
- A new four-pose petting/fox reaction sheet uses common530x517 regions and measured source foot baseline622 in every pose. Safe-packing repair preserves complete tails/outlines. A3.2-second calm loop moves hand/face/ears/tail through authored poses; no whole-pair bouncing. Sparse translucent pixel patches under boots/paws remain fixed on grass. Reduced motion holds the calm first pose and suppresses button motion while keeping selection feedback.
- All331 checks across nine suites pass, including44 menu checks: four actual poses visited, fixed canvas/contact, reduced-motion freeze, five screen sizes and native text/icon fit. A headed120-frame/30fps portrait video records the loop, hover and fixed anchors in an isolated returning profile. It is a fixed-simulation render sample, not device-performance or final visual approval. Previous A32 captures retained under `docs/screenshots/menu-before-a33/`.


## A34 · Collection caption and stable Settings alignment

User reports overlapping Collection/Coming later typography and a misaligned Settings icon. The title and smaller regular subtitle now occupy a centered VBox with explicit separation. Settings uses a centered HBox for its gear and title; decorative independent gear movement is suppressed, preserving native focus/selection. Existing dimensions, art, gameplay and saved preferences remain. Relevant49 menu checks pass, including separation/alignment at five sizes and prior durable save coverage. Seven native captures and120-frame motion sample refreshed; final visual/device approval stays open. Original GDD unchanged.


## A35 · Short Start label and consistently centered action icons

User explicitly requests Start rather than Start adventure, matching fonts/sizes across actions and vertically centered play icon on tablet. Fresh profiles now show Start; returning profiles retain Continue. Four equal action frames use24px portrait/34px desktop titles. Icon positioning runs after final button sizing and refreshes feedback after resize; subtle scale feedback retains each center instead of lifting vertically. Adoption, save and gameplay flows unchanged. Relevant54 menu checks pass; physical-device and final visual approval remain open. Original GDD unchanged.


## A36 · Continue from corrected menu to native adoption

User accepted the A35 menu alignment and authorized continuation. V05 is the next planned screen. Native Meet Foxy now retains the approved room/cream/wood/pixel identity, editable20-character name, shared canonical wallet, Settings and Back. Existing GameState.adopt must commit durably before navigation; cancellation creates no profile, failure stays visible, and next_after_adoption remains authoritative. LineEdit and screen instances survive resize and settings; mobile keyboard-height adaptation is implemented but still needs real-device testing. Generated sources and provenance are in `adoption-production.json`; no original GDD change or final screen-art approval.

## A37 · Prominent usable bed and room proportions

User explicitly requests a more present bed and other care objects so the pet visibly sleeps in the bed. Subsequent feedback rejects the small child relative to the room, a bed moved too low, and the adoption pair standing on the window in portrait. These are user corrections, not visual acceptance.

The current candidate enlarges home actors, places a separate blue bed to the right beside them above the controls, and changes Rest/Wake between empty and authored curled-sleeping furniture states. Durable care state survives restart and waking restores the live pet. Phone adoption frames the measured room floor above pair contact via a height-dependent wall crop; the window remains above the characters, including short phones. Generated baked-bed source is superseded and retained; two furniture states do not complete stage-specific action clips. Full V03 native care layout and individual bowl/tub actions remain open.371 checks pass across ten suites, including30 adoption/room checks; actual captures retained. Final visual and physical-device review remains open. Original GDD unchanged.


## A38 · Child/Foxy proportions must follow actual pet age

User asks to verify room proportions according to the pet's age so it does not look strange. Audit found only two standing sizes, one baked sleeping baby for every age, and age labels that did not update live. Correct these presentation inconsistencies; keep age rules and durable progress unchanged.

Four room heights now increase gradually:24/30/34/38 versus explorer42, using common room scale2.7. Baby/child retain their prior reference presentation. Exact teen/adult ratios are provisional implementation targets rather than GDD-specified measurements or new user art approval. Real thresholds remain0/7/30/60 days. Sleeping Foxy is an independent age-sized sprite on the same fixed mattress behind its existing front bolster; the explorer and furniture do not grow. Live desktop/portrait captions use the current stage. Teen/adult still reuse child identity art; distinct mature anatomy and full growth/sleep/wake clips remain pending.

126 relevant checks pass, including30 new home-growth checks and adult sleep after restart;401 aggregate checks with prior remaining suite evidence. Sixteen actual age/pose/viewport frames are retained under `docs/screenshots/growth-*`, with comparison/source metadata in `home-growth-review.html` and `home-growth-production.json`. Physical devices and final visual approval remain open. Original GDD unchanged.


## A39 · Phone Web release, circular controller and versioned publishing

User explicitly requests a dedicated Git repository, Cloudflare playable link for a phone (correcting TV), concept-styled phone buttons with a round movement controller, and a versioned release process. The source repository is private; the playable browser build is public.0.1.0 is the first prototype prerelease, not final visual/content approval. Original GDD unchanged.

- Circular wood/cream base and blue thumb follow shared pixel UI; Jump/Use/Find use existing illustrated shared button helpers. One finger owns the stick through drags outside its rim, reversals and a neutral deadzone; a separate finger can use actions. Saved size/spacing/height, safe areas, keyboard controls and resize remain. Prompt, source regions/pivots and state are in `touch-release-production.json`.
- Browser export uses single-thread Godot4.7.2. Native routine worker stays intact; browser routine saves coalesce through one deferred idle writer. Durable transactions supersede stale pending callbacks. Separate regression tests preserve failure/retry, duplicate-reward and shutdown boundaries. IndexedDB data is browser/device local.
- `VERSION`, project version, immutable Git tag, GitHub release notes/ZIP/checksums and deployed `release.json` link each version to its source commit. `tools/release.py` runs checks and exports before publishing to the dedicated Cloudflare project. Details and rollback: `releases.md`. Credentials/build caches/test profiles are excluded. Original assets/docs/experimental sources are retained in private Git; runtime package excludes them.
- All415 checks across12 suites pass. Actual390x844 browser Start/adopt/gameplay, held joystick, coin and reload/Continue verified. Three native scene captures retained; public deployment verification recorded after publish. Physical phones, final shared-screen rollout, long-session phone performance and visual approval remain open. Missing arrow glyphs in the Web instruction font were replaced with clear left/right words.


## A40 · Validate hosting before release announcement

Actual0.1.0 Cloudflare test failed at engine startup: Pages stripped the gzip Content-Encoding override, although the locally emulated headers worked. Keep0.1.0/tag/archive immutable and mark superseded; do not report that deployment as playable.0.1.1 uses a named gzip transport binary with explicit DecompressionStream decoding before WebAssembly initialization. A guarded single-line adapter is applied to the pinned exported Godot loader; changed engine source aborts packaging for review. Source texture quality, gameplay and save format are unchanged.

`tools/verify_web.py` checks actual hosted version/source commit, decompresses WASM to its magic signature and verifies every game-pack chunk and full SHA256. Publish runs it after deployment and before GitHub release announcement. Actual Cloudflare0.1.1 preview menu boots at390x844 with no runtime error. Production gameplay/reload evidence follows promotion; physical phones and final visual gates remain open.


## A41 · Complete the current internal menu/care loop and rotate adventures

User accepts the public preview as a start but finds the internal menus/basic care insufficient. User explicitly requests concept-faithful button sizes, alignment, icons, spacing and proportions down to small details; V03/V06/V07/V08/V09 are the implementation references. User confirms Foxy receives commands rather than direct character control, and home supports both landscape and portrait. Adventures on a portrait phone must show a rotate prompt and pause; the main menu/home remain usable in portrait. This supersedes the former portrait adventure-play layout, not keyboard/desktop testing or the same physics/save systems.

Authorized implementation: shared native illustrated home/care, details/growth, map/level selection, pause/settings, results and existing shop/decorate/minigame entry flows. Keep actual available content distinct from future worlds/species and preserve free care/ownership/rewards. Feeding, cleaning, water, petting and rest require visible room behavior, status and durable effects; new poses remain candidates for visual review, not complete production animation sets. Original GDD preserved.

## A42 · Actual room behind modal blur

User explicitly corrects the Pet Details background: the concept's painted room has a different layout from the real My Pet room. Modal panels must show the actual room softly blurred, with sharp UI as in the concept. Implemented candidate uses the same world viewport and two half-resolution Gaussian passes for the backdrop; the sharp portrait crops that same world. V06 UI skin retains only its transparent frame silhouette, not its painted room. The home instance is retained across its menus; unfinished care cancels without consuming a meal. Exact native V06 frame/row/footer geometry replaces the previous generic wallet-framed layout. This is implementation evidence, not visual approval.

## A43 · Reject crowded home; choose a new interaction layout before publishing

User rejects almost all button proportions and the room's density: icons too large, some buttons too narrow and poorly aligned, and too many permanent buttons. User proposes hiding general navigation in a single menu and possibly revealing care actions only after a Care/pet action, and requests new concept exploration and comparable virtual-pet examples.

This supersedes copying the V03 permanent navigation/care dashboard verbatim. Preserve its approved art identity and furniture/world quality, but redesign the home interaction hierarchy for phone portrait and landscape. Current0.2.0 candidate publication is stopped; public0.1.1 remains unchanged. Audit evidence and brief: `feedback/2026-10-16-home-crowding/audit.md`. Three image-based layout proposals must be reviewed before building the replacement. No new layout is selected or approved. Existing functional care, same-room modal blur, save and rotation fixes stay available in the workspace;449 automated checks are not an acceptance of the rejected UI.

## A44 · Select quiet home → care drawer; drinking-water bowl; both orientations

User confirms that A43 displayed option1 (Quiet Room, `quiet-room.png`) and option2 (Foxy Care Drawer, `foxy-care-drawer.png`) are successive states of one selected flow: pressing Care for Foxy in1 opens2. User approves the portrait/iPhone direction and requires a proper landscape adaptation as well. Water must mean a pet bowl of drinking water, never a wash tub; Clean remains bathing.

Implement this selected flow natively on the existing Godot room, actors, care transactions and save/orientation systems. Quiet home retains a compact canonical wallet, one Menu entry and one Care entry. Secondary navigation moves into Menu; detailed needs/growth remain reachable but do not occupy the home. Choosing a care action closes the drawer so its real animation is visible. Open modal backgrounds use the same room with soft blur. Revised selected references and extracted production candidates are saved separately; layout/identity selection does not approve the complete production animation set, physical-device behavior or full game phase.

A44 implementation evidence: native room retains only wallet/Menu/Care. Six care actions open below in portrait and beside the pair in landscape; eight secondary destinations are in Menu. The same room is softly blurred while open. Water uses a separate blue drinking-bowl icon and serving sequence. Responsive actor/furniture coordinates replace fixed toy positions that could fall outside narrow windows. All461 checks pass, with actual native/local-browser captures and nine headed frame-time samples. This resumes the selected0.2.0 release candidate; final runtime art, full clips, tablet crop review and physical-device checks remain open.

## A45 · Prevent concurrent browser sessions from overwriting progress

During A44 hosted care/reload verification, an old0.1.1 test tab was still running against the same browser-local save. Care persisted correctly after closing that stale writer; two simultaneous engines can overwrite each other's IndexedDB filesystem snapshots. Add an origin-scoped browser Web Lock before engine initialization. A second tab remains on an explanatory retry screen and never mounts the save filesystem. The browser releases the lock on owner close/reload/crash. Native ordered saves, durable transactions, rewards and schema stay unchanged. Older already-running builds predate the guard and should be closed when updating.0.2.2 retains the selected A44 layout.

A45 hosted verification:0.2.2 source `8fa0fb6ef9d4914fd9467c464b37ca1dacc4b9b6` matches the deployed bytes. Second tab blocks, owner close then Retry boots, prior drinking5XP survives reload, selected Care flow works390×844 and844×390.461 checks pass; receipt/captures under `releases/v0.2.2.json`. These are actual desktop browser/native tests, not physical-phone or final art certification.

## A46 · Phone memory budget: images sized for display, released per screen

User reports the hosted0.2.3 loading screen crashes on phones (Chrome and Safari) during "Downloading the game", while desktop browsers work. No release had been tested on a physical phone. Native measurement found every source image decoded to about6 MB regardless of on-screen size (for example the coin is1254×1254 but drawn at roughly40–200 px), the menu alone held about100 MB of image memory, home176 MB, and adventure art stayed resident after leaving it (menu after play192 MB).

User direction: the game will grow to many adventures and screens, must look the same on Mac and phone, and should not keep separate quality per platform unless needed. Rule from now on:

- Source images remain the art of record. Runtime copies are generated only where measured display size proves the source is larger than ever drawn on the largest supported display (4K desktop, large phone and tablet). Copies report the source size, so regions, pivots and layouts never change. `tools/measure_texture_scale.py` measures; `tools/build_runtime_textures.py` generates; `tools/compare_texture_captures.py` compares before/after captures.
- Each screen loads its own art and releases it when left. Adventure art caches are released on every screen change.
- Per-screen graphics budget target on phones: about80 MB of images; `tools/profile_texture_memory.gd` records it. New art must be produced at the size it is shown, and large reusable pieces are preferred over unique full-screen paintings.
- Further steps, not yet done: split downloads by adventure when content grows; evaluate compressed GPU textures (ETC2/ASTC) only after visual review; a separate HD set for desktop only if a later screen needs it.

The loading page now does the engine and pack steps one after another, writes pack parts into one buffer, and remembers the last startup step across a crash so the next visit shows where loading stopped. Whether the phone crash is caused by engine/download memory or by image memory is not yet confirmed on a device.

## A47 · Root cause of the phone loading crash; visual rebuild against the concepts is next

User (2026-10-18): 0.2.5 still does not load on phones in any browser; the current game looks far from the concept pictures (menus, layout, portrait). Only the child and wolf/fox animations are acceptable. Direction: first make it load on phones, then rebuild screens and menus to match the concept library, working on phone portrait, PC and tablet.

Root cause, measured in WebKit (Safari engine) with an iPhone viewport: the loader passed the assembled pack to `engine.preloadFile` as a `Uint8Array`. The engine uses that argument as a lookup key (`config.fileSizes[file]`), so the browser converts all 41 million bytes into one comma-separated string. That string alone pushed the page process from ~0.6 GB to ~1.9 GB; iPhones close a tab around 1–1.5 GB. The same code path runs in Chrome, which matches "any browser". It existed since 0.2.0; 0.1.1's smaller pack peaked ~1.55 GB and still loaded. Earlier A46 work (image sizes, staging, hashing) did not touch the cause.

Fix (0.2.6): pass the raw `ArrayBuffer`; stream each pack part directly into the one buffer; per-part SHA-256 kept. Measured peak 0.6–0.71 GB (0.2.5: 1.92 GB); empty Godot project baseline 0.56 GB. `tools/profile_web_memory.js` repeats the measurement with a 1 GB review limit; `tests/test_web.gd` guards the buffer hand-off. Physical phone confirmation still required.

The visual rebuild against the concepts is a separate, next step and needs per-screen review; no new layout is approved by this entry.

A47 visual pass 1 (0.2.7 candidate). User direction 2026-10-18: make the app look like the concepts, free to generate assets with Codex. Captured every screen at phone portrait, phone landscape, tablet and desktop (`tools/capture_concept_gap.gd`, `tools/capture_level_strip.gd`; before images in `feedback/2026-10-18-concept-gap/`). Implemented: density-aware native layout scale (physical-pixel canvases on phones/tablets; desktop capped at 600 points tall, tablet portrait 540 wide); V07 map, V08 pause/settings, V09 results, V02 HUD tiles; Codex-generated icon sheet, world cards, earth bank and scenery kit with prompts and sources retained. Kept the user-requested round stick (A39). Not added: concept hearts (no health mechanic) and audio sliders (no music/effects/voices exist), so the UI does not show controls that do nothing. Remaining gaps: largely flat level layout limits V02 depth; no framing foreground tree; home/menu/adoption/details unchanged this pass; "Crates [E]" world label in Windmill Walk. New art is a review candidate, not approval.

## A48 · One component system for all screens; no blur behind Care/Menu

User (2026-10-18), with close-ups: text, icons and heights still differ between screens; small wooden frames look bad when shrunk; Settings appears blue in one place and different elsewhere; the Foxy name tag reads as a broken button; meter right end is square; switch knob is high; memory row unclear; the Care drawer should look like the approved concept and the room behind Care/Menu must not be blurred. User allows deviating from the concept where it looks better, with their review.

Decisions implemented (review candidates):
- Roles with fixed sizes (`PetUI` H_*/F_*): primary 60, button 52, header 52, HUD 48 (touch minimum), tag 32; one button text size 20, tiles 16, tags 15; groups share one text size (`PetUI.unify`).
- Border weight by role: thin (10) for buttons, tiles, squares; panel (14); board (16) only for the main-menu action stack. Rivets drawn at a size tied to the border, only on frames >=110x44.
- Every icon-only control is the same cream square; meaning comes from the glyph colour (blue gear, red X, navy menu bars) from one Codex glyph sheet. This deliberately replaces the concept's blue/red filled squares for consistency.
- Information labels (pet name, region, companion, Coming later) are flat rounded tags, not wooden buttons.
- One header builder for menu screens: back-with-title, wallet, one square.
- Care drawer: centred title between orange paws, close at right; Care drawer and Menu overlays keep the live room sharp (supersedes A44 soft blur for these two overlays; full pages such as details/map/pause still blur).
- Meters are drawn natively, rounded at both ends; the On/Off knob is centred; subtitles that do not fit are dropped, not clipped.

## A49 · Approved UI kit direction (Codex proposal) for every screen

User (2026-10-18) approved the Codex redesign proposal (`feedback/2026-10-18-ui-redesign/kit-proposal.png`, `screens-proposal.png`): "much nicer", to be applied consistently to all screens as a complete mobile UI kit with a component for every situation, not a single place. Hierarchy: one heavy carved-wood outer panel with ribbon banner and leaf decoration; rivet-free gold/cream pill buttons inside; round icon buttons (Menu with a small label); soft care tiles with gold selected state; round map medallions (completed/current portrait/available/locked) on a dotted path; soft tag/wallet pills; frameless stat rows. Keep the project's own 2D characters and rooms everywhere (the generated boy/fox in the proposal are not used); the home/Care screen in particular shows the real room and pair. Supersedes the A48 drawn wood frame and square icon buttons once the kit is integrated; A48 roles, sizes, unified text and the layout check remain.

## A50 · PETOPIA V2 GDD adopted; first milestone = connected Green Meadows with parallax

User (2026-10-18) supplied `docs/sources/v2/PETOPIA_V2_Complete_GDD.pdf` (text extracted to `gdd-v2-text.txt`; 22 concept images in `assets/concepts/current/v2-gdd/`). V2 keeps all V1 features and adds connected 2D Metroidvania exploration, seven-layer parallax, toy parts, Toy Builder, on-foot Pet Racing, Pet Chef and a Game Center. User asked to start with the adventure: Metroidvania structure with parallax scenery in the concept style, assets generated with Codex.

Implemented (review candidate, roadmap step 2 and part of 3):
- `data/world/green_meadows.json`: Meadow Fields, River Crossing, Hidden Cave, Old Tower, Forest Gate as a connected room graph with edge and door exits, spawns, coins, toy-part chests (robot wheel/arm/head), signs, the Foxy Boost shrine and the Vine Climb thorn gate (locked: a later ability). Home is the left exit of Meadow Fields.
- `scripts/world/meadow_world.gd`: rooms built from data; parallax sky 0.05, mountains 0.10, hills 0.20, village 0.35, midground 0.60, foreground 1.20 (GDD factors) drawn as separate seamless transparent strips with vertical parallax in tall rooms; terrain from the meadow kit over plain colliders; cave and tower scenery; fade transitions (instant with reduced motion); Find makes Foxy point to the nearest hidden chest; falls return to solid ground (no fail state).
- Metroidvania loop: Foxy Boost (double jump) learned at the Hidden Cave shrine opens high ledges in Meadow Fields, Hidden Cave and Old Tower; the main route, doors and shrine never need it (tested by a jump-reachability check).
- Progress in `quest_state.world` (room, visited, opened chests, abilities, coins, toy parts) with save validation; chests and abilities are durable transactions; relaunch resumes in the last room.
- Assets: six parallax strips, 31 environment pieces, three action icons (Find magnifier, Use press, Jump), all Codex-generated with prompts and sources kept. Engine choice: custom-drawn parallax rather than Parallax2D nodes, for exact control of tiling and vertical scrolling inside the existing SubViewport rendering.
- Entry: Adventures map, first stop "Green Meadows". V1 Lost Picnic and Windmill Walk remain as stops 2 and 3 and are unchanged.

Not yet done from the V2 roadmap: world map/minimap screen, Toy Builder, Pet Racing, Pet Chef, Mystic Forest/Robot Factory, more pets (Ember, Bubbles), shop integration of parts. Image ceiling raised 210 -> 220 MiB after review (V1 level art still shipped).

## A51 · The pet is the heart of the game (Tamagotchi depth, linked to the adventure)

User (2026-10-18): the My Pet area is still a prototype and should become a full Tamagotchi-like experience, and every pet decision should matter in the adventure. Extends the V2 GDD ("Each mode should affect another mode"; "Bond affects reactions, tricks, greetings and cooperative abilities"); recorded here because the GDD does not spell these rules out.

- Care loop: clean, feed (several foods bought in the shop, with likes and dislikes), drink, play, pet, rest; every action has its own clear animation for each growth stage. Fetch: Foxy runs, catches the ball, carries it back in the mouth and drops it at the child's feet; playable in portrait.
- Growth is visible everywhere: baby Foxy is small next to the child, and grows through child, teen and adult in the room and in the adventure.
- Condition carries into the adventure: a very hungry or very tired Foxy will not set out (the game says why and leads to My Pet to fix it). During adventures Foxy gets hungrier and more tired; when tired, Foxy cannot dig or help with Double Jump until rested or fed (a snack from the bag helps). Shown on a small Foxy status chip in the HUD.
- Growth and bond add helpers, never block the main story (GDD: no weeks-long real-time gates): an older Foxy smells treasure from farther away and digs faster.
- Shop sells foods, toys and decorations with coins earned in adventures and care.
- Kid-friendly: no pet death, needs never punish harshly, offline decay capped (existing rules).

## A52 · One Foxy, one ball (user decision 2026-10-18)

- Every Foxy animation is drawn from the in-game pixel Foxy (foxy-run.png, foxy-sleep-v1.png): black legs, round eyes, no eyebrows, same pixel size. The soft painterly candidates are archived and not used.
- The ball is the yellow sun ball everywhere (fetch, buttons, shop), cut from the same animation sheet.
- Sleeping Foxy curls up facing left; all other animations face right.

## A53 · Sound (user request 2026-10-18, provisional until heard on a phone)

- Soft chiptune to match the pixel art, synthesized by tools/build_sounds.py so every sound can be retuned and rebuilt.
- One loop per place (menu, home, meadow, cave/tower, ball game), crossfaded; music sits about 7 dB under effects. Sound and Music are separate settings.
- The child has short "hup / yay / ouch" voice blips; Foxy has yips, sniffs, munching, lapping, purring and snoring. Nothing loud or scary.

## A54 · Collectable, switchable abilities (user idea 2026-10-18, planned)

- Abilities are found through the story, like the Sky Feather (Double Jump). Each region adds one that opens new places: e.g. Swim for a water world, later others.
- Abilities are kept in a set the child can see, and the active one can be switched during play when a place needs a different one.
- Each ability is a quest-like moment (a shrine, a friend's gift), explained once with a card and shown in the bag.

## A55 · Paper-theater style (user direction 2026-10-18, replaces the pixel-art look)

- PETOPIA becomes a living handcrafted paper-theater world: paper-cut dioramas, pop-up books and puppet animation, visible paper texture, soft shadows between layers, warm light, slight depth of field. References: assets/concepts/current/paper-v1/P01, P02.
- Characters are layered paper puppets (separate head, ears, tail, arms, legs) animated as cutouts with a handmade feel.
- Environments: folded-paper trees, cardboard cliffs, paper waterfalls, clouds on strings; 6-8 parallax layers like stage scenery.
- Paper is gameplay: origami platforms unfold, pop-up bridges open, flowers bloom through folds, hidden doors reveal another scenery layer, the pet can unfold, pull or move paper layers.
- Godot stays 2D: layered sprites, cutout rigs (Skeleton2D or node hierarchy), shaders, Parallax2D. Day/night variations.
- Decisions (user 2026-10-18): our current explorer (brown hair, green jacket, backpack) as a paper puppet, no red cap; Foxy stays a fox; everything converts together before the next release.

## A56 · Paper pet room (P20, approved by the user 2026-10-18)

- User 2026-10-18: P19b treehouse look, with the open space of P19c so the room can be decorated; P16/P19a/P19c rejected as the room.
- Essentials stay fixed on one floor line near the middle: paw bed (left), food and water bowls (front), bath tub (right).
- Bowls are always there and have states: empty, full. The explorer fills them (kibble from a bag, water from a watering can) when Foxy asks or when new food is given; Foxy then eats/drinks from them.
- Decorate uses five spots in the same room: two floor, two wall (beside the window), one hanging from the beam.
- Care animations (user): explorer fills food and water; Foxy eats, drinks, sleeps in the bed and bathes in the tub with a fun bath animation.
- Room makeover (user 2026-10-18): every room piece is replaceable from the shop: bed, bath, food and water bowls, rug, shelf and books, curtains/window dressing, lamp, wall pictures and floor decorations (about 10 spots), plus the wall colour (repaint). Starter pieces are free; new ones are bought with coins. Replaces the five generic "+" spots.

## A57 · Torn-paper collage style (P31) for the whole game (user 2026-10-18)

- Green Meadows rebuilt from concept P31: torn-paper sky, layered sun, drifting clouds, mountains / village hills / lake strips far apart in depth; simple leaf-paper ground with a torn cream edge; few props.
- The explorer and Foxy change to the P31 character look (soft torn/cut paper, no brass pins or jointed puppet parts). Critters may keep their current look.
- All HUD elements and menus (hearts, coins, buttons, boards) are redone in the P31 torn-paper style from new concepts, replacing the A55 cardboard-and-pins UI.
