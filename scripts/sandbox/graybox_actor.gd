class_name GrayboxActor
extends PixelArt
## Deliberately simple silhouettes. Physics and animation state stay independent.

var home_pose: Texture2D
var home_pose_pivot=Vector2.ZERO
var home_pose_body_height=1.0
var sprite: Sprite2D
var gait_distance=0.0
var walk_frame=0
var contact_shadow: ContactShadow
func _ready() -> void:
	ArtStyle.prepare()
	sprite=Sprite2D.new()
	sprite.centered=false
	# The parent body interpolates motion; local animation pivots/scales update on
	# the render clock and must not blend from a previous pose or default scale.
	sprite.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	# Preserve shaded outlines/partial alpha instead of thresholding them away.
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(sprite)
	contact_shadow=ContactShadow.new()
	contact_shadow.actor=self
	add_child(contact_shadow)
func _process(delta: float) -> void:
	super._process(delta)
	if not is_instance_valid(sprite): return
	sprite.visible=ArtStyle.enabled and kind!="resident"
	if not sprite.visible: return
	if home_pose!=null and mood!="run":
		var body_height=42.0 if kind=="child" else (30.0 if child_stage else 24.0)
		var factor=body_height/home_pose_body_height
		sprite.texture=home_pose
		sprite.scale=Vector2.ONE*factor
		sprite.position=-home_pose_pivot*factor
		sprite.flip_h=false
		return
	var identity="explorer" if kind=="child" else ("foxy_child" if child_stage else "foxy_baby")
	var pose="idle"
	if mood=="run":
		# Essential locomotion stays readable with reduced motion enabled.
		# That preference suppresses decorative bob/effects, not the running feet.
		gait_distance+=travel_speed*delta
		walk_frame=int(gait_distance/ArtStyle.run_stride(identity)*ArtStyle.run_count(identity))%ArtStyle.run_count(identity)
		pose="walk"
	elif mood=="jump": pose="jump"
	elif mood=="throw" and kind=="child": pose="throw"
	elif mood=="ability" and kind!="child": pose="dig"
	var height=42.0 if kind=="child" else (30.0 if child_stage else 24.0)
	if pose=="walk":
		var row=ArtStyle.walk_row(identity)
		var factor=height/float(row.body_height)
		sprite.texture=ArtStyle.walk_texture(identity,walk_frame)
		sprite.scale=Vector2.ONE*factor
		var pivot=ArtStyle.run_frame(identity,walk_frame).pivot
		var pivot_x=pivot[0] if facing>=0 else sprite.texture.get_width()-pivot[0]
		sprite.position=Vector2(-pivot_x,-pivot[1])*factor
	else:
		var tex=ArtStyle.texture(identity+"_"+pose)
		sprite.texture=tex
		var base=ArtStyle.texture(identity+"_idle").get_height()
		var factor=height/base
		sprite.scale=Vector2(factor,factor*(0.7 if mood=="sleep" else 1.0))
		# Feet on the ground: discount empty rows under the drawn figure.
		sprite.position=Vector2(-tex.get_width()*factor/2,-(tex.get_height()-bottom_padding(tex))*sprite.scale.y)
	if mood=="ability" and kind!="child" and not reduced_motion:
		sprite.position.y+=sin(motion*9)*.6
	sprite.flip_h=facing<0

static var _padding: Dictionary={}
static func bottom_padding(tex: Texture2D) -> float:
	var key=str(tex.get_rid())+str(tex.region if tex is AtlasTexture else Rect2())
	if _padding.has(key): return _padding[key]
	var image=tex.get_image()
	var rows=0
	if image!=null:
		var h=image.get_height()
		var w=image.get_width()
		for y in range(h-1,-1,-1):
			var solid=false
			for x in range(0,w,2):
				if image.get_pixel(x,y).a>0.3:
					solid=true
					break
			if solid: break
			rows+=1
	_padding[key]=rows
	return rows

func _draw() -> void:
	if ArtStyle.enabled and kind!="resident":
		# Source art supplies form shading; remove the unrelated prototype oval.

		if mood=="ability" and not reduced_motion:
			for i in range(3):
				var t=fposmod(motion*2+i*.33,1.0)
				draw_rect(Rect2(Vector2(facing*(13+t*5),-2-t*4),Vector2.ONE*.8),Color(.73,.55,.27,1-t))
		if mood=="sleep": draw_string(ThemeDB.fallback_font,Vector2(10,-25),"z",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("536578"))
		return
	var height = 30.0 if kind == "child" else (22.0 if child_stage else 18.0)
	var width = 14.0 if kind == "child" else 18.0
	var tint = Color("85b9cc") if kind == "child" else Color("e7b079")
	if kind == "resident":
		height = 26
		tint = Color("afa5c7")
	var bounds = Rect2(-width/2,-height,width,height)
	if mood == "sleep": bounds = Rect2(-14,-10,28,10)
	draw_ellipse_shadow()
	var capsule = StyleBoxFlat.new()
	capsule.bg_color = tint
	capsule.border_color = Color("384451")
	capsule.set_border_width_all(1)
	capsule.set_corner_radius_all(9)
	draw_style_box(capsule,bounds)
	draw_circle(Vector2(facing*3,-height+7),1.5,Color("283540"))
	if collar: draw_line(Vector2(-7,-8),Vector2(7,-8),Color("589cbe"),2)
	if mood in ["ability","happy"]:
		draw_arc(Vector2(0,-height/2),height/2+5,0,TAU,24,Color("edcf80"),1)
	if mood=="ability" and kind!="child":
		var reach=3.0 if reduced_motion else sin(motion*12)*3
		draw_line(Vector2(facing*5,-8),Vector2(facing*(12+reach),-2),Color("7d6044"),3)
		for i in range(3):
			var drift=0.0 if reduced_motion else fposmod(motion*16+i*5,12)
			draw_circle(Vector2(facing*(14+drift),-2-drift*0.4),1.5,Color("b49e78"))
	if mood == "sleep":
		draw_string(ThemeDB.fallback_font,Vector2(9,-17),"z",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("536578"))
	if kind == "child":
		draw_line(Vector2(-4,-height+13),Vector2(4,-height+13),Color("d7edf1"),2)
