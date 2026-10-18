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
func _draw() -> void:
	var ball=CareArt.icon("ball")
	var r=size.y*0.5
	var track=Rect2(r*0.6,size.y*0.22,maxf(1,size.x-r*1.2),size.y*0.56)
	draw_style_box(PetUI.kit_style("meter_track",track.size.y*0.5),track)
	# Gold band where Foxy can catch (same range the game checks).
	var left=(BallGame.PLAY_LEFT-330)/260.0
	var right=(BallGame.PLAY_RIGHT-330)/260.0
	var inner=track.grow(-track.size.y*0.18)
	var zone=Rect2(inner.position.x+inner.size.x*left,inner.position.y,inner.size.x*(right-left),inner.size.y)
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
