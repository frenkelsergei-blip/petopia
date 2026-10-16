class_name WorldRender
extends RefCounted
## Rendering resolution is independent of physics units and camera framing.
const DENSITY=2
static func configure(view: SubViewport, logical_size: Vector2i) -> void:
	view.size_2d_override=logical_size
	view.size_2d_override_stretch=true
	# A stretched desktop container owns native size; only set it manually when
	# the portrait UI displays the viewport texture in a separate TextureRect.
	var owner=view.get_parent()
	if owner is SubViewportContainer and owner.stretch: return
	if view.size!=logical_size*DENSITY: view.size=logical_size*DENSITY

