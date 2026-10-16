# A43 · Home crowding audit and redesign brief

The user rejects the crowded home and widespread button proportions: narrow frames, oversized icons, inconsistent text fit and a full row of unrelated navigation. Publishing the0.2.0 candidate is stopped. The public0.1.1 remains unchanged. Functional checks do not constitute visual approval.

## Captured surface and steps

Captured the actual native Godot home with an isolated profile via `tools/capture_home_audit.gd`, after the user's feedback. Files inspected before accepting them as evidence. No physical phone or accessibility certification.

1. `01-short-phone.png` —360×640 home entry: poor. Navigation, duplicate identity, six meters and seven immediate care/detail actions leave a narrow band for the child, Foxy and furniture.14 immediate buttons, excluding the passive wallet.
2. `02-landscape-phone.png` —844×390 home: poor. Tabs compete with the wallet and settings. The106px tab width cannot accommodate icon, padding and label at the chosen font size, so native minimum sizing expands adjacent frames. The care panel also clips the room's right side. The problem is structural as well as component sizing.
3. `03-desktop.png` —1280×720 home: mixed. The actual room is readable and the furniture is grounded, but repeated My Pet navigation/title/identity plus permanent meters and care controls still compete for attention.13 immediate actions.
4. `04-details-blur.png` —open Pet Details: improved background consistency. The actual same room texture is blurred behind a sharp native panel and a sharp pet crop. The user has not approved overall visual fidelity; this does not approve home density.

## Proposed direction, not an approved implementation

- Preserve the current actual room layout, child/Foxy, bed and wash location. Retain the approved pixel identity, wood/cream UI and canonical coin. Do not use a different concept room as the live backdrop.
- Persistent top controls: one compact wallet and one clearly labelled Menu target. Put Adventures, Shop, Decorate, Collection, Settings and exit navigation in that menu.
- Three independent phone concepts: one Care button, a revealed care drawer, or a three-action dock. Each has one dominant pet/room use case, generous spacing and distinct interaction hierarchy.
- The open care drawer may show Feed, Water, Clean, Pet, Play and Rest. Detailed needs/growth live in Pet Details, not six permanent bars across the room. Needs can surface one relevant cue when needed rather than a dashboard.
- Clear names and visible controls matter for children; avoid relying on an unlabeled invisible pet gesture. Furniture can provide direct shortcuts without replacing the discoverable Care entry.
- Phone target reference390×844, at least48 logical pixels per touch target; prefer56–64. Icons24–28, regular text16–20, gap10–12. Text must fit without overlapping its icon/border; never squash the entire button to fit a dense navigation bar. Landscape/tablet must reflow rather than stretch.
- Modals use the actual room softly blurred behind crisp controls. A selected layout is required before redesign implementation; concepts are proposals only.

## Comparison research

- Outfit7 official Google Play listing, My Talking Tom2, inspected screenshot viewer: large pet, compact top indicators, small consistent care icons along the bottom. Marketing screenshots show presentation, not independently tested gameplay or usability. https://play.google.com/store/apps/details?id=com.outfit7.mytalkingtom2
- Bandai official Tamagotchi On manual: separate Care Icon Screen reached from Home. This is a virtual-pet interaction pattern from a physical device, not a claim that it is a phone app. https://www.bandai.com/amfile/file/download/file/32/product/1275788/

## Status

Full current automation:449 checks across13 suites passed before this design review, including care/orientation/saves. That evidence covers mechanics and sampled sizing, not acceptable visual hierarchy. Preserve the fixes; do not publish the rejected layout. Three image-based proposals follow. Future implementation remains native Godot on the existing game/save systems.
