# First runtime art pilot

This is the first playable art integration, not a completed production art set. The accepted V01 character identity and V02 meadow palette guide it. The same movement, collision shapes, cooperative actions, rewards and save systems run in Art and Graybox modes.

Switch **Visuals: Art pilot / Graybox** on the sandbox hub or in Pause. This changes rendering in place. It does not restart an adventure or create a different save.

## Saved assets and source

- `assets/art/pilot-v1/actors-terrain-atlas.png`: original generated RGBA image containing explorer poses, Foxy baby/child poses, grass/soil, a tree and shrub.
- `assets/art/pilot-v1/meadow-background.png`: original generated distant meadow panorama.
- `assets/art/pilot-v1/manifest.json`: authored atlas regions, logical sizes and completion notes.
- `docs/art-pilot-prompts.json`: exact final prompts, using built-in `image_gen`; source references are V01 and V02.
- `docs/asset-register.json`: provenance and current status.

The generation did not follow an exact regular grid, so the importer uses explicit AtlasTexture regions. Read-only alpha analysis identified region bounds; original PNG pixels and transparency are preserved. Runtime texture filtering is nearest; a shared sprite shader rejects nearly transparent edge noise. Each identity uses one scale and a foot-based origin, independent of the current pose. Collision capsules are unchanged.

The pilot has idle/run/jump/throw for the child and idle/run/jump/dig for Foxy baby/child. The original pilot alternated two poses. The current review build replaces that gait with eight distance-driven movement cells per identity; see `art-production-matrix.md`. Full GDD walk/run frame sets, separate sleep/eat/celebrate clips, equipment attachment anchors and animation timing remain future work. A resident character, room surfaces, moving platforms, crate/food props and some mechanisms still use identified placeholders. This is not the final logo/menu pass.

## Check with actual play

`tools/capture_graybox.gd -- art-pilot` captures the project with the art pilot; omitting that argument captures Graybox. Screenshots are saved with distinct `art-pilot-*` and `graybox-*` names under `docs/screenshots/`.

The trail-tool suite verifies that switching appearance preserves the same player shape and that sprites share the original atlas with real alpha. A headed `tools/profile_gameplay.gd -- art-pilot` sample records performance with actual assets. Inspect `test-results/performance-art-pilot.json`; single-machine samples do not replace device or long-session tests.
