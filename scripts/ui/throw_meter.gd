class_name ThrowMeter
extends Control
## Aim bar (A49 kit): carved track, gold target band with soft edges, and the
## sun ball sliding along it as the marker. Shared by landscape and portrait.
const HEIGHT=40.0
var activity: BallGame
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.y=HEIGHT
func _process(_delta: float) -> void: queue_redraw()
## A57 (P52): the curved torn-paper power meter with its cream marker.
var paper32=false
func _draw() -> void:
	if paper32:
		draw_p52()
		return
	var ball=CareArt.icon("ball")
	var r=size.y*0.5
	var track=Rect2(r*0.6,size.y*0.22,maxf(1,size.x-r*1.2),size.y*0.56)
	draw_style_box(PetUI.kit_style("meter_track",track.size.y*0.5),track)
	# Gold band where Foxy can catch (same range the game checks).
	# The band follows Foxy (it wanders) and the child (walking changes reach).
	var b=activity.band() if is_instance_valid(activity) else Vector2(0.4,0.6)
	var left=clampf(b.x,0.0,1.0)
	var right=clampf(b.y,0.0,1.0)
	var inner=track.grow(-track.size.y*0.18)
	var zone=Rect2(inner.position.x+inner.size.x*left,inner.position.y,maxf(2.0,inner.size.x*(right-left)),inner.size.y)
	draw_style_box(PetUI.kit_style("meter_fill",zone.size.y*0.5,PetUI.GOLD),zone)
	var ready=is_instance_valid(activity) and not activity.in_flight and not activity.waiting and not activity.done
	var fraction=activity.aim_fraction() if is_instance_valid(activity) else 0.0
	var inside=fraction>=left and fraction<=right
	# Small stars mark the band edges so the target reads without colour.
	for x in [zone.position.x,zone.end.x]:
		draw_colored_polygon(PackedVector2Array([Vector2(x,track.position.y-5),Vector2(x+5,track.position.y-12),Vector2(x-5,track.position.y-12)]),Color("8a4b1c"))
	var center=Vector2(inner.position.x+inner.size.x*fraction,size.y*0.5)
	var d=size.y*(1.0 if ready and inside else 0.86)
	if ready and inside: draw_circle(center,d*0.62,Color(1,0.93,0.5,0.55))
	draw_texture_rect(ball,Rect2(center-Vector2(d,d)*0.5,Vector2(d,d)),false,Color(1,1,1,1.0 if ready else 0.55))

func draw_p52() -> void:
	var track: Texture2D=ConceptScreen.tex("ball-p32","meter")
	var marker: Texture2D=ConceptScreen.tex("ball-p32","marker")
	var h=size.x*track.get_height()/track.get_width()
	var top=size.y-h
	draw_texture_rect(track,Rect2(0,top,size.x,h),false)
	var b=activity.band() if is_instance_valid(activity) else Vector2(0.4,0.6)
	var ready=is_instance_valid(activity) and not activity.in_flight and not activity.waiting and not activity.done
	var fraction=activity.aim_fraction() if is_instance_valid(activity) else 0.0
	var inside=fraction>=b.x and fraction<=b.y
	# The track is a shallow smile: points on its centre line.
	var at=func(f: float) -> Vector2: return Vector2(size.x*(0.06+0.88*f),top+h*(0.38+0.2*sin(PI*f)))
	# Catch band: a soft gold glow along the track, little cream ticks at its ends.
	var steps=12
	for i in steps:
		var f=lerpf(b.x,b.y,(i+0.5)/steps)
		draw_circle(at.call(f),h*0.2,Color(1,0.93,0.45,0.28))
	for f in [b.x,b.y]:
		var p: Vector2=at.call(clampf(f,0,1))
		draw_colored_polygon(PackedVector2Array([p+Vector2(0,-h*0.32),p+Vector2(-h*0.12,-h*0.55),p+Vector2(h*0.12,-h*0.55)]),Color("fff6e0"))
	var c: Vector2=at.call(clampf(fraction,0,1))
	var mw=h*0.62
	var mh=mw*marker.get_height()/marker.get_width()
	if ready and inside: draw_circle(c+Vector2(0,-mh*0.4),mw*0.7,Color(1,0.93,0.5,0.5))
	draw_texture_rect(marker,Rect2(c+Vector2(-mw*0.5,-mh*0.95),Vector2(mw,mh)),false,Color(1,1,1,1.0 if ready else 0.6))
