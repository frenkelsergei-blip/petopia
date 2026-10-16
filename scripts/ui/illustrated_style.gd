extends StyleBox
## Full-density art with independent source and logical corner dimensions.
var texture: Texture2D
var region: Rect2
var source_corner=140.0
var corner=22.0
var tint=Color.WHITE

func _get_minimum_size() -> Vector2:
	# StyleBox adds content margins itself. Corners clamp at draw time.
	return Vector2.ZERO

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
