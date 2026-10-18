extends StyleBox
## A48 crisp wooden frame drawn in layers at any size, replacing the shrunk
## painted 9-slice (which turned soft and muddy on small controls).
## outline -> wood edge with highlight/shade -> cream or gold face -> rivets.
var face=Color("fbefd3")
var face_shade=Color("e9d2a6")
var face_light=Color("fffaf0")
var wood=Color("a2653a")
var wood_light=Color("d39b62")
var wood_dark=Color("6f4223")
var outline=Color("3a2416")
var weight=1.0     # 1 thin controls, 1.5 panels, 2 big menu boards
var tint=Color.WHITE
var rivets=true
var corner=0.0     # compatibility with callers that set a corner size

func _get_minimum_size() -> Vector2: return Vector2.ZERO

func _box(color: Color, radius: float) -> StyleBoxFlat:
	var s=StyleBoxFlat.new()
	s.bg_color=color*tint
	s.set_corner_radius_all(int(radius))
	s.anti_aliasing=true
	s.anti_aliasing_size=0.6
	return s

func edge_width(size_value: Vector2) -> float:
	return clampf(minf(size_value.x,size_value.y)*.07,3,5)*weight

func _draw(canvas: RID, rect: Rect2) -> void:
	var w=edge_width(rect.size)
	var r=clampf(minf(rect.size.x,rect.size.y)*.16,6,14)
	_box(Color(0,0,0,.22),r+1).draw(canvas,Rect2(rect.position+Vector2(0,2),rect.size))
	_box(outline,r).draw(canvas,rect)
	# Wood edge: dark base, mid wood lifted off the bottom, light top line.
	var wood_rect=rect.grow(-1.5)
	_box(wood_dark,r-1).draw(canvas,wood_rect)
	var bevel=maxf(1.5,w*.35)
	_box(wood,r-1).draw(canvas,Rect2(wood_rect.position,wood_rect.size-Vector2(0,bevel)))
	var light=_box(wood_light,1)
	light.bg_color.a=.85
	light.draw(canvas,Rect2(wood_rect.position+Vector2(r*.6,1),Vector2(wood_rect.size.x-r*1.2,maxf(1,w*.25))))
	# Face: thin dark seam, shaded base, cream/gold face, faint gloss.
	var face_rect=wood_rect.grow(-w)
	face_rect.size.y+=bevel*.5
	var fr=maxf(2,r-w)
	_box(outline.lerp(wood_dark,.4),fr+1).draw(canvas,face_rect.grow(1))
	_box(face_shade,fr).draw(canvas,face_rect)
	var shade=clampf(face_rect.size.y*.08,1.5,3)
	_box(face,fr).draw(canvas,Rect2(face_rect.position,face_rect.size-Vector2(0,shade)))
	var gloss=_box(face_light,maxf(1,fr-1))
	gloss.bg_color.a=.6
	gloss.draw(canvas,Rect2(face_rect.position+Vector2(fr*.5,1.5),Vector2(face_rect.size.x-fr,maxf(1.5,face_rect.size.y*.07))))
	if not rivets or rect.size.x<110 or rect.size.y<44: return
	var d=clampf(w*1.1,4,6)
	var inset=w+1.5+d*.5+3
	for at in [Vector2(inset,inset),Vector2(rect.size.x-inset,inset),Vector2(inset,rect.size.y-inset),Vector2(rect.size.x-inset,rect.size.y-inset)]:
		var c=rect.position+at
		_box(outline,d*.5+1).draw(canvas,Rect2(c-Vector2.ONE*(d*.5+1),Vector2.ONE*(d+2)))
		_box(Color("c8842f"),d*.5).draw(canvas,Rect2(c-Vector2.ONE*d*.5,Vector2.ONE*d))
		_box(Color("ffe2a0"),1).draw(canvas,Rect2(c-Vector2.ONE*d*.3,Vector2.ONE*maxf(1.2,d*.3)))
