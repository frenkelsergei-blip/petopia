# PETOPIA rendering rebuild notes · 16 October 2026

## Requirements, evidence and choices

The original GDD §§25–26 calls for a coherent modular Meadow kit, one consistent pixel density, three depth layers and documented animation clips/pivots. The proposed baseline and frame counts are starting points, not evidence of production completion. Approved V01/V02 define character identity, illustrated form shading, dimensional grass/rock and readable play objects. They do not prescribe the exact level layout.

The user rejected isolated painted sections surrounded by older square geometry, thin grass, grainy rocks, hovering roots, identical repeated sections, frozen/sliding feet, gray fists, an unrelated oval shadow and an apparently inactive crank. These are open visual quality issues; functional tests cannot accept them.

## Sources consulted

- [Godot: using TileSets](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html): terrain sets use edge/corner relationships rather than treating every square as an independently complete platform.
- [Godot: Polygon2D](https://docs.godotengine.org/en/stable/classes/class_polygon2d.html): textured polygons and UV coordinates can describe nonrectangular visual geometry.
- [Godot: 2D sprite animation](https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html): animation requires actual source frames and playback timing. Frame count alone says nothing about a convincing gait.
- [Cardboard Sword art director interview: The Siege and the Sandfox](https://www.gamedeveloper.com/art/adding-depth-to-2d-with-hand-drawn-normal-maps-in-i-the-siege-and-the-sandfox-i-): the artist describes broad form lighting, noise problems from excessive small detail, and testing foreground/background/characters together in a small game area. This does not imply that PETOPIA has normal maps or that normal maps would repair poor base artwork.
- [GDC: Rayman Legends tools presentation introduction](https://www.gamedeveloper.com/design/video-the-tools-used-to-design-i-rayman-legends-i-): production combines art vision with level-design tooling. The article links the developer presentation; it does not by itself document every UbiArt rendering algorithm. We do not claim to reproduce that engine.

## Current implementation choices (provisional)

Existing authored rectangles remain the collision/save source. Their connected union supplies one visual contour, with rounded/irregular exposed boundaries and continuous world-space material mapping. This follows the connected-edge principle without migrating existing levels to a grid or claiming to implement Godot native TileMap terrain sets. The grass fringe needs real visible depth relative to the 42-unit actor; a paper-thin uniform line was explicitly rejected. Fine illustrated boulders replace the grainy first material. Tree source alpha gutters are trimmed so the root pivot reaches supported ground.

The two-times native viewport preserves source outlines/details while logical camera/physics coordinates remain unchanged. Frame regions are measured from alpha components; generated sheets are not trusted to obey a perfect grid. The run frame clock advances from distance even when reduced-motion preference is enabled; decorative bob/effects retain that preference. A separate terrain ray projects sparse pixel shadow clusters onto actual ground rather than attaching a smooth oval to airborne feet. Color correction keeps the same skin/boot materials through the cycle; strong gray/purple limb recoloring was a mistaken request in the intermediate generation prompt and is superseded.

Crank stand and wheel are separate anchored components. In the lab, Use opens/closes the bridge with visible wheel rotation; closing is refused while either actor occupies it. Picnic uses its existing durable one-way puzzle transaction. Bridge deck collision stays unchanged; rendered supports extend through the river surface and foreground water occludes their ends. Baked floating rock feet are excluded. Coin array indexes/counts remain stable while three conflicting placements are moved away from flags/targets.

These are reviewed candidates, not final art approval. Full action clips, natural edge variants, authored composition/variation over all adventures, mobile hardware checks and the general intermittent-glitch report remain open. The latest user instruction stops further unreviewed rollout: assess a coherent playable section first. Historical failed images remain in the workspace.
