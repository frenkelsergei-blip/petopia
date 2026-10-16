# Shared PETOPIA interface

The user approved the overall character, adventure and home direction on 16 October 2026 and authorized the next batch. Approval includes the explicit requirement that coins and menus look consistent. It does not approve every existing control: the adventure's dark counter and the home's blue-framed counter visibly differ and need a common replacement.

`ui-design-system.json` defines that replacement and the shared component rules. A master component sheet guides every subsequent concept. The first reusable runtime asset is a single gold coin texture; the same texture is used for the wallet badge and world pickups. Differences in size or counter meaning must not introduce a different coin silhouette.

| Component | Common rule |
|---|---|
| Coin | Round gold stepped rim, amber right edge, upper-left glint, simple vertical inset; no changing emblem |
| Counter | Cream inset in wood frame; coin left, navy number right; run pickups explicitly labeled Run coins |
| Panels and buttons | Cream/wood/navy; primary gold; same corner treatment, icon spacing and label style |
| Selection and focus | Selected gold plus marker; blue focus outline; distinguish focus from selection |
| Disabled content | Desaturated cream plus lock and reason; never a working-looking unavailable button |
| Menus | Shared header, Back/title left, stable navigation, wallet/settings right |
| Need meters | Fixed label, icon and color mapping across home and details; bond remains progression rather than a fifth short-term need |
| Character and pet | Use the accepted V01 identity; preserve clothing, Foxy markings and stage proportions |
| Logo | Supplied second reference's multicolor lettering and paw O, without the floating heart; title screen only needs the large logo |

The next batch follows GDD §21 and the existing screen catalogue: main menu, adoption, pet details, world/level selection, pause/settings, and adventure results. All new screens are proposals for layout review within the accepted direction. Keep Phase 1 content honest: Foxy only, The Lost Picnic available, other content clearly locked or future, and no age gate on the adventure.

Concept images cannot guarantee identical pixels across separate generations. During implementation, shared textures, themes and component instances provide that guarantee. The concept sheet is a reference, not an atlas to crop into unrelated screen controls.

Runtime follow-up: the user subsequently requested the Windmill Walk level-two preview and reusable crate bag. Both are now documented amendments; only Foxy is available. The main roadmap gates remain open. New runtime art is an initial pilot and keeps the same canonical coin, shared cream/wood/navy controls and collision geometry in both visual modes.

Portrait follow-up (A09): mobile is the primary layout. The same PetUI styles, coin texture, item icons and action callbacks feed responsive portrait menus. Four need summaries sit in a two-column grid; details retain health and bond. The independent game viewport narrows its adventure camera rather than stretching sprites. Safe bounded presets resize and reposition controls; menus scroll. Full physical-device and accessibility verification remains open. See `mobile-layout.md`.

V04 runtime follow-up (A30): the application now boots to a native main menu. Logo, scenery, friendly pair and two empty button faces are separate reference-derived assets, with prompts/regions/pivots in `menu-production.json`. `PetUI.menu_button` provides reusable nine-slice chrome and native hover, pressed, disabled and blue-focus states. The canonical coin shows the saved wallet. Continue resumes the pending level/checkpoint or returns to the pet; a fresh profile starts adoption and then The Lost Picnic. Practice is available before adoption; Collection remains visibly unavailable. Settings save motion and touch presets before adoption and through the existing profile transaction afterwards. Seven actual renders and36 menu checks are retained in [menu review](menu-review.html). This is implementation, not final visual approval; V05–V09 production rollout, typography/audio and physical-device review remain open.

A31 supersedes the gold main-action face in V04: the user preferred the second cream/wood reference. Every illustrated menu button uses that cream texture, including Start/Continue and Done. Native focus remains blue; hover/press gently change brightness. This preference applies to menu-button chrome; it does not replace gold coins or selected settings.

A32 corrects the remaining V04 fidelity feedback: desktop buttons are352x98 with58px illustrated icons, a centered native rounded title area and separate Collection caption. Full-density sources replace the small intermediate texture and primitive symbols. Wallet uses a detailed wood frame, canonical coin and actual balance; Settings uses the blue gear tile in the lower-right. Six new transparent sources, font/license and complete provenance are in `menu-v2-production.json`. Previous frames are retained for comparison. This is a review candidate, not overall menu acceptance.

A33 supersedes the smooth A32 icons and large phone controls: the user's pixel close-up now guides compact stepped icons. Latest phone actions are282x72/76 with36px icons and24px titles; desktop352x104 with50px icons. Cream rests and gold focus/hover follow the latest instruction; native hitboxes remain fixed. Smaller Settings gear, larger pair, four-pose petting loop and fixed sparse ground shadow are available in the [live render review](menu-review.html), including a motion clip. Saved reduced motion stops decorative animation. Exact assets/anchors and superseded source status: `menu-v3-production.json`. Full visual/device approval remains open.
