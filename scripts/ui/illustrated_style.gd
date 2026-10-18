extends StyleBox
## Full-density art with independent source and logical corner dimensions.
## Rivets are not part of the art: they are drawn here at one fixed size and
## inset, so every wide button and panel matches and labels never meet them.
var texture: Texture2D
var region: Rect2
var source_corner=140.0
var corner=22.0
var tint=Color.WHITE
var rivet: Texture2D
const RIVET_MIN=Vector2(110,44)

func _get_minimum_size() -> Vector2:
	# StyleBox adds content margins itself. Corners clamp at draw time.
	return Vector2.ZERO

static func rivet_layout(bounds_size: Vector2, c: float) -> Array:
	# [inset from each edge to rivet centre, diameter]
	return [roundf(c*.75),maxf(4,roundf(c*.4))]

func _draw(canvas: RID, bounds: Rect2) -> void:
	if texture==null: return
	var c=minf(corner,minf(bounds.size.x,bounds.size.y)*0.5)
	var src=minf(source_corner,minf(region.size.x,region.size.y)*0.5)
	var dx=[0.0,c,bounds.size.x-c,bounds.size.x]
	var dy=[0.0,c,bounds.size.y-c,bounds.size.y]
	var sx=[region.position.x,region.position.x+src,region.end.x-src,region.end.x]
	var sy=[region.position.y,region.position.y+src,region.end.y-src,region.end.y]
	for row in range(3):
		for col in range(3):
			var destination=Rect2(bounds.position+Vector2(dx[col],dy[row]),Vector2(dx[col+1]-dx[col],dy[row+1]-dy[row]))
			var source=Rect2(sx[col],sy[row],sx[col+1]-sx[col],sy[row+1]-sy[row])
			texture.draw_rect_region(canvas,destination,source,tint)
	if rivet==null or bounds.size.x<RIVET_MIN.x or bounds.size.y<RIVET_MIN.y: return
	var spec=rivet_layout(bounds.size,c)
	var inset: float=spec[0]
	var d: float=spec[1]
	for at in [Vector2(inset,inset),Vector2(bounds.size.x-inset,inset),Vector2(inset,bounds.size.y-inset),Vector2(bounds.size.x-inset,bounds.size.y-inset)]:
		rivet.draw_rect(canvas,Rect2(bounds.position+at-Vector2.ONE*d*.5,Vector2.ONE*d),false,tint)
