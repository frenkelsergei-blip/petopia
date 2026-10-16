class_name HomeArt
extends Node2D

var pet_art: PixelArt
var explorer: PixelArt
var state: GameState
var t = 0.0
var reaction = 0.0
var toy_preview = -1
var last_action = ""
var toy_play_time = 0.0
var toy_play_cooldown = 0.0
var bed_bounds=Rect2(430,164,196,104)
var bed_regions=[Rect2(40,140,944,500),Rect2(1064,140,944,500)]
var bed_texture: Texture2D
var room_texture: Texture2D
var sleep_texture: Texture2D
const ROOM_SCALE=2.7
# Presentation targets, not new biological thresholds or completed mature art.
# Baby/child retain their existing reference sizes; later stages grow gradually.
const STAGE_HEIGHTS={"baby":24.0,"child":30.0,"teen":34.0,"adult":38.0}
const SLEEP_REGIONS=[Rect2(192,128,736,496),Rect2(1120,128,768,496)]

func placed_toy_slot() -> int:
	if not is_instance_valid(state) or state.state.is_empty() or state.state.room_layout.is_empty(): return -1
	return int(state.state.room_layout[0].slot)

func toy_position(slot: int) -> Vector2:
	var offset=sin(toy_play_time*9)*7 if toy_play_time>0 and not pet_art.reduced_motion else 0.0
	return Vector2([330,415,530][slot]+offset,282)

func _ready() -> void:
	physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	bed_texture=load("res://assets/art/home-v1/bed-states.png")
	room_texture=load("res://assets/ui/adoption-v1/room.png")
	sleep_texture=load("res://assets/art/home-v1/foxy-sleep-v1.png")
	pet_art = GrayboxActor.new()
	pet_art.position = Vector2(370,252) if ArtStyle.enabled else Vector2(389,281)
	pet_art.scale = Vector2.ONE*(ROOM_SCALE if ArtStyle.enabled else 1.5)
	add_child(pet_art)
	explorer = GrayboxActor.new()
	explorer.kind = "child"
	explorer.position = Vector2(270,252) if ArtStyle.enabled else Vector2(332,280)
	explorer.scale = Vector2.ONE*(ROOM_SCALE if ArtStyle.enabled else 1.5)
	add_child(explorer)

func react_to(action: String) -> void:
	last_action = action
	reaction = 2.0

func _process(delta: float) -> void:
	t += delta
	reaction = maxf(0, reaction-delta)
	toy_play_time=maxf(0,toy_play_time-delta)
	toy_play_cooldown=maxf(0,toy_play_cooldown-delta)
	if is_instance_valid(state) and not state.state.is_empty():
		var p = state.pet()
		pet_art.visible=not (ArtStyle.enabled and p.sleeping)
		pet_art.child_stage = p.growth_stage != "baby"
		var base_height=30.0 if pet_art.child_stage else 24.0
		var stage_height=float(STAGE_HEIGHTS.get(p.growth_stage,24.0))
		pet_art.scale=Vector2.ONE*(ROOM_SCALE if ArtStyle.enabled else 1.5)*stage_height/base_height
		pet_art.collar = p.equipped_items.has("collar")
		pet_art.reduced_motion = state.state.settings.reduced_motion
		explorer.reduced_motion = pet_art.reduced_motion
		if p.sleeping:
			pet_art.position = Vector2(505,264)
			pet_art.mood = "sleep"
		else:
			var center=370.0 if ArtStyle.enabled else 410.0
			var goal = center + sin(t*0.3)*20 if not pet_art.reduced_motion else center
			if placed_toy_slot()>=0: goal = [330.0,415.0,530.0][placed_toy_slot()]-17
			var floor_y=252 if ArtStyle.enabled and placed_toy_slot()<0 else 281
			pet_art.position = pet_art.position.move_toward(Vector2(goal,floor_y),delta*18)
			if placed_toy_slot()>=0 and absf(pet_art.position.x-goal)<3 and toy_play_cooldown<=0:
				toy_play_time=1.5
				toy_play_cooldown=4
			pet_art.facing=1
			pet_art.mood = "happy" if reaction>0 or toy_play_time>0 else "idle"
	queue_redraw()

func bed_occupied() -> bool:
	return is_instance_valid(state) and not state.state.is_empty() and state.pet().sleeping

func sleep_region() -> Rect2:
	return SLEEP_REGIONS[0 if state.pet().growth_stage=="baby" else 1]

func sleep_bounds() -> Rect2:
	var region=sleep_region()
	var width=float(STAGE_HEIGHTS.get(state.pet().growth_stage,24.0))*ROOM_SCALE*1.25
	var height=width*region.size.y/region.size.x
	# The mattress and its front edge stay fixed; only the sleeping pet grows.
	var foot=Vector2(bed_bounds.get_center().x,231)
	return Rect2(foot-Vector2(width/2,height*479/496),Vector2(width,height))

func draw_room_art() -> void:
	draw_texture_rect(room_texture,Rect2(0,0,640,360),false)
	# Furniture is a separate stateful object, not baked into the room illustration.
	draw_texture_rect_region(bed_texture,bed_bounds,bed_regions[0])
	if bed_occupied():
		# Sleeping Foxy is independent from the furniture, so age cannot resize the
		# bed or turn every pet back into the baked baby on the old combined frame.
		draw_texture_rect_region(sleep_texture,sleep_bounds(),sleep_region())
		# Repaint the existing front bolster above the pet's lower contour.
		var front=Rect2(40,475,944,165)
		var dest=Rect2(bed_bounds.position+Vector2(0,335.0/500*bed_bounds.size.y),Vector2(bed_bounds.size.x,165.0/500*bed_bounds.size.y))
		draw_texture_rect_region(bed_texture,dest,front)

func box(x: float,y: float,w: float,h: float,c: String) -> void:
	draw_rect(Rect2(x,y,w,h),Color(c))

func _draw() -> void:
	box(0,0,640,360,"bdaf88")
	box(0,49,640,224,"c5ae7e")
	for y in range(52,270,22):
		box(0,y,640,2,"b29a6f")
		for x in range((y%3)*31,640,95): box(x,y+2,1,20,"c0a77a")
	box(0,266,640,94,"a48359")
	for y in range(269,360,18):
		box(0,y,640,2,"896d4d")
		for x in range((y%4)*21,640,90): box(x,y,1,18,"8c704e")
	# Sunny window with distant meadow.
	box(345,81,132,128,"846e49");box(351,87,120,116,"acd4d7")
	box(351,160,120,43,"8db88c");box(363,150,52,53,"9bc59a")
	box(406,139,58,64,"80ad88");box(407,87,5,116,"ebd6a5")
	box(351,141,120,5,"ebd6a5");box(341,202,140,7,"d4b77b")
	box(335,81,15,115,"f0dfb9");box(475,81,15,115,"f0dfb9")
	for x in [338,343,478,483]: box(x,84,2,108,"dcc89d")
	# Bookshelf and a pot.
	box(532,117,76,141,"6d6248");box(538,122,64,130,"a98b5c")
	for y in [156,195,233]: box(533,y,74,5,"695c42")
	for i in range(7): box(541+i*8,130+i%3*3,5,26-i%3*3,["6e8d82","b87551","d1b46f","8e9ea0"][i%4])
	box(549,172,18,18,"c7b087");box(577,168,17,22,"849a7e")
	box(546,212,49,16,"d8c6a0")
	# Cozy bed, clean bowl, wash tub.
	box(475,244,82,22,"675c45");box(479,242,74,18,"668273");box(484,239,64,12,"90a38a")
	box(481,238,18,11,"e8d6aa");box(474,261,8,9,"675c45");box(551,261,8,9,"675c45")
	box(250,268,27,13,"7b8e93");box(253,266,21,8,"bfdde0");box(257,267,12,4,"e0d5ae")
	box(208,250,35,29,"866b4d");box(210,253,31,7,"b6d4cf")
	for x in [211,221,232]: box(x,259,2,18,"b29464")
	# Rug, leaves, wall art.
	box(302,281,159,6,"617e62");box(296,287,172,10,"809b74");box(307,297,150,5,"617e62")
	for x in range(310,458,12): box(x,285,5,13,"b5bd8a")
	box(247,117,58,63,"806646");box(251,121,50,55,"f0dfb4")
	box(258,150,36,20,"809d71");box(269,133,14,23,"487459")
	box(597,263,24,22,"997353");box(600,258,18,6,"c09c69")
	for point in [[597,241],[613,228],[602,214],[622,246]]:
		box(point[0],point[1],7,22,"4c7958");box(point[0]-5,point[1],16,8,"6f9462")
	if is_instance_valid(state) and not state.state.is_empty():
		var slot = toy_preview
		if slot == -1 and not state.state.room_layout.is_empty(): slot = int(state.state.room_layout[0].slot)
		if slot >= 0:
			var x = [330,415,530][slot]
			draw_circle(Vector2(x,282),8,Color("e3ae53"));box(x-2,275,4,14,"f5dc8f")
			if toy_preview>=0: draw_arc(Vector2(x,282),13,0,TAU,24,Color("f9e4ac"),2)
