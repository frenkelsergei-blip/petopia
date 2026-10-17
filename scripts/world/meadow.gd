class_name Meadow
extends Node2D

var camera_x = 0.0
var elapsed = 0.0
var reduced_motion = false
var ground: Array[Rect2] = []
var bridge = false
var secret = false
var basket = false
var pickups: Array = []
var coin_texture: Texture2D

func _ready() -> void:
	coin_texture = ArtTexture.load_texture(PetUI.COIN_PATH)

func _process(delta: float) -> void:
	if not reduced_motion: elapsed += delta
	queue_redraw()

func rect(x: float, y: float, w: float, h: float, c: String) -> void:
	draw_rect(Rect2(x,y,w,h), Color(c))

func tree(x: float, y: float, scale_value: float = 1.0) -> void:
	draw_set_transform(Vector2(x,y),0,Vector2.ONE*scale_value)
	rect(-8,-75,17,75,"5b5740"); rect(-5,-74,6,72,"887452")
	for v in [Vector2(-30,-83),Vector2(8,-88),Vector2(-12,-106),Vector2(-34,-112),Vector2(16,-115),Vector2(-8,-133)]:
		rect(v.x-19,v.y-15,43,34,"326852")
		rect(v.x-16,v.y-18,36,29,"477d58")
		rect(v.x-12,v.y-18,24,8,"66935c")
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	rect(camera_x,0,640,360,"9bcddd")
	rect(camera_x,150,640,100,"b9d9d5")
	for i in range(-1, 8):
		var x = camera_x + fposmod(i*155.0-camera_x*0.16, 900.0)-150
		draw_polygon(PackedVector2Array([Vector2(x,210),Vector2(x+100,85+i%3*15),Vector2(x+210,210)]),PackedColorArray([Color("82b5b7")]))
	for i in range(11):
		var x = camera_x+fposmod(i*100.0-camera_x*0.3,800.0)-80
		rect(x,208,110,40,"78aa91"); rect(x+15,191,65,25,"78aa91")
	for i in range(7):
		var x = camera_x+fposmod(i*157.0-camera_x*0.10+elapsed*1.5,950.0)-150
		rect(x,52+i%3*21,70,12,"e3f0e5"); rect(x+15,44+i%3*21,35,20,"e3f0e5")
	# Water remains visible below the constructed bridge.
	rect(900,280,180,80,"5cacc0")
	for j in range(5):
		for i in range(7): rect(905+i*27+sin(elapsed*2+j)*3,295+j*11,14,2,"b4e2dd")
	for i in range(24):
		var x = i*167.0+60
		if absf(x-camera_x-320)<480: tree(x,286,0.75 if i%3 else 1.15)
	for r in ground:
		draw_rect(r,Color("8b7550"))
		draw_rect(Rect2(r.position,Vector2(r.size.x,7)),Color("4c8050"))
		draw_rect(Rect2(r.position,Vector2(r.size.x,3)),Color("a3bd67"))
		for x in range(int(r.position.x),int(r.end.x),16):
			for y in range(int(r.position.y)+12,360,16):
				if (x/16+y/16)%3==0: rect(x+3,y,6,3,"a28c61")
	if bridge:
		for x in range(900,1080,12):
			rect(x,281,11,7,"a5804f"); rect(x,281,11,2,"d6b57b")
	for i in range(260):
		var x = i*15+7
		if x>895 and x<1085: continue
		var y = 286
		if absf(x-camera_x-320)>380: continue
		rect(x,y-5,2,5,"46784d")
		if i%3==0:
			rect(x-2,y-8,6,3,"e4c984" if i%2 else "e9dacc"); rect(x,y-9,2,5,"f4df9e")
	for i in range(20):
		if i in pickups: continue
		var x = 330+i*133
		var y = 249+sin(elapsed*2+i)*3
		if coin_texture != null: draw_texture_rect(coin_texture,Rect2(x-8,y-8,16,16),false)
	# Bridge crank and checkpoint, all original shapes.
	rect(842,259,7,29,"7b6646"); draw_circle(Vector2(845,261),9,Color("526965")); draw_arc(Vector2(845,261),6,0,TAU,16,Color("c4c9a2"),2)
	rect(1128,246,4,42,"7d6548"); rect(1132,246,22,14,"edc975")
	rect(1900,282,32,6,"96774e")
	if secret:
		rect(1899,267,27,18,"8b603e"); rect(1901,265,23,8,"c99c57"); rect(1910,271,5,7,"f4dd89")
	else:
		for i in range(3): rect(1906+i*9,275-i%2*4,4,2,"d5c5a0")
	if not basket:
		rect(3030,269,25,16,"b88b53"); rect(3033,266,19,5,"edd39d")
		draw_arc(Vector2(3043,268),9,PI,TAU,12,Color("92683f"),3)
		rect(3034,267,8,4,"e6a2a2"); rect(3044,267,8,4,"f2e1b0")
	rect(3095,251,5,37,"7b6646"); rect(3082,248,40,14,"b99361")
	# Picnic blanket at arrival.
	rect(130,284,68,4,"c68f80")
	for x in range(132,198,10): rect(x,284,5,3,"eee1b9")
