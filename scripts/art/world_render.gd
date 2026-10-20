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
	# A60: render at the screen's real pixel density (phones are 2.5-3.5x),
	# so the paper art and the characters stay sharp, also when a tall room
	# zooms the camera out.
	var d=float(DENSITY)
	var win=DisplayServer.window_get_size()
	if win.y>0: d=clampf(float(win.y)/float(maxi(1,logical_size.y))*1.25,float(DENSITY),4.0)
	var want=Vector2i(Vector2(logical_size)*d)
	if view.size!=want: view.size=want

