## 2026-10-20 · Map journey on phones (0.12.1)

- Level map (P69d) in landscape: the map takes 56% of the width; My Journey is the title with 0/6, four part slots and the goal rows filling the side (rows were thin at 844x390). Cream "0/6"; Bonus tag clear of the pin button. Kit cutter trims each piece halfway to its neighbour (slivers beside slots and pins); place labels sized to their words.

## 2026-10-19 · Every screen from the P69 concepts (0.12.0)

- Audit: tools/capture_audit_screens.gd captures 25 screens at 390x844, 844x390 and 1180x820 (Adventures alone per process: it stops headed captures from drawing). Concepts P69a-h (approved): one header, one tile style, one layer, coins only on My Pet, Shop and in levels.
- Codex asset sheets copied from P69 (tools/build_p69_kits.sh): frame-p69, controls-p69, ball-p69, overlay-p69, pictures-p69 on flat blue (tools/build_blue_kit.py --rows, pieces keep their soft shadows, neighbours' shadows trimmed), icons-p69 on magenta (tools/build_magenta_kit.py joins rays and waves to their icon), shadow-p69 on white (tools/build_shadow_kit.py: darkness becomes alpha).
- ConceptScreen: p69 / p69_whole / p69_icon / p69_face; P68 names draw P69 pieces; page_header (X, leafy plaque, coin pill only when given). Rebuilt to P69 measures: Feed, Menu, Details, Shop, Play together, Collection, Settings (three groups, More page; no scrolling), Pause (one column), Adventures (real map, robot parts, locked worlds with a pop-up), Decorate (one tray), level map (slots, goal rows, pin buttons), Bag, result pop-up (shared by Catch the Ball and adventures), Catch the Ball HUD (meter: gold always in the middle, pointer relative to the catch zone), ability pop-up, sign-tip toast in the middle, place-name banner, coin pills (main menu, My Pet, levels) and PetUI.COIN_PATH = icons-p69/coin.
- Catch the Ball: boy's standing frames had their boots cut by the Codex sheet's row line (build_hero_frames grid looks 60 px past it); contact shadows were behind the garden (garden z -5) and now use the P69 shadow pieces; Foxy carries the ball back in the carry drawing (paws), not on the nose. Main menu coin pill smaller and away from the logo.
- Web budget: P69-replaced UI pieces and unused menu41 crops dropped from the export; new kits added to KITS.

## 2026-10-19 · Web fix and one-layer pages (0.11.6)

- 0.11.0-0.11.5 shipped without the new kits (journey-p32, complete-p32, goals-p32, menu41-p32, frame-p68 were missing from tools/sync_export_files.py KITS), so the web build lacked their pictures and JSON layouts. Added; screen guards accept the P68 kit. Release check now includes a phone-size browser run of the built web game.
- P68 pages: no big card; the scene dims and tiles, rows and buttons sit directly on it; lists (settings, journey, result) on one card with flat lines.
- Web budget: superseded and never-loaded art dropped from the export (old paper screens, cut-out leftovers); small fallback icons kept.

## 2026-10-19 · One frame for every screen (0.11.5)

- Concept P68 (style guide from the approved main menu). Codex kit frame-p68 (plaque, close, card, tile, button, tab, tab_on, row, slot) cut by tools/build_blue_kit.py with the concept's own soft shadows. ConceptScreen.p68_page draws the shared header (close X, title plaque, the main menu's growing coin pill with the canonical coin) and one card; p68 / p68_button / p68_whole draw kit pieces.
- Converted: Shop, room Menu, Feed, Details, Play together, Collection, Bag, Pause/Settings, Map with My Journey, adventure Result (pieces swapped). Room HUD hides under a page.

## 2026-10-19 · Main menu from the portrait concept (0.11.4)

- New concept P41-menu-portrait. Codex copies (wordless concept, scene alone, tablet-width scene) give menu41-p32: the logo, Start, cream plank and pills cut from the concept with their own soft shadows (k_*.png), placed at concept offsets and scaled uniformly; the cream plank repeats for every further button. Coin pill (Codex kit, nine-patch) grows with the number. Same design in landscape over the P41 plate. Version tag hidden.

## 2026-10-19 · Concept-true map, clear goals, drawbridge (0.11.3)

- Map: journey-p32/frame.png and frame_portrait.png are Codex copies of P67 and a new portrait concept (P67-map-journey-portrait) with words and dynamic parts removed; the road map painting (map_clean.png) sits in the frame's hole; words, slots, checks, rows and coins are placed at concept coordinates (P67_L). Each open goal row has a round map button; the picked goal glows big on the map with its name and the golden road.
- River Crossing bridge: two halves hinged at each bank on rope posts, raised at 58 degrees (visible), lowering with a bounce.

## 2026-10-19 · Feet on the ground (0.11.2)

- Standing lines set to where each strip's solid top actually starts (measured alpha): meadow ground_top 0.025, caps 0.03, floating ledges 0.035, cellar 0.01, tower 0.015. The torn lip no longer covers the soles.

## 2026-10-19 · Concept-true completion, run cycle (0.11.1)

- P66: Codex edits of the concept itself give card-raw (no words, no stars), frame-raw (also empty stage and strip) and stage-raw (characters only, same pixels). The pop-up draws frame.png at P66 coordinates, then stage_heroes and teaser_mystic per world (P66_WORLDS), then the words, stars, coin count-up and confetti at measured positions; buttons are hit areas over the drawn planks.
- Sky creatures (not grounded) never get a silhouette shadow.
- Explorer run: source/run/cycle-raw.png (contact, down, pass, up per leg), one scale for the cycle; meadow ground_top standing line 0.085 (boots on the grass).

## 2026-10-19 · Journey map, Treasure Vault, world complete (0.11.0)

- Concepts P63 (Treasure Vault), P64 (Journey card), P65 (goal HUD, not used: nothing extra on the play screen per user), P66 (world complete), P67 (map with the journey).
- Map (P67, journey-p32 kit plus a Codex map redraw where every place sits on a road): place labels with a check when nothing is left; every open goal glows on its place (paper icons from goals-p32); tapping a goal draws a golden road from You are here along the roads (P67_ROADS); the My Journey panel lists the four robot parts, Help Moss, Sky Feather, the secret treasure (Bonus) and coins found. Portrait stacks the map over the panel. GameState.journey() drives it.
- Treasure Vault (P63 world sheet `vault`): the cellar gate becomes a doorway (Enter) into a new room windmill_vault with the big chest (propeller + 60 coins), a jar of gems and a trophy (bonus coins), books, apples, a scroll, coin piles and lanterns. Visiting it keeps the cellar gate open for good.
- World complete (P66, complete-p32): pop-in board, golden rays, bouncing heroes, three stars filling in, coins counting up, confetti; Continue or My Pet. GameState.world_finish() pays 200 coins and 100 bond XP once.

## 2026-10-19 · Shop alignment (0.10.7)

- P45 shop (landscape and portrait): stall icon and "Shop" centred as one group on the title strip; owned items show a green "Owned" pill with centred words instead of the Buy plank's coin; the empty Room tab shows a centred house icon, "Coming soon" and one short line; the pale leaf tab icon is tinted green on the cream tab.

## 2026-10-19 · World fixes (0.10.6)

- New world sheet `fixes` (P35-river, tools/world_style.py): crank_stand, crank_round (cut, re-centred on the hub), sign_hint. The crank draws the stand and the wheel turning on its axle (the old crank_wheel art held its own stand and was spun and squashed as one piece); signs show the paper hint badge on the board instead of the old care icon.
- Windmill Cellar: Foxy hops on a pressure plate by itself when the child walks up and holds it until the child goes back left (Come calls it off, then it waits 6 s before helping again); sign text updated; world test updated.
- airy(): flags, signs, lanterns, plants and similar keep only the soft ground oval (no silhouette copy).
- clean_kit_edges.py run on the cave, cellar and tower art; 34 coins added (appended, so saved coin ids keep their meaning).
- Web budget: new pieces sized to their use; crank_wheel/rope_post dropped from the export; hud3 status icons 200 px.

## 2026-10-19 · Floating joystick, animal ground shadows (0.10.5)

- Touch stick: idle alpha 0.4 (world visible through it), 0.9 while held; floating: a touch in the movement zone (lower 70% of the stick side, 45% wide) moves the stick there; release returns it home.
- Critters: no silhouette copy behind them; one soft ground oval like the heroes, wider than the body and a little lower; flyers' oval sits on the ground straight below (ground_below), smaller and fainter up to 170 px high (blob-shadow practice for airborne sprites). Critters draw on their own layer (z 2) above the terrain's grass edge so the oval is not hidden.

## 2026-10-19 · Playfeel and polish (0.10.4)

- Catch the Ball: Foxy's facing could become 0 at its goal (drawn zero pixels wide, so it vanished mid-throw); arc lowered (ARC_HEIGHT 58) so the ball stays under the title; Foxy hands the ball from its mouth into the child's hand (no drop on the grass); Foxy only runs while it has ground to cover; the boy's run frames anchor the ball in his front fist (build_hero_frames hand_anchor).
- Shadows: ConceptScreen.soft_shadow works from the short side (wide planks keep a full halo), BUTTON_SHADOW 0.42, shadow_rect places every halo evenly; used by menu planks, tiles, HUD round buttons and touch buttons.
- Touch controls: bigger stick; a hovering mouse never grabs it; a lost mouse release, leaving the window or losing focus lets go (stick re-centres, walking stops); action buttons are icons only. HUD Map/Bag/Settings without captions. Space removed from ui_accept (it re-pressed the focused Settings button).
- World art: smooth mipmapped filtering for the world layers and small pieces; magenta fringe removed from meadow-p31 (world_style.py cleans every cut); critter silhouette shadows aligned through soft_shadow/shadow_rect, flyers cast a lighter lifted shadow, firmer ground contact.
- Coin pills: ConceptScreen.coin_pill and the HUD pill grow with the number (coin end keeps its shape).
- Toasts: gameplay tips (world, lab, adventure, ball) need Settings > Hints; errors still show; the strip is centred with centred words.

## 2026-10-19 · Eating from the bowl (0.10.3)

- New Codex sheet source/upfox/eat-raw.png: upright Foxy holding the same blue paw bowl in every cell; only the food changes (kibble, berries, apple, fish, cookies, carrot) plus the empty bowl. Frames eat_<food> and eat_empty (tools/build_hero_frames.py).
- Tamagotchi feeding shows eat_<chosen food>, then the empty bowl for the last part of the meal; the food drawn in Foxy's paws (nibble) is no longer used for meals.

## 2026-10-19 · Clean menus (0.10.2)

- My Pet (Tamagotchi room) shows no care words: Foxy's moods and animations say how it feels (GameState.quiet_care while the room is open); real save failures still show.
- Toy ball beside Foxy drew as a white box: the texture was freed right after drawing; textures drawn by the room are now held (tt(), room_tex).
- No hover tooltips (gui/timers/tooltip_delay_sec); button names stay for tests and accessibility.
- tools/clean_kit_edges.py removes the magenta fringe from every cut kit piece (edge colour from the nearest inside pixel, the magenta share turned into soft transparency); build_screen_paper.py runs it on every cut.
- Paper UI draws smoothly (root canvas filter linear with mipmaps; UI kits import mipmaps), so icons are no longer jagged; board slabs repeat their paper instead of stretching (no streaks).
- Decorate (P58): readable portrait layout (three cards then two, Done centred below), landscape tray sized to the screen with cards spread to Done; each card has the light shadow; in the Tamagotchi room the Sun ball card has its own Place button.
- Shop portrait: every card fits above the detail panel.

## 2026-10-19 · P32 UI everywhere, P43 treehouse room, soft paper shadows, critter walks (unreleased)

- HUD from P40: status card at the concept's proportion with the P40 apple and lightning icons, larger spaced hearts, smaller coin pill, round buttons with white rings, soft shadows and outlined captions, smaller joystick without the baked inner line, place banner with a soft-white under-strip (generic for every place) and centred, larger title.
- Main menu from P41 (clean Codex plate, logo, panel, planks with soft shadows, pills, coin counter); Pause & Settings from P42 (two cards, resting picture, seven concept rows first: sliders, toggles, stepper, close; hearts and coins stay visible).
- Bag (P44), Shop (P45), Adventures map (P46: Green Meadows places as stops with checks, gold current place and locks), Foxy Details (P47) and the room UI (P43: status card, need bars, coin pill, menu, CARE board with big icons) built from new Codex sheets copied from each concept, placed at the concept's coordinates (tools/build_screen_paper.py kits, tools/capture_p32_screens.gd compares each screen with its concept).
- My Pet room from P43: empty treehouse plate (Codex edit) and leaf-dome bed, stone tub and bowls cut from a P43 props sheet; the pair is bigger as in the concept; soft furniture shadows.
- World: every piece casts a soft blurred paper shadow plus a soft contact oval instead of a hard dark copy; critters walk with new 4-frame cycles (hedgehog, crab, frog hop: crouch, push, fly, land) that advance with distance, with a small step bob.
- tools/sync_export_files.py keeps the web export list in step with the style kits (sources never shipped).

## 2026-10-18 · Paper pet room from P20 with care animations (unreleased)

- tools/build_room_paper.py: clean P20 plate and room props (bed and tub back/front layers, bowls empty/full, kibble bag, watering can, streams, bubbles, foam, drop, Z, heart, duck, curled sleeping Foxy). Furniture on one floor line around the pair (unit()/spot() layout, portrait keeps the whole row).
- Care: the explorer pours kibble/water (pour pose), bowls fill and empty; Foxy eats/drinks (head-down poses), hops into the tub, bathes in bubbles with the duck, hops out and shakes off drops; sleeps curled in the bed with Zs; petting hearts; Foxy asks with a bowl/Z bubble when hungry or tired. tools/capture_room_care.gd records each step.

## 2026-10-18 · Paper kit for every screen, paper home room (unreleased)

- tools/build_kit_paper.py: the shared kit (panel, card, tile, planks, switches, slider, round, tag, rows, wallet, divider, field, vine) copied from P15/P12; kit_style.gd uses it with the same piece names (falls back to kit-v1), so pause, settings, map and other generic screens turn paper.
- Home room is the clean P16 plate (Codex edit: Foxy, Decorate panel and UI removed); bed, tub and rug are part of it. Puppets act care steps themselves; home puppets keep room scale; paper food bowl.
- Open: adoption/care/home_growth tests still expect the pixel bed overlay and pixel care frames (to update with the puppet care animations).

## 2026-10-18 · Paper bag, pet details and shop (unreleased)

- tools/build_bag_paper.py, build_details_paper.py, build_shop_paper.py: each screen from its concept (P12, P13, P14): Codex edit of the concept with every word and changing part removed (geometry kept), Codex sheet copied from it, layout.json measured on the concept with the old keys (screen code shared; BAG_ART/DETAILS_ART/SHOP_ART switch on ArtStyle.paper). Details adds paper stat icons, plaque icons, empty room picture behind the stage fox; bag count sits on the picture; shop adds coin icon and paw divider.

## 2026-10-18 · Paper main menu (P11) and paper cave (unreleased)

- tools/build_menu_paper.py: clean P11 background plate (Codex edit: every UI piece and word removed, explorer and Foxy kept) and the kit copied from P11 (logo, tagline plank, green/cream/small planks, coin plaque, paper icons). Words live (tagline, captions, "Green Meadows" sign). Portrait slides the plate down so the pair shows under the buttons. Old menu art no longer loads or ships.
- Hidden Cave redrawn in flat paper (three depth strips over an indigo card, crystal ledge, ground, crystals, vines, lantern); paper ceiling.
- Menu tests: the pixel petting-loop checks apply only to the pixel style.

## 2026-10-18 · Paper pass 3: paper HUD, P18 shadows, bigger puppets (unreleased)

- P18 concept (puppet shadows): soft gradient contact shadow under the feet, warm light on near parts, darker far limbs. Puppets at the old sprites' on-screen size (explorer 66, Foxy fox_height x1.9).
- Paper HUD from P10: status card (paper Foxy head, hearts, apple/star meters on paper tracks), coin plaque, round map/bag/gear buttons, context glyphs (dig, enter, open, pick up, place, talk) and the room-name plaque (PaperPlaque centres text by cap height).
- Old Tower/cave floor fill is flat dark paper stone; tower wall and ledges dimmed.

## 2026-10-18 · Paper pass 2: one paper-cut world (unreleased)

- New Codex sheets copied from P02 and redrawn as flat layered paper: far mountains and castle, trees and village, near woods, cliffs (aerial haze tints by depth); ground kit (leafy grass ledge, earth, caps, floating platforms); props, doors, tower, pickups, critters, fauna and Moss in true paper-cut. Hanging twine clouds, sun and bird (hanging.json gives string and body positions). Soft close-up foreground layer (blur 3, small, sparse); front grass strip removed so feet show.
- Puppets resampled to display size with mipmaps (explorer 170, Foxy 110 rig px; pose offsets keep authored units); flat paper contact oval replaces the pixel shadow. Paper P10 controls: cardboard stick with brass knob, orange/blue paper buttons.
- Export list ships the paper art and drops pixel pieces with a paper replacement; small sprites sized near their screen size (budget passes). Known open: three old pixel-sprite suites (trail_tools, art_polish, home_growth), Old Tower floor piece.

## 2026-10-18 · Crisp text (0.6.1)

- Kits erase baked words from the bases (bag/shop titles, stat names, growth text, back button) and the screens draw them with Lilita; kp() keeps scaled text at 11 px or more; font hinting none + mipmaps.

## 2026-10-18 · Shop from concept V11 (0.6.0)

- build_shop_kit.py and build_shop(): tabs, 4x2 cards with price pills, details with Buy (Buy_<Name>), Room tab placeholder. Graybox test selects the toy card first.

## 2026-10-18 · Pet details from V06, audit and new concepts (0.5.9)

- Audit captures of 15 screens at 4 sizes. build_details_kit.py: V06 base with dynamic parts cleared, Codex asset sheet copied from V06 (bars, icons, cards, stage foxes); DetailMeter three-slice bars. Old details-skin/reference art dropped. Concepts V11 shop, V12 collection, V13 mini games, V14 decorate for review.

## 2026-10-18 · Bag from its concept, asset pipeline rule (0.5.8)

- Bag base is the V10 concept with tabs, slots and card cleared; leaves kept by colour and connectivity; items, badge and glow from a Codex asset sheet copied from the concept; layout.json from measured concept rectangles. Sky, cave front and midground layers at 768 px (budget). AGENTS.md: concept-to-assets pipeline.

## 2026-10-18 · Bag cut from its concept (0.5.7)

- tools/build_bag_kit.py cuts frame, slots, tabs, plaque, card, gold button, close and badge directly from V10-bag-v1.png (mirrored clean corners, wide clean middles so Lanczos ringing never stretches; margins set inside the corners). Bag uses these at the concept's scale.

## 2026-10-18 · Inventory bag, arrow position, heart edges (0.5.6)

- build_world_bag rebuilt: bag_items per tab (only owned items), GridContainer of nine-sliced slots in a ScrollContainer, details card with bag_use action. Codex concept V10 and bag-v1 kit. Edge arrow drawn upper centre. Hearts keyed by hue (previous fringe fix painted background dark).

## 2026-10-18 · Bag redesign, whole hearts, abilities plan (0.5.5)

- build_world_bag: quest tag, bag_row() rows for snacks, tools, robot parts (5 columns, count badges, faded when missing). Hearts re-cut with a strict magenta key (the soft key removed pink highlights). A54 and roadmap phase P1D for abilities.

## 2026-10-18 · Status panel without heart sockets (0.5.4)

- Codex redrew the hud-v2 panel without sockets (status2-raw.png); slots re-measured.

## 2026-10-18 · New status panel (0.5.3)

- hud-v2 Codex sheet sliced; slot positions in slots.json; portrait window cut out and a pixel Foxy (pet-v2 pet frames) animates in a clipped sky disc behind the frame; three-slice meter fills. Fix: weakly cached textures freed before render drew white; meter textures are now held. Door transitions play ui_open instead of the door creak.

## 2026-10-18 · Foxy holds the plate, better following, feather art (0.5.2)

- Plates: near kind "plate" (Sit/Come); MeadowWorld.foxy_holding parks Foxy on the plate (plate_pressed counts Foxy); cleared on room change. World test: Foxy holds the cellar gate.
- Companion: top speed scales with distance (138 to 258), targets the child when the trail is stale and the child is >80 away, recover() places Foxy behind a grounded child; stuck 1.2 s; lag catch-up 0.8 s with dust. Pointing releases after walking 140 px past (skipped per visit).
- Codex standalone Sky Feather replaces the cropped shrine top. All suites pass (world 90 checks).

## 2026-10-18 · Guide arrow without label, fitted cards (0.5.1)

- Edge arrow drawn alone; show_card sizes to its text. Double jump traced frame by frame: smooth.

## 2026-10-18 · Foxy finds things, guide arrow, status card, smooth camera, soft sounds (0.5.0)

- MeadowWorld.foxy_discovers: nearest undug spot within smell range; Companion.point_target sits Foxy by it with a "!" marker and barks. New dig items key/snack/carrot; golden key moved from a pickup to Foxy's dig in the Hidden Cave; 8 more dig spots. GameState.world_goal returns room and point; goal_target finds the exit toward it (BFS). Edge arrow with label, bouncing down arrow on screen (Codex markers).
- WorldCamera follows in _process from blended physics positions; scenery redraws per rendered frame (removes parallax jitter against the interpolated camera).
- HUD: StatusCard; minimap/hints default off; coin pill fits 4 digits.
- Codex sound pass (tools/build_sounds.py): sine/triangle effects, strongly low-passed noise, softer music; measured no >4 kHz harshness, no clicks. Explorer footsteps and hup removed; voices default off; web output latency 120 ms.
- Doors: Codex tower arches (open, locked, unlocked) and hillside paw-stone door that slides into the ground; crumble breaks into four tumbling pieces; dust and sparkle particles. Unused door/arch/sign images dropped (budget).
- World suite 87 checks. All suites pass.

## 2026-10-18 · Web sound fix, menu settings, menu shadows (0.4.9)

- Root cause: web export defaulted to Sample playback; with runtime Music/SFX buses the output was silent (measured 0.0 RMS). project.godot audio/general/default_playback_type.web=0 (Stream): measured 0.06-0.09 RMS on Chromium and WebKit (tools/check_web_audio.js).
- web/shell.html: navigator.audioSession playback, resume all audio contexts on tap, silent primer; Play now unlocks. Sound connects buttons that existed before it.
- Main menu Settings opens CareInterface settings; menu tests rewritten (54 checks). Soft radial menu shadows; version label bottom-left with outline. All suites pass.

## 2026-10-18 · Settings, cave parallax, smooth fall recovery (0.4.8)

- SaveStore.SETTINGS_SCHEMA drives validation; older settings files gain new keys at defaults. New: voices, music_volume, sfx_volume, show_minimap, show_hints, show_goal, place_names, stick_size, control_opacity, left_handed, gentle. Settings list in four sections with fitted captions and Reset; CareInterface mode "settings" opened from the main menu (All settings).
- Cave: four Codex parallax layers (cave_far 0.08, cave_back 0.20, cave_mid 0.45, cave_front 1.20) replace the tiled wall.
- Falls: safe point only on ground solid on both sides (raised bridge excluded); recover_from_fall fades once and returns; world test added (83 checks). All suites pass.

## 2026-10-18 · Music and sound, Sky Feather stays visible (0.4.7)

- tools/build_sounds.py synthesizes 5 music loops and 52 effects (WAV, imported as QOA; music loop_mode forward). Sound (scripts/systems/sound.gd): pooled effects, crossfading music, Music/SFX buses, every BaseButton taps automatically, silent when headless. Music preference with migration for older settings.
- Hooks: screens and rooms pick music; child jump/double/land/steps/hurt; Foxy react voices; world events; My Pet care actions and snoring; ball throw/catch/miss/bounce; shop buy/error; banners and cards.
- Sky Feather: empty stand (Codex) stays after collection, feather hovers then flies to the bag; cave sign has an 'after' text; ability card waits for the flight.
- All suites pass. Sounds verified by measurement and a windowed run only; not yet listened to on a device.

## 2026-10-18 · Drink and pet animations, harder Catch the Ball (0.4.6)

- pet-v2 drink and pet sets from a second Codex sheet (pixel2-raw.png, scale 0.7 to match); build_pet_anims reads several sheets. Old care-v1 actors-contact and water art removed from code and export. Child kneels for water too; Foxy stands farther away as it grows.
- BallGame: throw lands child.x + 185..445 by the aim bar; child walks 60..300; Foxy wanders (480 ± 70) while aiming; catch reach 24 (practice 60); aim speed 2.3; band() drives the ThrowMeter. Carry frames dropped for the normal run with the ball at the mouth.
- All suites pass.

## 2026-10-18 · Bridge slides out (0.4.5)

- Replaced the code-drawn drawbridge post and ropes (user: looked bad) with the bridge strip sliding out from the bank; strip() takes a texture phase shift so the planks travel with it.

## 2026-10-18 · Pixel Foxy animations in My Pet and fetch, crates in the bag, drawbridge, line fix (0.4.4)

- HomeArt draws pet-v2 frames (_pet_frame, scaled to the growth-stage height): eat (child kneels with idle frames), bathe (own tub, mid-room), sleep (curled, breathing in bed; wake stretch). Old foxy-sleep-v1 art dropped from the export (budget).
- Ball game: carry frames while Foxy brings the ball back (GrayboxActor.home_pose_flip); overlay ball hidden while carried.
- Crates: Use becomes Place only after Place a crate in the bag (MeadowWorld.placing).
- Terrain layer no longer repeats textures (edge bleed drew dark lines on scaled phone screens); tiling earth and cave ceiling moved to TerrainFill. Walls layer redraws with the camera.
- Drawbridge swings from a hinge with ropes (bounce on landing, ropes fade once down).
- All suites pass.

## 2026-10-18 · Critters per place, themed gates, next goal on the map, stick and jump fixes (0.4.3)

- TouchControls ignores emulated mouse events (DEVICE_ID_EMULATION); an emulated move could adopt the stick after a rebuild and its release never arrived.
- Explorer: the air jump is never cut by an early release; a puff of air marks it.
- Critters by kind (hedgehog, crab, frog hopping, bat and bee flying on a wave); Codex critters sheet (12 frames) sliced by build_meadow_kit. Tower bats, cave crab, river frog, forest bee.
- Edge exits draw a gate themed for the destination (gate_home, gate_meadow, gate_river; Codex gates sheet); arrow signs removed. Place-name ribbon on room entry.
- GameState.world_goal() drives the hint line and the map (bouncing star over the goal room, Next line under the title); the key step points to the Hidden Cave.
- Lever toggles the secret wall both ways. Birds use world positions.
- World suite 80 checks. All suites pass.

## 2026-10-18 · Bag keeps what you find, crates travel, tower safe steps (0.4.2)

- GameState: world_collect_crates (leaving a room returns placed crates except ones on a pressure plate), world_pick_food (apples/fish into the inventory), carrots count in quest_state.world (max 3, validated on load), world_add_carrot / world_use_carrot.
- World bag: Found on the way row (Jump carrot tap to use, Sky Feather, Golden key); clearer Lost Picnic steps. Food short name Carrot.
- Sky Feather shrine hidden once learned. Old Tower: three 36 px steps right of the thorns plus a sign. HUD hearts follow the room chip when its width changes.
- World suite 80 checks. All suites pass.

## 2026-10-18 · Catch the Ball full screen, Foxy carries the ball, one Foxy style (0.4.1)

- Catch the Ball: full-screen garden (wide screens trim sky only), HUD like the adventure (My Pet, score plank, settings), A49 aim bar with the sun ball as marker, round Throw button. Landscape only: portrait shows the shared turn card and pauses.
- Fetch: the ball flies into Foxy's mouth on a catch (only for throws in reach), Foxy runs back carrying it, drops it at the child's feet with a bounce.
- Yellow sun ball everywhere (A52). Foxy animation candidates redrawn from the in-game pixel Foxy on one sheet (tools/build_pet_anims.py), awaiting integration.
- Turn card shared by adventure and Catch the Ball; the phone's screen turns to a wide upright picture when the phone lies sideways.
- Mobile suite updated for the landscape-only ball game. All suites pass.

## 2026-10-18 · Foods, shop, loading screen, bag, map route and clouds, tower interior, animals (0.4.0)

- Foods (data/foods.json): six foods with price, fullness, happiness, energy; likes and dislikes. Feed opens a food picker; shop sections for foods, toys and things.
- Loading screen: progress bar, then Play now and What's new (version and notes inside).
- World bag on one screen: snack tiles close the bag and Foxy eats in the world with a food bubble; robot part slots; crates; quest line.
- Map: dotted route between connected places (gold once visited); unexplored places under soft layered drifting clouds (shadowed underside, sunlit top).
- Old Tower interior: one continuous Codex stone wall (windows, torches, ivy) tiled behind the platforms; the old square columns are gone.
- Ambient animals: birds, butterflies, bunny, squirrel, duckling standing on the ground. Crank lowers and raises the bridge. Settings: Start Green Meadows again (two-tap confirm).
- Web image budget: menu meadow and picnic finish backgrounds resized to 1280x720 (222.5 to under 220 MiB). All 15 suites pass.

## 2026-10-18 · Signs, pickups, keys, Foxy follow, real tower, clear finish (0.3.9 candidate)

- Signs: small hint bulb centred on the measured board (no text on the sign); full hint on Read.
- Pickups: apples and fish snacks feed Foxy (food + energy), regrowing magic carrots give one big jump, a golden key in the Hidden Cave unlocks the Old Tower's top door (padlock shown; button says Locked / Open), a clue note at River Crossing points to the windmill lever.
- Foxy hops to the child when left far behind or far below for over a second (tower lift and crumbling steps).
- Old Tower exterior: Codex round ivy tower replaces the bordered square block at River Crossing and Forest Gate; its own doorway is the exit (no second door drawn).
- Forest Gate thorns now say Mystic Forest opens in a future adventure; one-time "Green Meadows complete!" card when all robot parts and the picnic are done.
- World suite 73 checks (key reachable without Double Jump, apple, carrot, locked door, Foxy catch-up). All suites pass.

## 2026-10-18 · A51 pet condition and growth in the adventure (0.3.8 candidate)

- Foxy's adventure size follows the growth stage (baby 16, child 22, teen 27, adult 31 world px next to the 42 px child).
- A very hungry, very tired or sleeping Foxy stays home: the game opens My Pet with a card saying why and how to fix it (persists across re-layout).
- Exploring: Foxy gets hungrier (1/min) and more tired (1.4/min). Below 15: Foxy won't dig and Double Jump stops working until fed or rested. Snack button in the world bag (Berry bowl); lighting a lantern gives a rest (+20 energy).
- Older Foxy and stronger bond smell treasure from farther (120-230 px + bond) and dig faster.
- HUD Foxy chip: face plus food and energy bars.
- World suite 66 checks. All suites pass.

## 2026-10-18 · Turn card, minimap, The Lost Picnic quest (0.3.7 candidate)

- Turn-your-phone card fills most of the screen with 28 px padding; phone animation sized to the space; buttons share one text size.
- Minimap shows a zoomed window (~3 screens) around the child: room-coloured sky and ground, the visible area framed, an orange "you" dot, door and chest icons; small rooms centred; everything clipped inside the frame.
- The Lost Picnic (V1 first adventure) is now a quest inside Green Meadows: talk to Moss the bunny in Meadow Fields, take the basket from the top of the Old Tower, bring it back for a picnic (25 coins, a Berry bowl, bond; once). Quest stage in the bag and goal line. World suite 57 checks.

## 2026-10-18 · P1 play-through fixes (0.3.6 candidate)

- Joystick 20% bigger, reacts slightly outside its ring, and re-presses its direction every frame so a room change can no longer leave it pressing nothing (cause of the "stuck" stick). No-steal rule kept.
- Out of hearts: stays in the same room (lit lantern or entry point) with a short fade; never jumps rooms.
- Cave: stray glow circles removed. Lanterns: steady soft glow with a slight flicker instead of a pulsing ring.
- Signs show a short painted word (TIP, RIVER, CLIMB...). First crate shows an explanation card; Place shows a see-through crate where it will go. Bouncing marker over doors, levers, chests and shrine when in reach.
- Start/Continue lead into Green Meadows; the old picnic/windmill practice levels are retired from the Adventures map (code kept).
- River Crossing bridge raised until you turn the crank wheel (V1 mechanic brought back). Wider pit with a raft in Meadow Fields; two hedgehogs at the Forest Gate.
- Old Tower rebuilt: stone facade around its River Crossing entrance, crumbling steps, a moving lift, a thorn bed, a hedgehog; wide ledges repeat instead of stretching; camera keeps the child in the lower middle. The top exit leads onto a high ledge at the Forest Gate with the tower behind you.
- Phones: page fills the whole screen (viewport-fit=cover); notch/home-bar insets measured in the page and passed to the game for button placement. Turn-your-phone screen shows a Codex pixel phone tilting sideways.
- Tests updated for Continue into the world; crank tests added. All suites pass.

## 2026-10-18 · P1 pet puzzles, challenge room, living world, Menu sign, minimap (0.3.5 candidate)

- Pet puzzle: Foxy digs up a lever by the windmill; pulling it opens a secret stone wall into the Windmill Cellar (durable world flags).
- Challenge room (optional): crumbling stones and a log raft over a pit; a pressure plate opens a stone gate only while weighted, so a crate from the bag must hold it; prize: airplane propeller toy part (first part for a second toy).
- Living world: moving water shimmer and sparkles, drifting leaves in the meadows, fireflies and light beams in the cave (all off with reduced motion).
- Minimap under the room name (room shape, you, doors, hidden chests); tapping it opens the area map. Cellar on the painted map.
- Menu button is a hanging wooden sign (Codex), matching the signs in the world.
- Robot counts ignore non-robot parts. World suite 49 checks. All suites pass.

## 2026-10-18 · P1 visible connections, area map, kid-friendly challenge (0.3.3 candidate)

- Rooms longer with landmarks (turning windmill). Every connection visible: path arches with arrow signs at room edges, cave mouths, a stone tower entrance; River Crossing reaches the Old Tower by its door and the Forest Gate is only reached by climbing the tower to its top door. Room changes fade with a pause instead of snapping.
- Challenge: 3 hearts; thorns, hedgehog critters (hop on them to make them curl up), falls and water each cost one heart with a short safe moment; at zero you return to the last lantern with hearts refilled and keep everything. Lantern posts light up when touched (saved) and refill hearts. Moving log raft over the second stream; crumbling stone in the cave.
- Area map from the HUD map button: visited rooms, unvisited as "?", where you are (fox medal), chests left, locked ways, parts and lanterns.
- Codex art: path arch, tower entrance, windmill body + sails, lanterns, arrow sign, thorns, hedgehog (2 walk frames + curled), log raft, crumbling stone, heart.
- World suite 33 -> 44 checks (tower climb without Double Jump, lantern return keeps items, stomp, crumble, map). All suites pass.

## 2026-10-18 · P1 context actions, Foxy digging, crates (0.3.2 candidate)

- Use button changes to Enter, Open, Read, Pick up, Place or Touch with its own Codex icon; Find becomes Dig where Foxy smells something (dirt mound with outlined gold sparkles when Foxy is near).
- Foxy digs up crates (bag holds up to 3) and coins once per spot; crates are placed in front of the child, are solid, stack, and can be picked up again; saved per room and validated.
- New River Crossing ledge and robot body part reachable by stacking a crate; robot is now 4 parts. Bag button and screen in the world (crate count badge, parts found). Double Jump named and explained with a one-time card.
- World suite 23 -> 33 checks. All suites pass.

## 2026-10-18 · A50 world review fixes (0.3.1 candidate)

- User played 0.3.0 on the phone (screens in feedback/2026-10-18-world-review). Fixed now: dark horizontal lines across the parallax (layers were drawn with texture repeat, so each strip's top sampled its opaque bottom row); vertical joints and dark rectangle edges in the ground (world-aligned tiling, cross-faded seamless earth/strip/wall tiles); blurry floating islands and structure pieces (no longer downscaled); thin ledges are one-way so you can jump up through them; the bridge sat 4 px above the banks and blocked walking; cave vines now hang from a rock ceiling with a crystal rim; cave and tower get layered interior parallax (far/near walls, crystal glow; tower arches show the sky); cave/tower floors use rock fill; Foxy no longer floats in the dig pose (poses sit on their lowest opaque row); Find/Use/Jump icon and label on one fixed grid inside the ring; HUD coin pill shows only the number; subtitles use the game font.
- A strip-drawing loop could hang when a tile edge fell on a float rounding boundary; guarded (caught by the world suite timing out).
- Open for the next pass (level design): Castlevania-style connected rooms with visible passages and doors, a map, real challenge, usable bag/crates, animated water and living scenery, a nicer Menu button, sign clues.

## 2026-10-18 · A50 V2 connected Green Meadows (0.3.0 candidate)

- V2 GDD archived and extracted; concept images saved under current/v2-gdd.
- Five connected rooms with seven-layer parallax, kit terrain, chests with robot toy parts, Foxy Boost shrine and ability-gated revisits, locked Vine Climb gate; door and edge transitions; progress saved in quest_state.world.
- New tools: `tools/build_parallax_layers.py` (best-match seam cut), `tools/build_meadow_kit.py` (slice + automatic outline trim + prop sizing), `tools/capture_world.gd` (run with `--always-on-top`; macOS otherwise stops redrawing a covered window and captures go stale).
- New suite `tests/test_world.gd` (23 checks: data, reachability with/without boost, coins once, edge/door transitions, shrine, durable chest/ability, validation, boost physics, relaunch). Found and fixed: the edge clamp kept the child 2 px short of the exit trigger.
- Find/Use/Jump use new clearer icons (magnifier with paw, finger pressing a button, arrow with dust).
- All 16 suites pass; local WebKit iPhone load peak 615 MB.

## 2026-10-18 · A49 approved UI kit on every screen (0.2.7 candidate)

- User approved the Codex UI redesign and asked for a complete kit for all screens, our own 2D characters kept (Codex-drawn boy/fox not used), concepts organised so only the new ones are used, and no stretched buttons.
- Concepts: `assets/concepts/current/` (A49 kit, latest per screen, A44 home) vs `archive/` (superseded, never a reference); 30 referencing files updated; AGENTS.md rule; README in the folder.
- Kit: four Codex production sheets -> 40 pieces + `kit.json` (`tools/build_ui_kit.py`). `scripts/ui/kit_style.gd` never distorts a piece: three-slice ends scale with height only and length comes from a uniform centre slice; nine-slice corners keep shape; round pieces keep aspect. Meters never draw narrower than their height.
- Roles: carved panel only for outer containers; gold/cream pills for buttons (pressed/disabled pieces); round icon buttons (Menu icon only, no label); kit care tiles; frameless row strips (gold total); fitted tag pills; wallet pill; HUD planks with stud-safe insets; kit switch and round-arrow selector; round wooden action buttons that turn gold while held; kit joystick; map medallions (done/current with our fox in a ring and flag/open/locked) on a stone path; Foxy name badge with medallion. Portrait pause card sits inside its panel without a second frame.
- Icons: `tools/build_icon_sheets.py` isolates each icon and pads it (no neighbouring slivers).
- Removed the old drawn wood frame, painted 9-slice style and their art from the web package.
- Capture tool no longer waits forever when macOS stops redrawing a hidden window; captures default to test-results/. Earlier default overwrote the saved before-images; restored from git.
- All 14 suites pass (layout check at four sizes).

## 2026-10-18 · A48 crisp frames, trimmed icons, automatic layout check (0.2.7 candidate)

- User close-ups: "Run coins" clipped, coin/number misaligned, basket vs gear sizes differ, busy paw ornaments, frames sloppy when small.
- Frames: `scripts/ui/wood_frame.gd` draws the wooden frame in layers (outline, bevelled wood, cream/gold face, brass rivets) at any size; replaces the downscaled painted 9-slice. Weight by role (thin/panel/board).
- Icons: `assets/ui/concept-v1/icon-bounds.json` crops every concept icon/glyph to its visible pixels; icon-only squares fill 58%, tiles 56% of height. Flat tan `paw-ornament.png` for the drawer title.
- Meet Foxy and main-menu wallet moved onto the shared layout; Meet Foxy header in one row; short-phone touch heights via `PetUI.touch_height`.
- Scroll bars hidden in cards (rows were cut by the bar). Subtitles at least 13 pt and dropped when they do not fit.
- New suite `tests/test_ui_layout.gd` (80 checks): every screen at 390x844, 844x390, 768x1024, 1280x720 - no clipped text, icon/text on one centre line, centred tiles, content inside frames and scroll areas, one text size per row. Verified it fails on the old scroll-bar overlap. Known exception: landscape details is still the fixed V06 reference layout.
- All 14 suites pass.

## 2026-10-18 · A48 component system (0.2.7 candidate)

- Audit tool `tools/audit_ui_components.gd` inventories every framed control (phone: 15 heights, 14 text sizes, three square-button looks before this pass).
- Implemented A48 roles/weights/glyph squares/tags/header/unify; native rounded meters; centred switch; memory row; concept drawer header; no blur behind Care and Menu. Frames-v2 and glyph sheet added to the web export (the frames were missing from it).
- Tests: new sharp-overlay checks (care 45). All 13 suites pass.

## 2026-10-18 · A47 alignment pass (0.2.7 candidate)

- User: buttons look misaligned and stretched (Find/Use/Jump icons, menu icon/text), only Settings looked right.
- Causes: rivets baked into 9-slice art (stretched, collided with labels), per-screen hand-placed icon/text offsets, Godot icon+text centring differing by text length, odd pixel sizes.
- Fix: `tools/build_clean_frames.py` derives rivet-free cream/gold frames from the approved wallet art and one rivet sprite; `illustrated_style` draws rivets at a fixed size/inset on frames >=110x44 only. `PetUI.compose/arrange` is the single content layout (row, tile, icon, left; optional subtitle shown only when it fits inside the 9 px border; even sizes for exact centring). Applied to CareArt buttons, main menu, care tiles, nav tabs, HUD chips and tiles, wallet, chips, reward rows, details rows. Landscape menu Games/Settings enlarged to >=48 px on phones.
- Tests: paths updated to Content/Symbol; coin badge checks containment instead of a fixed 40 px. All 13 suites pass; captures in test-results/gap-v10/.

## 2026-10-18 · A47 0.2.7 candidate: first visual pass toward the concepts

- Gap audit: all nine screens at four sizes plus full-level strips. Biggest gaps: flat repeating boulder ground and empty mid-ground, empty results card, plain pause list, bare map, small desktop/tablet UI.
- Layout scale: native screens now divide window pixels by the screen scale on web/mobile and cap landscape at 600 points tall / tablet portrait at 540 wide.
- Rebuilt V07 map, V08 pause/settings (toggles, steppers, Paused ribbon, compact phone-landscape card), V09 results (reward rows, memory row, portrait celebration crop, compact summary), V02 adventure HUD (level/coins/bag/settings/goal chips, icon tiles; slimmer bar under 450 points).
- World: Codex bank texture anchored per contour (replaces rock-material-v2), ConceptScenery mid and front layers in both adventures.
- Assets (Codex image generation, prompts/sources kept): concept icon sheet, three world cards, bank, scenery kit. Old boulder texture removed from the web export; image budget test passes.
- Tests updated to concept wording/layout (completion title, fully on-screen result card, icon-only Bag found by tooltip, bank material). All 13 suites pass.
- Open: physical phones, user visual review, level layout depth, framing foreground, home/menu/adoption/details pass, Windmill "Crates [E]" label.

## 2026-10-18 · A47 0.2.6 candidate: root cause of phone loading crash

- User: 0.2.5 still does not load on phones (any browser); visuals far from the concepts. Loading first, then rebuild screens to the concepts.
- Reproduced with Playwright WebKit (Safari engine), iPhone 13 viewport, sampling the page process memory: 0.2.5 peaks 1.92 GB, 0.2.2 2.08 GB, 0.1.1 (loaded on the phone) 1.55 GB; an empty Godot 4.7.2 web project 0.56 GB. Bisected: the jump happens when a `Uint8Array` is passed to `engine.preloadFile`; the engine indexes `config.fileSizes[file]`, converting the 41 MB view into a string key. Passing the `ArrayBuffer` keeps the peak at ~0.7 GB.
- Fix: shell streams parts into one `ArrayBuffer` and hands over `pack.buffer`; per-part size/SHA-256 checks kept. New `tools/profile_web_memory.js` (WebKit, 1 GB limit) and a `test_web` guard.
- 0.2.6 local: peaks 606/705/713 MB across three runs, menu renders, Start opens adoption; corrupted part shows "The download was incomplete" with Try again. Physical phone still pending.
- Published 0.2.6 (tag v0.2.6): hosted bytes verified; hosted WebKit load peak 706 MB, menu reached.

## 2026-10-17 · 0.2.5 candidate: phone loading memory

- Hosted 0.2.4 still closes on the user's phone (all browsers); the remembered step was "Checking the download": the page hashed the whole 42 MB pack in one call (the browser copies it) right after the engine started, and the engine then copied the pack again into its filesystem.
- Parts now download one at a time and are verified by per-part SHA-256 as they arrive; `tools/build_web.py` records part hashes and applies a guarded adapter so the engine filesystem owns the downloaded pack instead of copying it. Stage renamed "Handing the game to the engine".
- All checks pass. Emulated iPhone 13: loads, fits, tap works; a corrupted part shows "The download was incomplete" with Try again. Physical phone still pending.

## 2026-10-17 · A46 0.2.4 candidate: phone memory and screen fit

- User: hosted 0.2.3 crashes on phones (Chrome and Safari) during "Downloading the game"; desktop works. Portrait on the phone does not fit the screen (bottom cut off). No earlier release was tested on a physical phone.
- Measured: every source image decodes to about 6 MB; menu held 100 MB of images, home 176 MB, and adventure art stayed resident (menu after play 192 MB). Engine is 37.7 MB WebAssembly and the pack 42.6 MB.
- All 40 image loads go through `ArtTexture`. A coordinate-coded probe measured actual on-screen scale at 4K desktop, large phone and tablet; only seven images are drawn smaller than their source (menu icons, coin, home controls, adventure backdrop) and now ship as runtime copies reporting source size (42 → 3.2 MiB decoded). Large backgrounds/actor sheets are drawn at or above source size on 4K/tablet and stay unchanged. Adventure art caches release on screen change. Native image memory: menu 100 → 62 MB, home 176 → 126 MB, fetch 168 → 86 MB, menu after play 192 → 76 MB. 4K before/after captures: changed regions differ about 0.5/255; other differences are animation timing.
- Loading page: engine prepared before downloading the pack, parts written into one buffer, last startup step remembered across a crash. Canvas sized to the visible viewport (resize policy 0) and refitted after rotation, page scroll locked.
- Fixed: the adventure HUD's first layout released input held while the adventure opened (exposed by the slower first adventure frame).
- First Mac publish attempt failed its checks: the new runtime copies had never been imported there (publish runs checks before anything imports), so screens failed to build. `tools/run_checks.py` now imports assets first, and `ArtTexture` falls back to the source image if a copy is unavailable. Reproduced by removing imported copies; all suites then pass.
- 467 checks across 13 suites pass. Emulated iPhone 13 in Chromium: load, portrait/landscape/portrait fit, tap, crash-step message. Physical phones not tested; home/adventure image memory remains above the 80 MB target.

## 2026-10-17 · 0.2.3 candidate: named startup steps and stall notice

- User reports the browser loading screen still sticks; the cause on their device is not yet known. Prepared 0.2.3 (version, project version and release notes) so the hosted page reports where it stops.
- Loading screen names each step and, after 45 seconds without progress, says which step stalled and shows Try again. Non-secure addresses now get a clear message. Packaged load, pack checksum, WASM transport and single-tab lock unchanged.
- 461 checks across 13 suites pass (release prepare). Local Chromium: menu reached; a never-answered pack part showed the named stall with Try again; second-tab block/retry unchanged. Not yet published: publishing needs the user's Cloudflare/GitHub login from `main`.

## 2026-10-17 · Web loading screen startup fallback

- Reproduced a stuck loading screen: the custom shell always required `release.json`/`game-pack.json`, which only `tools/build_web.py` produces. Godot editor Run in Browser and plain `--export-release` output stayed at 0% with Download failed (404); opening `index.html` from disk stayed with Failed to fetch.
- Shell now boots the stock `index.pck`/`index.wasm` when no release package is present and tells file:// users to run `python3 tools/serve_web.py`. Packaged/hosted path, chunked pack checksum, WASM transport and the single-tab Web Lock are unchanged.
- 461 checks across 13 suites pass on Linux Godot 4.7.2. Playwright Chromium at 390×844: packaged and plain exports reach the main menu, file:// shows the instruction, second tab blocks and retries after owner close. Not yet released; Safari/Firefox, phones and the hosted URL not re-tested.

## 2026-10-17 · A45 single active browser session

- Hosted0.2.1 care→Details→reload retained5XP after closing a stale0.1.1 test tab. Found concurrent old/new browser engines can overwrite the origin's profile.0.2.2 claims an exclusive browser-managed Web Lock before engine initialization; a second tab displays Close the other tab / Try again and never mounts the save filesystem. Owner close/reload/crash releases the lock automatically. Save writer, transactions and schema unchanged. Hosted0.2.2 confirms second-tab block, owner-close/retry, retained5XP after reload, portrait/landscape Care drawer and corrected growth text. No engine errors; expected blocked-tab notice captured.461 checks pass again; hosted source/transport/pack hashes match. Receipt: `releases/v0.2.2.json`.

## 2026-10-17 · Hosted0.2.0 review and0.2.1 font correction

-0.2.0 source69607ce published with immutable tag/ZIP and hosted byte verification. Actual public390×844 menu, quiet home, Care/Water and Menu/Details work with no runtime errors; receipt retained. Review found unsupported arrow glyphs in compact Growth Journey; replaced with plain age sentences in0.2.1. This patch preserves the selected A44 flow, assets and save format.

## 2026-10-17 · A44 selected quiet room → care drawer

- User selects proposals1 and2 as consecutive states. Quiet home keeps the canonical wallet, Menu and Care. Care opens six generous tiles; Menu opens eight secondary destinations. Detailed stats move into Details. Native icon/text sizing prevents oversized symbols and cramped button captions.
- Water now uses a blue drinking bowl, distinct from the Clean bathtub. Choosing care closes the drawer and restores the room camera before approach/acting/durable completion. Four new kneeling-child and baby-Foxy idle/contact poses remain animation candidates; older growth identity and save rules are preserved.
- Portrait drawer opens below the pair, landscape drawer beside them. Whole-room camera adjustment preserves actor/furniture grounding; modal blur uses that same live world. Furniture hit regions and toy positions follow responsive room coordinates.
-461 checks across13 suites pass, including real pointer Care/Water/Menu navigation, six safe care targets, orientation while drawer open, same-run adventure rotation, failed/cancelled care, slow disk, duplicate rewards and shutdown. Actual native captures at five sizes retained. Nine headed Mac samples: means8.33–8.79ms, p99≤17.44ms, no wall frames>25ms;97 nodes stable over12 modal cycles. Local Web quiet→Care→Water and in-place portrait/landscape resize verified. These are not physical-phone certification or final art approval.
- Source references, prompts, regions, pivots and production limits saved in `home-flow-production.json`, `home-flow-prompts.json` and asset register.0.2.0 candidate resumes versioned publishing after selected-flow validation; deployed receipt follows publication. No phase outcome marked complete; original GDD untouched.

## 2026-10-16 · A41–A43 internal care candidate; home redesign required

- Added native home/care, details, map, pause/settings, shop/decorate/collection, fetch and result flows on the existing GameState. Serving/wash/water/rest have approach/acting/completion; effects and owned meals publish only after the durable transaction. Leaving unfinished care cancels without spending a meal.
- Adventures now request landscape on a portrait phone, pause and release held input, and resume the same run after rotation. Native Bag/settings respect the orientation guard. Graybox portrait diagnostics remain available for prior physics/input coverage.
- A42 replaces the concept's alternate room background with the actual live room. Two half-resolution Gaussian passes blur only the modal backdrop; the sharp portrait samples that same room. V06 uses measured reference geometry and native labels/meters/actions. The existing room instance is retained across its menus; washing uses its actual tub, rather than a duplicate foreground tub.
-449 functional checks across13 suites pass, including existing slow-disk/reward/shutdown boundaries and34 new care/orientation/modal checks. Six headed Mac samples at390×844,844×390 and1280×720 show means8.33–8.56ms, p99 up to16.77ms and no wall frames above25ms;97 nodes stable across12 modal cycles. These are desktop samples, not device or art acceptance.
- User explicitly rejects the current crowded home and button/icon proportions in A43. The0.2.0 local candidate was prepared but publishing is STOPPED; public0.1.1 remains unchanged. New scoped native captures, critique and redesign brief are retained in `feedback/2026-10-16-home-crowding/`. Three image-based proposals will be reviewed before building the replacement. No phase outcome marked complete.
- Prompts, actual actor regions/pivots, sources and statuses are in `care-production.json`, `care-prompts.json` and the asset register. Mature art/full petting/audio, physical phones, final shared-control sizing and visual approval remain open. Original GDD unchanged.

# PETOPIA workspace change log

## 2026-10-16 · A40 hosted transport correction

-0.1.0 public boot failed because Cloudflare stripped the gzip header override. Preserved its original immutable tag/archive and prepared0.1.1 with explicit browser decompression. Added guarded pinned-engine transport adapter and actual hosted version/commit/WASM/PCK validation before release announcement.
-0.1.1 Cloudflare preview reaches the menu at390x844 without engine errors. All415 Godot checks passed again during publication; no gameplay/save schema or art quality changes. Native phone/desktop captures refreshed. Live stable HTTPS URL also passed Start/adoption/held joystick/coin/reload/Continue with zero runtime errors. Actual browser JPEG and source-linked receipt retained in `docs/releases/v0.1.1.json`. Stable-alias propagation briefly delayed automated verification; successful verification preceded GitHub release announcement. Added a bounded15-second propagation retry for later releases. Physical phone performance/art review remain open.


## 2026-10-16 · A39 mobile Web and versioned release

- Prepared0.1.0 with a dedicated private GitHub repository and Cloudflare Pages project. Added checked build/publish scripts, immutable version tags, release notes, web ZIP/checksums and source-linked release metadata; deployment receipt follows actual publish.
- Round captured wood/cream/blue controller replaces movement rectangles; independent shared Jump/Use/Find controls preserve simultaneous input and saved sizing. New asset provenance retained. Native phone/desktop captures use isolated profiles.
- Threadless Web writer coalesces idle saves and preserves transaction order; native worker unchanged. All415 checks pass across12 suites. Local actual browser adoption, movement/coin and reload/Continue pass without runtime errors. Physical devices and final art remain open.


## 2026-10-16 · Age-consistent room proportions

- A38: user asks to verify Foxy/child proportions by age. Audit found only baby/non-baby standing sizes, an age-invariant sleeping baby baked into furniture and static age captions. These were incomplete; do not describe the previous room as correct across all ages.
- Room presentation now uses four gradual target heights:24/30/34/38 against the explorer's42 before their shared2.7 room scale (about57/71/81/90%). Baby/child retain established sizes; teen/adult numerical targets are provisional visual choices, not values specified by the GDD. Original0/7/30/60-day age thresholds remain.
- Added independent baby/child curled-sleep sprites with measured foot pivots. Only Foxy grows inside the same empty bed and front bolster. Teen/adult reuse the child identity provisionally in both poses; their distinct anatomy/animation remains pending. Live native/portrait age captions track actual growth. No change to adventure physics, save schema or writer.
- Relevant126 checks pass:30 home_growth,30 adoption,27 scenes and39 mobile.401 aggregate checks across11 suites; other seven suite results retained from A36/A37. Tests cover real age thresholds, actual room sprite heights, fixed child/furniture, sleep fit, resize, wake and adult sleep after restart. Sixteen actual age/pose/viewport comparison frames inspected; prior adoption/home captures refreshed with the independent sleep sprite.
- Built-in image_gen source, prompt, measured regions and pivots are retained in `home-growth-production.json`, `home-growth-prompts.json` and the asset register. Review: `home-growth-review.html`. Exact ratios, mature identities and final visual/physical-device review remain open.

## 2026-10-16 · Native adoption and corrected room/bed presence

- A36: continued from the user-accepted A35 menu correction into V05. Added a native illustrated Meet Foxy screen with actual20-character name entry, canonical wallet, shared cream/gold buttons, Back, existing Settings and blocked-save recovery. Enter focuses confirmation; a durable adoption must succeed before entering the previously requested destination. Resize/settings retain typed names; Back creates no profile.
- Room and front-facing Foxy sources were generated with built-in image_gen from approved V05/V03 references. Existing four-pose child/Foxy interaction and pixel contact are reused. Furniture is separated from the room plate rather than leaving an immovable baked bed. Original sources, prompts, regions, pivots and statuses are retained in `adoption-production.json` and the asset register.
- A37: user rejected small room actors, the lowered bed and the phone pair on the window sill. Enlarged home actors to reference room proportions; moved the independent bed to the right beside them, above the action row. An adaptive upper-wall crop places the phone window above the pair's fixed floor contact across tall/short phones. User references retained under `docs/feedback/2026-10-16-adoption-home/`.
- Care feedback now stays on the foreground floor below actors/bed instead of covering them in portrait. Rest/Wake uses two authored furniture states: empty bed or Foxy curled inside the mattress, without a duplicate standing pet. The existing care transaction persists sleep across restart. These states do not complete stage-specific sleep/walk-in clips; remaining native V03 care layout and feed/wash production are open.
- All ten suites run in batches this iteration:371 checks pass, including30 adoption/room checks. Adoption/scenes/art_polish rerun after final room correction. Existing slow-disk, duplicate-reward and shutdown checks remain. Six native adoption and five home/bed views captured, with desktop, portrait, short phone, tablet, notch and Settings. Physical mobile keyboard/device, child playtests and final visual review remain open. No save schema/writer or terrain/gameplay changes.

## 2026-10-16 · Start wording and uniform action alignment

- A35: fresh menu action now reads Start. Its font matches the other actions (24px portrait,34px desktop) and all four frames retain identical dimensions. Returning saves still show Continue; adoption/resume behavior is unchanged.
- Symbols are centered after final font/frame sizing. Resize refreshes their feedback from the new center; hover/press scale around that center without vertical lifting. This addresses the displaced tablet play icon.
- Relevant54 menu checks pass, adding equal frame/font and symbol-center checks at five sizes. Existing save/adoption/resume checks remain included. Other eight suites retain287 passing A33 results. Native static/motion captures refreshed with isolated profiles; previous A34 frames retained. Final visual/device review remains open.

## 2026-10-16 · Collection typography and Settings alignment

- A34: separated Collection and Coming later into a centered vertical layout with explicit spacing. The subtitle uses smaller regular type; the native action name remains available without duplicate visible text.
- Settings gear and label now share one centered horizontal layout. The gear stays aligned during hover/press while the button retains gold selection and native input.
- Relevant49 menu checks pass, including five sizes, line separation, icon/text alignment and existing durable preferences/resume checks. Seven actual Godot frames and120-frame portrait motion sample refreshed; desktop/portrait inspected. Other eight suites retain287 passing A33 checks; they were not rerun for this layout-only revision.
- Prior phone frame retained under `docs/screenshots/menu-before-a34/`. No new raster assets, gameplay or save-schema changes. User visual approval and physical-device review remain open.

## 2026-10-16 · Pixel menu, taller compact buttons and petting motion

- A33 supersedes the too-smooth icon set and the oversized phone composition. Added reference-derived pixel icons, smaller phone icons/text/gear, taller72/76px phone buttons with282px width,352x104 desktop actions and a larger child/Foxy area. Fixed resize sizing order so old font minima cannot leave buttons stretched.
- User-requested gold selection/focus/hover now sits over cream resting buttons. Small icon lift/press feedback preserves real native hitboxes/labels and respects saved reduced motion. Pointer moves focus so the selected action stays clear. Returning-profile capture shows Continue; fresh starts retain explicit wording.
- Added four authored menu petting/reaction poses, repaired sheet gutters, common canvas and measured fixed feet; sparse pixel contact shadows stay on the meadow. Reduced motion freezes decoration. This is a menu loop, not a completed gameplay animation set or new character approval.
- All331 checks pass across nine suites, including44 menu checks for pose progression, stationary contact, motion preference, text/icon fit, native navigation and save boundaries. Seven static frames and a120-frame headed portrait motion sample inspected; prior captures retained. Fixed-simulation video is not a performance/device claim.
- Active new sources/prompts/regions/pivots: `assets/ui/menu-v3/`, `docs/menu-v3-production.json`. Video: `docs/screenshots/menu-motion.mp4`; capture: `tools/capture_menu_motion.gd`. Progress, validation and before/after review synchronized. Whole-menu/game visual gates remain open.

## 2026-10-16 · V04 proportions, icons, wallet and Settings fidelity

- A32 addresses explicit comparison feedback: shortened/taller352x98 desktop action buttons replace425x76; native rounded type and aligned larger icons replace flat primitive symbols. Collection gets a separate title/caption. A31 cream choice retained.
- Added five full-resolution reference-derived illustrated icons and an empty wood/cream wallet frame. Canonical coin and actual balance remain separate native elements. Settings now has the blue gear tile and reference-like lower-right placement.
- Removed360x90 intermediate button rasterization. Full-density source regions render with independent logical corners and linear filtering, keeping detail on desktop/tablet and preserving frame proportions. Lilita One font and OFL license/source metadata bundled.
- All323 checks across nine suites pass, including36 menu navigation/safe-area/persistence checks. Seven headed menu frames inspected; prior frames retained for explicit before/after comparison. No gameplay, save schema or reward changes; physical-device and final user visual review stay open.
- Assets/prompts/regions/pivots: `assets/ui/menu-v2/`, `docs/menu-v2-production.json`, asset register. User references, verification/progress and review dashboard synchronized.

## 2026-10-16 · User-selected cream menu buttons

- A31: adopted the user's second button reference for all illustrated menu actions, including Start/Continue and Settings Done. Reused the existing cream face/simple wood frame; removed the gold face from normal/hover/pressed menu states. Native focus, locked state, actions and layout retained.
- Relevant36 menu checks pass; seven actual desktop/portrait/tablet/Settings captures refreshed and inspected. Prior full-suite323 checks retained as earlier functional evidence. No persistence or gameplay changes, new generated assets or overall art approval.
- User references, asset status, verification, progress and menu review synchronized.

## 2026-10-16 · Native V04 main menu

- Added the first production-menu candidate: reference-derived multicolor logo, meadow, friendly child/Foxy pair and empty cream/gold button textures, with real native controls/icons and saved wallet. Reusable PetUI nine-slice styling keeps text and focus interactive; corrected white focused-button text to navy.
- Start adventure goes through existing adoption into The Lost Picnic. Continue resumes exact saved level/run/checkpoint or returns to My Pet. Practice works without adoption; hub and Pause return to Main menu. Collection is explicitly Coming later. Existing river, terrain, mission rewards and tool ownership retained.
- Native portrait/landscape layout respects safe insets, retains >=48px targets and avoids overlapping controls/friends on short phones/tablets. Settings saves reduced motion and touch presets before adoption and inherits them into the profile; existing profiles use the ordered durable transaction. Routine save queue and schema remain unchanged.
- Full runner:323 checks across nine suites pass, including36 menu checks and all slow-disk, duplicate-reward and shutdown coverage. Seven headed Godot captures inspected, including short phone, tablet, notch, Settings and returning profile. No physical-device or final art approval claim.
- Sources and prompts: `assets/ui/menu-v1/`, `docs/menu-production.json`, asset register. Review: `docs/menu-review.html`; captures via `tools/capture_main_menu.gd`, review builder `tools/build_menu_review.py`. Progress and verification synchronized. Remaining V05–V09 production UI and final art/audio/device gates stay open.

## 2026-10-16 · Animated contact foam at bridge piles

- Addressed A29: white/cyan broken crests wrap each pile at the water surface, with back/foreground separation, fading wakes and small edge splashes. Deterministic native Godot effect uses the existing meadow clock and the lower-pool depth of the right pile. Original river/rocks, bridge geometry, collision and saved state retained.
- Relevant art suite:52 checks pass. Sixty actual rendered motion frames retained and encoded at30fps; contact-region pixel changes verified at all three piles. Actual desktop and portrait views inspected.
- Headed390x844 Mac sample:1,569 frames after warmup, mean8.578ms,p9917.335ms,worst22.318ms,zero>25ms;126 nodes stable over twelve scene cycles. Existing editor/game/background processes remained. Physical devices and final visual acceptance remain open.

## 2026-10-16 · Right bridge pile reaches the lower pool

- Addressed A28: extended the waterfall-side pile32world pixels so it enters the lower pool instead of stopping mid-fall. Other piles, beam/deck positions and original river artwork retained. Physics and save schema unchanged.
- Relevant art suite:52 checks pass. Captured and inspected actual desktop/portrait views with `tools/capture_bridge_depth.gd`; before/after files preserved. No final art approval or new device/performance claim.

## 2026-10-16 · Free tools, clear interactions and story results (review candidate)

- Recorded A19–A27 and retained feedback. Kept the first level's teaching difficulty and collision layout. Flat blue river replacement was rejected and reverted; original rocks/falls restored. Last beam/pile shifted toward current; final water contact is still a visual review item.
- Removed numbered build spots and introduced child-chosen, unsnapped crate positions via Bag → Place a crate. Added native ghost/confirm/cancel flow for portrait, mouse and keyboard; grounded stacks, actor/solid overlap, reach, bounded ownership, packing and cross-level reuse. Legacy numbered layouts still load/pack, preserving ownership and progress.
- Added wheel-only contextual outline, consumed-action clearing and original render-clock parallax correction. Removed floating action words. Real Use/Find controls and HUD explain reveal/open/finish actions. Tree footprints now reject step intersections; props/flags reserve scenery clearance.
- Added one-time flag flutter/star arrival with reduced-motion handling; visited/reloaded flag stays calm. Flag sits beside the checkpoint; three pickup positions move clear with stable saved indexes/counts.
- Chests now reveal with Find and open with Use; lifted lid and visible canonical coins explain the treasure. Open state survives reload. Bonus stays in the durable completion reward and cannot duplicate. Lab remains reward-free and now has a visible picnic finish.
- Replaced the capsule resident with a generated Moss rabbit reaction sheet; added greeting/celebration, picnic landmark and return gate. Prompt, source, alpha regions and measured pivots retained. Three reaction poses are a visual candidate, not a complete animation set or approved NPC design.
- Added a durable completion receipt and story result: exact mission/pickup/treasure coins, pet meals, bond XP, new/already-owned keepsake and wallet. JSON receipt validation, reload and duplicate reward checks pass. Actual capture caught an oversized source coin; fixed the TextureRect sizing order and added a rendered-size regression check.
- Verification: 287 checks across eight suites, including existing slow-disk, ordered writer, purchases, duplicate rewards and shutdown checks. Fourteen actual desktop/portrait scene captures inspected. Headed 390×844 Mac sample: mean8.46ms, p9916.71ms, worst24.80ms, zero >25ms; 126 nodes stable over twelve scene cycles. Existing game/editor/background load remained. No physical-device or visual-approval claim.
- Reviewed the suggested tools post; no posted skill installed/activated. Isolated SmartShape evaluation rejected and excluded. New menu production continues after these playable fixes; final V04/V09/shared chrome and overall art/audio gates remain open.

## 2026-10-16 · Surface/animation candidate v4.1, still unapproved

- Recorded A15–A18 and retained user feedback. Localized construction, thin grass, noisy rock material, floating roots, gray hands and unrelated shadows were rejected. Latest instruction prioritizes one coherent playable section before further content rollout.
- Replaced the mixed static terrain drawing paths with one connected contour/material/fringe renderer shared by existing lab/adventure layouts. Old pasted bank/cap drawing functions are removed from active code. The first new material/scale also failed; current candidate uses broad illustrated forms and deeper vegetation. Whole-route composition/variation and natural edge variants remain unfinished.
- Native world rendering preserves twice the source resolution while camera/physics stay in logical coordinates. Source alpha gutters no longer lift tree roots off ground. Hero scale stays near one fifth of playfield height.
- Added measured eight-pose child and six-pose Foxy baby/child run sources; corrected the intermediate gray/purple limb colors. Essential gait no longer freezes under reduced-motion settings. Separate idle/action/jump/fall/land/turnaround inventory remains open.
- Added reference-informed sparse pixel shadows projected onto terrain. No surface means no shadow; airborne shadows remain on the detected surface, not under the jumping body.
- Separate crank wheel rotates. The reward-free lab starts with the bridge closed, allows opening/closing and protects actors occupying it. Picnic keeps its durable one-way puzzle flow. Loaded bridges appear immediately. Rendered timber posts enter/are occluded by water; floating baked rock feet excluded. Three coin positions moved clear of flags/targets without changing saved pickup indexes/counts.
- Fixed the new surface iterator's floating-boundary stall during validation by using a bounded integer tile range. Corrected short companion-trail targeting so a newly stopped pet does not walk into its leader.
- Validation: all eight suites pass, 236 checks, including save ordering/slow disk/rewards/shutdown and mobile layout/input. Eleven headed runtime captures plus a 130-frame fixed-simulation clip retained. Mac portrait profile: mean8.52ms, p9917.39ms, worst58.90ms, three frames over25ms; existing editor/game/background processes were open. Twelve scene cycles stable at123nodes. General intermittent-glitch report remains open.
- Added direct `Play Art Review.command` entry using a separate profile, research notes, source prompts, frame/pivot metadata and asset status. Decoration study retained but not integrated. No phase outcome or visual gate completed by this work.

## 2026-10-16 · V2 art rejection and rendering audit

- User explicitly rejected the v2 runtime, including actor detail, cut terrain, repeated river texture, disconnected bridge and pasted layers. Garden setting is relatively improved but not accepted. Saved paired feedback images under `docs/feedback/2026-10-16-rejected-v2/`.
- Recorded A14: concept defines visual quality, identity and depth; do not duplicate its exact layout or substitute a flat illustration for a playable world.
- Rendering audit found the 640×360 intermediate viewport and 42/24px actor targets discard source detail before upscaling. Mirrored soil patches, water stretched to stream bounds and bridge boards drawn independently produce the visible repetition and disconnected construction.
- Previous automated checks remain mechanics/regression evidence only; no new playable art result has been accepted.

## 2026-10-16 · Concept fidelity correction (subsequently rejected)

- Recorded A10–A13 and retained user feedback images. Approved V01/V02 and shared UI remain the source; generic square terrain, empty coarse sky and first oversized-cottage garden were rejected.
- Recreated continuous organic bank/rock and rounded hanging ledge art directly from V02. Added border-free globally phased dirt, exposed-surface grass, full-width scenery support and art-only river/wood/prop rendering. Dry-gap diagnostic overlay remains in graybox only.
- Increased adventure camera framing to 1.7 zoom: the 42px hero occupies 19.8% of the 360px playfield, close to the repeated reference. Existing collision shapes and movement remain unchanged. Added upper-route vertical framing.
- Added eight movement cells per current identity, distance-driven gait and explicit foot pivots. Disabled interpolation of sprite-local scale/pivots to prevent transient oversized poses while retaining body/camera interpolation. Ground shadows follow actual grounded state.
- Fetch now uses a dedicated home garden, a cottage in the middle distance, 84/48px child/pet presentation and a shared contextual aim meter. Throw/catch anchors scale with the actors; the pet still fetches automatically.
- Added an explicit art-production matrix for missing views, clips, environments, UI/logo and audio. PNG masters, source references, metadata and prompts are preserved. Generated sheets are candidates, not approval of the complete asset set.
- Added 23 art-regression checks and one additional portrait-scale check; 225 checks across eight suites pass. Actual scene captures and a 30fps walk recording are linked from art-review.html. Capture/profiling fixtures bypass focus auto-pause only for their isolated profiles.
- Current headed portrait sample: mean 8.46 ms, p99 17.12 ms, worst 38.19 ms, two >25ms frames; 135 nodes stable over twelve cycles. Keep intermittent glitches and device performance open.
- Visual acceptance, all-route art/collider audit, complete production animation/UI/audio and physical mobile playtesting remain open. Do not advance the Phase 1 visual gate from these tests.

## 2026-10-16 · Mobile-first portrait iteration

- Recorded explicit mobile-first portrait direction as A09 and a workspace rule; original GDD preserved.
- Default launcher opens a 390×844 window. Responsive portrait menus, home summary/care grid, map, shop, bag, decoration, details, progress, pause and results reuse shared styles, coin and actions.
- Independent world view and adventure camera adapt to screen ratio; resizing retains the active level. Movement and action fingers remain separate; bag/pause releases held input.
- Added durable button size, spacing and vertical-position presets under Pause → Touch controls, with optional settings validation compatible with old saves.
- Fixed popup classification by explicitly tagging modal panels. Kept game views rendering through a visible viewport owner and moved modal notifications above the sheet so they cannot cover build controls.
- Verification: 201 checks across seven suites, including 34 mobile checks. Eleven actual portrait screens captured. Native Mac pointer checked menu launch, held movement, pause/settings scroll and resume.
- Headed portrait Mac sample (after other suites/prior game closed): mean 8.68 ms, p99 17.59 ms, worst 19.12 ms, zero above 25 ms; stable 135 nodes after twelve scene cycles. Earlier concurrent sample retained separately. Scope is one desktop, not a phone performance guarantee.
- Remaining: physical Android/iOS touch reach, keyboard/lifecycle, export/signing, controller hardware and child playtests; animation, upper-route audit and intermittent-glitch report remain open.

## 2026-10-16 · Art and reusable tools iteration

- Reproduced a save-related adventure stall and moved routine checkpoints, pickups and autosaves to a bounded background writer. Purchases, rewards and normal shutdown remain ordered/durable.
- Added camera/physics interpolation, reset handling and visuals attached to moving-platform bodies. Existing 146 checks passed before the new art/tools work. Headed timing evidence is under `test-results/performance-{before,after}.json`.
- Integrated the first runtime art pilot from accepted V01/V02 references; originals, manifest and prompts are saved under `assets/art/pilot-v1/` and `docs/art-pilot-prompts.json`.
- Added reusable crates and the B-key adventure bag in response to the high-ledge screenshot. A physical three-jump staircase reaches the selected high ledge; pickup, packing, cross-level reuse, persistence and safe placement pass.
- Created the durable design amendment, AGENTS.md process rules and saved playtest screenshot. Original GDD unchanged.
- Added the Art/Graybox switch, B-key bag entry and a shared cream control legend so text remains readable over the meadow art.
- Final verification: 167 checks pass across six suites. Eleven actual scenes in both art and graybox modes were captured. Art pilot frame sample: 23.34 ms worst observed, zero over 25 ms.
- Remaining: full animation inventory and placeholder art, all upper-route jump audit, long-session/manual/device tests, further accessories and the open intermittent-glitch report.

## Earlier playable milestones

- Reward-free capsule movement lab, companion jump/recovery, The Lost Picnic, care/clocks, shop/toy placement and saves: initial playable graybox.
- Child-controlled ball throw with automatic pet fetch; clearer find/dig cue; usable adventure meals; Windmill Walk with moving platforms and a pet-operated shortcut: cooperation graybox, 130 checks passing at that milestone.

Current source of status: `progress.json`. Current verification: `verification.json`. Design changes and open playtest reports: `design-amendments.md`. Asset provenance and completion state: `asset-register.json`.
