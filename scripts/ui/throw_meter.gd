class_name ThrowMeter
extends Control
## Shared cream/wood aim guide, used in desktop and portrait UI.
var activity: BallGame
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.y=64
func _process(_delta: float) -> void: queue_redraw()
func _draw() -> void:
	var frame=PetUI.style(PetUI.CREAM,10)
	draw_style_box(frame,Rect2(Vector2.ZERO,size))
	var track=Rect2(16,13,maxf(1,size.x-32),22)
	var track_style=PetUI.style(Color("c5cbd0"),7)
	track_style.set_border_width_all(0)
	draw_style_box(track_style,track)
	var zone=Rect2(track.position+Vector2(track.size.x*60/260.0,0),Vector2(track.size.x*140/260.0,track.size.y))
	draw_rect(zone,PetUI.GOLD)
	# Diamond marker and text make the target distinguishable without color alone.
	var fraction=activity.aim_fraction() if is_instance_valid(activity) else 0.0
	var center=Vector2(track.position.x+track.size.x*fraction,24)
	draw_colored_polygon(PackedVector2Array([center+Vector2(0,-13),center+Vector2(7,0),center+Vector2(0,13),center+Vector2(-7,0)]),PetUI.INK)
	var text="Practice · throw in the marked band"
	if is_instance_valid(activity) and not activity.practice: text="Throw %d / 10 · %d catches"%[mini(10,activity.throws+1),activity.catches]
	if is_instance_valid(activity) and (activity.waiting or activity.in_flight): text="Foxy is bringing it back"
	draw_string(ThemeDB.fallback_font,Vector2(16,53),text,HORIZONTAL_ALIGNMENT_LEFT,size.x-32,15,PetUI.INK)
