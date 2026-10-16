class_name ItemVisual
extends Node2D
## Shared object silhouettes in shop, room and play. Replace here with final sprites.
var item_id = "ball_sun"
var ghost = false
func _draw() -> void: paint(self,item_id,Vector2.ZERO,ghost)
static func paint(canvas: CanvasItem, id: String, at: Vector2, preview: bool = false) -> void:
	var alpha=0.45 if preview else 1.0
	if ArtStyle.enabled and id in ["ball_sun","berry_bowl"]:
		var texture=CareArt.icon("ball" if id=="ball_sun" else "feed")
		var size=Vector2(16,16) if id=="ball_sun" else Vector2(25,20)
		canvas.draw_texture_rect(texture,Rect2(at-size/2,size),false,Color(1,1,1,alpha))
		return
	match id:
		"ball_sun":
			canvas.draw_circle(at,7,Color(0.88,0.73,0.44,alpha))
			canvas.draw_arc(at,7,0,TAU,24,Color(0.42,0.35,0.25,alpha),1)
			canvas.draw_line(at+Vector2(-5,-4),at+Vector2(5,4),Color(0.96,0.93,0.84,alpha),2)
		"berry_bowl":
			canvas.draw_style_box(_bowl_style(alpha),Rect2(at-Vector2(12,3),Vector2(24,12)))
			for offset in [Vector2(-6,-3),Vector2(0,-6),Vector2(6,-2)]: canvas.draw_circle(at+offset,4,Color(0.69,0.38,0.44,alpha))
		"blue_collar":
			canvas.draw_arc(at,10,0,TAU,24,Color(0.35,0.61,0.75,alpha),4)
			canvas.draw_rect(Rect2(at+Vector2(-3,5),Vector2(6,6)),Color(0.92,0.76,0.43,alpha))
static func _bowl_style(alpha: float) -> StyleBoxFlat:
	var s=StyleBoxFlat.new()
	s.bg_color=Color(0.6,0.7,0.74,alpha)
	s.set_corner_radius_all(4)
	return s
