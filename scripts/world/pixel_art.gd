class_name PixelArt
extends Node2D
## Original procedural prototype artwork; replace with approved animation sheets.

var kind = "foxy"
var motion = 0.0
var facing = 1.0
var mood = "idle"
var child_stage = false
var collar = false
var reduced_motion = false
var grounded = true
var travel_speed = 0.0

func _process(delta: float) -> void:
	if not reduced_motion: motion += delta
	queue_redraw()

func box(x: float, y: float, w: float, h: float, color: String) -> void:
	draw_rect(Rect2(x, y, w, h), Color(color))

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	draw_ellipse_shadow()
	var bob = round(sin(motion * (10 if mood == "run" else 3)) * (1 if mood != "sleep" else 0))
	draw_set_transform(Vector2(0, bob), 0, Vector2(facing, 1))
	if kind == "child": _explorer()
	elif kind == "resident": _resident()
	else: _fox()

func draw_ellipse_shadow() -> void:
	if not grounded: return
	draw_style_box(_shadow_style(), Rect2(-13, -2, 26, 5))

func _shadow_style() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.07, 0.14, 0.16, 0.2)
	s.set_corner_radius_all(4)
	return s

func _explorer() -> void:
	var step = int(sin(motion * 12) * 3) if mood == "run" else 0
	box(-9,-25,7,15,"674b2e"); box(-8,-24,5,11,"c59545")
	box(-5,-12,5,10+step,"263d53"); box(2,-12,5,10-step,"304e63")
	box(-6,-3+step,7,3,"493526"); box(2,-3-step,8,3,"493526")
	box(-6,-23,13,13,"244f46"); box(-4,-23,9,11,"4b8062")
	box(6,-20,4,11,"ac7148"); box(6,-20,4,6,"528d6e")
	box(-5,-37,14,15,"352a29"); box(-8,-34,19,9,"352a29")
	box(-3,-34,13,11,"bf875a"); box(0,-31,11,8,"d39b68")
	box(6,-30,2,3,"24343c"); box(9,-26,2,1,"71432f")
	box(-6,-37,7,7,"342a29"); box(0,-39,8,7,"3f302a")
	box(6,-37,5,5,"48312a"); box(-8,-30,6,5,"3f302a")
	box(-3,-34,3,4,"453029"); box(1,-35,3,3,"453029")
	box(-3,-22,4,3,"d5b15b")

func _fox() -> void:
	if mood == "sleep":
		box(-15,-11,28,10,"ab522d"); box(-12,-14,22,10,"e38737")
		box(4,-15,9,9,"f2a348"); box(6,-17,4,5,"c96c32")
		box(7,-10,4,1,"49332c"); box(-15,-9,10,7,"fff0cc")
		return
	var leg = 3 if child_stage else 0
	var step = int(sin(motion*13)*2) if mood == "run" else 0
	box(-17,-16-leg,8,11,"85452d"); box(-21,-20-leg,8,10,"da742d")
	box(-22,-24-leg,7,8,"fff0cf"); box(-19,-24-leg,5,3,"fff8dc")
	box(-11,-14-leg,22,12,"ad542d"); box(-10,-16-leg,19,12,"ed8a34")
	box(-6,-12-leg,16,10,"f8a34c")
	box(-8,-5-leg,4,5+leg+step,"634330"); box(5,-5-leg,4,5+leg-step,"634330")
	box(-9,-2+step,5,2,"3e342d"); box(4,-2-step,6,2,"3e342d")
	box(0,-24-leg,14,14,"a9542f"); box(-1,-25-leg,15,11,"f3963d")
	box(0,-34-leg,5,12,"75422f"); box(1,-31-leg,3,7,"f1b58e")
	box(10,-33-leg,5,11,"75422f"); box(11,-30-leg,3,6,"f1b58e")
	box(4,-20-leg,13,8,"fff1d0"); box(12,-19-leg,6,4,"fff8df")
	box(8,-22-leg,3,4,"27373b"); box(9,-22-leg,1,1,"ffffff")
	box(16,-19-leg,3,3,"27373b"); box(11,-13-leg,4,1,"714734")
	if collar: box(0,-12-leg,11,2,"549fcd")
	if mood in ["happy", "ability"]:
		box(1,-43-leg,3,3,"ed8490"); box(6,-43-leg,3,3,"ed8490"); box(3,-40-leg,4,3,"ed8490")

func _resident() -> void:
	box(-11,-16,23,16,"7f9b86"); box(-6,-24,15,14,"b2c4a2")
	box(-7,-36,4,17,"8b9f85"); box(3,-37,4,17,"8b9f85")
	box(-3,-21,2,3,"293f3e"); box(6,-21,2,3,"293f3e")
	box(-12,-12,26,5,"c69959")
