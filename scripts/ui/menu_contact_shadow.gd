extends Control
## Soft oval shadows under the child's boots and Foxy's paws (fixed, never
## follows the bobbing illustration). One feathered texture, drawn twice.
var soft: GradientTexture2D
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	soft=GradientTexture2D.new()
	soft.width=64
	soft.height=64
	soft.fill=GradientTexture2D.FILL_RADIAL
	soft.fill_from=Vector2(0.5,0.5)
	soft.fill_to=Vector2(1.0,0.5)
	var g=Gradient.new()
	g.offsets=PackedFloat32Array([0.0,0.55,1.0])
	g.colors=PackedColorArray([Color(0.1,0.16,0.04,0.42),Color(0.1,0.16,0.04,0.26),Color(0.1,0.16,0.04,0.0)])
	soft.gradient=g
func _draw() -> void:
	if soft==null: return
	# (centre x, width) as fractions of the friends picture: child, then Foxy.
	for spot in [[0.27,0.42],[0.64,0.40]]:
		var w: float=size.x*spot[1]
		draw_texture_rect(soft,Rect2(size.x*spot[0]-w*0.5,size.y*0.18,w,size.y*0.64),false)
