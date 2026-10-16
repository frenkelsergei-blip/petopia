class_name GardenPlayground
extends Node2D
## Home-garden presentation, intentionally independent of adventure level data.
var reduced_motion=false
var texture: Texture2D
func _ready() -> void:
	texture=load("res://assets/art/polish-v2/home-garden-scaled.png")
func _process(_delta: float) -> void: queue_redraw()
func _draw() -> void:
	if ArtStyle.enabled:
		draw_texture_rect(texture,Rect2(0,0,640,360),false)
		return
	draw_rect(Rect2(0,0,640,360),Color("d2dce2"))
	draw_rect(Rect2(0,235,640,125),Color("aebfaf"))
	draw_rect(Rect2(0,78,108,177),Color("a4b0b6"))
	draw_rect(Rect2(20,155,42,100),Color("839da1"))
	for x in range(100,640,22):
		draw_rect(Rect2(x,204,10,53),Color("b6ab95"))
	draw_rect(Rect2(100,218,540,7),Color("9d927d"))
	draw_rect(Rect2(100,242,540,7),Color("9d927d"))
