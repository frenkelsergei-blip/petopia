extends Control
## Ground contact uses discrete pixel clusters; never follows a bobbing illustration.
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	var outer=Color(0.17,0.23,0.07,0.23)
	var contact=Color(0.12,0.17,0.05,0.33)
	var step=maxf(1,roundf(size.x/145))
	for patch in [Rect2(0.08,0.28,0.34,0.30),Rect2(0.14,0.12,0.24,0.60),Rect2(0.47,0.26,0.34,0.38),Rect2(0.52,0.10,0.19,0.65),Rect2(0.03,0.40,0.035,0.18),Rect2(0.84,0.38,0.05,0.16),Rect2(0.39,0.68,0.05,0.18),Rect2(0.72,0.70,0.07,0.12)]:
		var r=Rect2((patch.position*size/step).round()*step,(patch.size*size/step).round()*step)
		draw_rect(r,outer)
	for patch in [Rect2(0.15,0.20,0.21,0.30),Rect2(0.54,0.20,0.18,0.30)]:
		draw_rect(Rect2((patch.position*size/step).round()*step,(patch.size*size/step).round()*step),contact)
