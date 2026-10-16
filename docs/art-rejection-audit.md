# Runtime art rejection · 16 October 2026

The user rejected the v2 runtime. This is a failed art implementation, not a request to copy the approved concept's exact level layout. The concept establishes the quality, identity, materials, proportions and depth expected of newly authored game content.

## What failed

| Area | Quality reference | Rejected runtime and construction cause |
|---|---|---|
| Child and Foxy | Strong readable outlines, shaded forms, expressive faces, hair/fur highlights, distinct clothing and paws | The 640×360 intermediate view is enlarged for desktop presentation. A 42-world-pixel child at camera zoom 1.7 is rasterized at roughly 71 pixels before the view is enlarged; Foxy baby is about 41 pixels. This loses texture detail. The 0.98 alpha cutoff also removes nearly all partially transparent edge pixels. Source identity, clip quality and pivots require review independently of resolution. |
| Natural banks | Irregular rock silhouettes, roots, grass overhangs, varied rock scale and connected corners | `draw_terrain` fills rectangular collision bounds; cropped/mirrored soil covers them and a narrow grass strip caps them. An organic source illustration does not make this rectangular construction organic. Mirroring creates obvious symmetric motifs. |
| Water and bridge | A continuous river in perspective, rocks, localized foam and falls, believable banks, deck and supports | `draw_water` stretches an image into the stream rectangle. `draw_bridge` repeats a platform image and draws separate straight supports/rope. These elements have no jointly authored bank connections or coherent depth/perspective. |
| Layering | Foreground plants, supported trees and middle/distant scenery overlap with clear depth and a shared light direction | A panorama, repeated props and ground strips are combined without a composed near/middle/far kit. A global tint cannot create the missing depth or contact. |
| Garden | Dedicated home setting, legible child/pet and convincing interaction | The setting is relatively improved; the user still rejects its actor quality and overall finish. It is not an approved screen. |

## Scope of the correction

- Keep the existing gameplay, saves and mobile-first requirement. These do not justify accepting poor art.
- Preserve source detail through rendering, then review character design, outline, shading, pivots, gait and floor contact at actual display size. A resolution change alone cannot repair the other failures.
- Build reusable banks with authored exposed faces, end caps, corner transitions and root/grass overhangs. Fit collision inside the visible walkable surface; do not stretch decorative art over the physics rectangle and call it finished.
- Build crossings with connected bank/deck/support pieces and an independently composed river behind them. Water must have meaningful local structure, not a rectangular animated fill.
- Compose foreground, near, middle and distant layers together with consistent scale, light and contrast. New level layouts can differ from the concept while satisfying its visual standard.
- Judge an actual playable section before extending the method across the levels. A generated image, a copied concept, a passing mechanics test and a larger character are not evidence of finished art.

## Unintegrated studies

Two built-in image-generation outputs are retained under `assets/art/reference-slice-v3/`, with prompts in `art-rejection-study-prompts.json`. Neither is wired into gameplay or approved:

- `crossing-environment.png`: literal reference-layout environment study. The user's clarification supersedes using it as a replacement playable scene. It does not solve modular world construction.
- `actors-detail-study.png`: source-detail study. Repeated similar strides and a front-facing fox in an intended side-view idle cell mean this is not a valid complete animation atlas. Do not silently replace the runtime frames with it.

The original v2 screenshots remain available as rejected evidence. The 225 previously passing checks cover mechanics and specific regressions; they do not contradict the failed visual gate. No new playable art iteration is declared complete by this audit.
