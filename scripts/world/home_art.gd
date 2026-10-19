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
var bed_bounds=Rect2(378,170,154,82)
var room_size=Vector2(640,360)
var floor_y=252.0
var pet_center=370.0
var action=""
var action_phase=""
var action_time=0.0
var action_frame=0
var action_goal=Vector2.ZERO
var explorer_goal=Vector2.ZERO
var action_finished=false
var care_feedback=""
var called_x=-1.0
var focus_pet=false
signal care_completed(action_name: String, success: bool)
var bed_regions=[Rect2(40,140,944,500),Rect2(1064,140,944,500)]
var bed_texture: Texture2D
var bowl_texture: Texture2D
var room_texture: Texture2D
var wide_room: Texture2D
var portrait_room: Texture2D
var idle_frames: Array[AtlasTexture]=[]
var idle_specs: Array=[]
## A52 pixel Foxy animations (assets/art/pet-v2, cut by tools/build_pet_anims.py).
var pet_sheets: Dictionary={}
var pet_frames: Dictionary={}
## Seconds left of the wake-up stretch.
var wake_time=0.0
var snore_in=1.5
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
	# P43: three spots on the leaf rug and the floor in front of it.
	if p43: return spot([380.0,560.0,700.0][slot],[410.0,418.0,410.0][slot])+Vector2(offset,0)
	return Vector2(([.42,.70,.83][slot]*room_size.x)+offset,floor_y+30)

func _ready() -> void:
	physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	bed_texture=ArtTexture.load_texture("res://assets/ui/room-paper/bed_back.png" if ArtStyle.paper else "res://assets/art/home-v1/bed-states.png")
	p43=ArtStyle.paper and ResourceLoader.exists(P43_DIR+"plate.png")
	if p43:
		FLOOR_REF=600.0
		BED=Vector2(175,430)
		BED_W=340.0
		# Bowls on the open floor in front of the rug (not under the bed).
		# Front-left as in P43, in front of the bed.
		FOOD_BOWL=Vector2(215,585)
		WATER_BOWL=Vector2(340,590)
		TUB=Vector2(800,505)
		BOWL_W=104.0
	wide_room=ArtTexture.load_texture((P43_DIR+"plate.png" if p43 else "res://assets/ui/room-paper/plate.png") if ArtStyle.paper else "res://assets/ui/adoption-v1/room.png")
	# A55: one paper room (concept P16) for both orientations, cropped to fit.
	portrait_room=wide_room if ArtStyle.paper else ArtTexture.load_texture("res://assets/art/home-flow-v1/room-portrait.png")
	room_texture=wide_room
	# Paper style: the paper heroes act in the room; the pixel idle sheet is not loaded.
	var idle_source: Texture2D=null if ArtStyle.paper else ArtTexture.load_texture("res://assets/art/home-flow-v1/idle-actors.png")
	idle_specs=[] if ArtStyle.paper else JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/home-flow-v1/idle-actors.json")).cells
	for cell in idle_specs:
		var r=cell.region
		var b=cell.visible_bounds
		var atlas=AtlasTexture.new()
		atlas.atlas=idle_source
		atlas.region=Rect2(r[0]+b[0],r[1]+b[1],b[2]-b[0],b[3]-b[1])
		atlas.filter_clip=true
		idle_frames.append(atlas)
	pet_frames=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/pet-v2/frames.json"))
	for set_name in pet_frames.sets: pet_sheets[set_name]=ArtTexture.load_texture("res://assets/art/pet-v2/%s.png"%set_name)
	pet_art = GrayboxActor.new()
	pet_art.in_home = true
	pet_art.position = Vector2(370,252) if ArtStyle.enabled else Vector2(389,281)
	pet_art.scale = Vector2.ONE*(ROOM_SCALE if ArtStyle.enabled else 1.5)
	add_child(pet_art)
	explorer = GrayboxActor.new()
	explorer.in_home = true
	explorer.kind = "child"
	explorer.position = Vector2(270,252) if ArtStyle.enabled else Vector2(332,280)
	explorer.scale = Vector2.ONE*(ROOM_SCALE if ArtStyle.enabled else 1.5)
	add_child(explorer)
	room_size=Vector2.ZERO
	layout_room(Vector2(640,360))

func room_scale() -> float:
	if not ArtStyle.enabled: return 1.5
	if ArtStyle.paper: return child_px()*unit()/42.0
	return room_size.y/210.0 if room_size.x<room_size.y else ROOM_SCALE

func layout_room(dimensions: Vector2) -> void:
	if room_size==dimensions: return
	var previous_floor=floor_y
	var previous_center=pet_center
	room_size=dimensions
	var portrait=dimensions.x<dimensions.y
	room_texture=portrait_room if portrait else wide_room
	floor_y=roundf(room_point(Vector2(500,1305)).y) if portrait else 252.0
	if ArtStyle.paper:
		# A56 (P20): the floor line in front of the rug; furniture around the pair.
		floor_y=roundf(room_point(Vector2(640,FLOOR_REF)).y)
		pet_center=roundf(spot(650,488).x)
	pet_center=roundf(dimensions.x*.62) if portrait else roundf(dimensions.x*.52)
	# P43: the pair stands on the leaf rug.
	if p43: pet_center=roundf(spot(520,488).x) if not portrait else roundf(dimensions.x*0.56)
	explorer.position=Vector2(pet_center-20*room_scale(),floor_y)
	explorer.scale=Vector2.ONE*room_scale()
	bed_bounds=Rect2(room_point(Vector2(642,918)),Vector2(150,80)) if portrait else Rect2(378+(dimensions.x-640)/2,170,154,82)
	if ArtStyle.paper: bed_bounds=Rect2(spot(250,340),spot(494,490)-spot(250,340))
	if p43: bed_bounds=Rect2(spot(BED.x-BED_W*0.34,BED.y-200),spot(BED.x+BED_W*0.48,BED.y-6)-spot(BED.x-BED_W*0.34,BED.y-200))

	if not busy(): pet_art.position=Vector2(pet_center,floor_y)
	else:
		pet_art.position+=Vector2(pet_center-previous_center,floor_y-previous_floor)
		action_goal=_goal_for(action)
		explorer_goal=Vector2(pet_center-47*room_scale()/ROOM_SCALE,floor_y) if action in ["feed","meal","water","pet"] else explorer.position
	queue_redraw()

func call_to(x: float) -> void:
	if busy(): return
	if state.pet().sleeping and not state.care("sleep"): return
	called_x=clampf(x,50,room_size.x-50)
	Sound.play("fox_yip",0.08)
	care_feedback="Here comes "+state.pet().name+"!"

func busy() -> bool: return not action.is_empty()

func wash_bounds() -> Rect2:
	var a=room_point(Vector2(0,800) if room_size.x<room_size.y else Vector2(0,365))
	var b=room_point(Vector2(272,1032) if room_size.x<room_size.y else Vector2(294,674))
	return Rect2(a,b-a)

## A56 (P20) room unit: plate pixels to screen. Landscape follows the plate;
## portrait keeps the whole furniture row on screen.
func unit() -> float:
	return room_size.y/720.0 if room_size.x>=room_size.y else room_size.x/680.0
func spot(x: float, y: float) -> Vector2:
	var cx=room_point(Vector2(612,FLOOR_REF)).x if room_size.x>=room_size.y else room_size.x*0.5
	return Vector2(cx+(x-612)*unit(),floor_y+(y-488)*unit())
var FOOD_BOWL=Vector2(600,600)
var WATER_BOWL=Vector2(860,600)
var TUB=Vector2(930,490)
## A57 (P43): the treehouse room. Plate and furniture from concept P43
## (assets/ui/room-p43); spot() keeps its units, the plate's floor line is
## at y=600 instead of 488. Bed left, bowls front left, tub on the right.
const P43_DIR="res://assets/ui/room-p43/"
var p43=false
var BED=Vector2(372,492)
var BED_W=250.0
var BOWL_W=96.0
var FLOOR_REF=488.0
var food_full=false
var water_full=false

## A56: Foxy's on-screen height by growth stage, as a share of the explorer
## (a baby fox is small; an adult stays shorter than the child).
const FOX_SHARE={"baby":0.34,"child":0.44,"teen":0.52,"adult":0.6}
func fox_px() -> float:
	return child_px()*unit()*float(FOX_SHARE.get(state.pet().growth_stage,0.34))
## Child height in plate pixels: P43's camera is closer, so the pair is bigger.
func child_px() -> float:
	return 390.0 if p43 else 290.0

func _goal_for(value: String) -> Vector2:
	if ArtStyle.paper:
		var fox=fox_px()
		match value:
			"feed","meal": return spot(FOOD_BOWL.x,FOOD_BOWL.y-8)+Vector2(fox*0.75,0)
			"water": return spot(WATER_BOWL.x,WATER_BOWL.y-8)+Vector2(fox*0.75,0)
			"clean": return spot(TUB.x,TUB.y-40)
			"sleep": return Vector2(bed_bounds.get_center().x,bed_bounds.end.y-20*unit())
	# The bath brings its own little tub, in the open where it is easy to see.
	if value=="clean": return Vector2(pet_center+10*room_scale(),floor_y)
	if value=="sleep": return Vector2(bed_bounds.get_center().x,bed_bounds.end.y)
	return Vector2(pet_center,floor_y)

func cancel_care() -> void:
	if not busy(): return
	action=""
	action_phase=""
	action_finished=false
	care_feedback="Care paused. Choose an activity when you are ready."
	pet_art.visible=not state.pet().sleeping
	explorer.visible=not focus_pet

## Food chosen in the food picker; "meal" uses it (kibble when empty).
var pending_food="kibble"
var food_chosen=false
## Serve a specific food from the food picker.
func request_food(id: String) -> bool:
	if busy(): return false
	pending_food=id
	food_chosen=true
	var okay=request_care("meal")
	food_chosen=false
	return okay
func request_care(value: String) -> bool:
	if busy() or value not in ["feed","meal","clean","pet","water","sleep"]: return false
	if value=="feed": pending_food="kibble"
	# V1 "meal" means the Berry bowl unless a food was picked.
	if value=="meal" and not food_chosen: pending_food="berry_bowl"
	if value=="meal" and state.food_count(pending_food)<1: return false
	if state.pet().sleeping and value!="sleep":
		if not state.care("sleep"): return false
	if value=="sleep" and state.pet().sleeping:
		var okay=state.care("sleep")
		if okay:
			care_feedback="Good morning, "+state.pet().name+"!"
			Sound.play("fox_yawn")
			pet_art.position=Vector2(bed_bounds.get_center().x,bed_bounds.end.y)
			wake_time=1.4
		return okay
	action=value
	last_action=value
	action_phase="approach"
	action_time=0
	action_frame=0
	action_finished=false
	action_goal=_goal_for(value)
	explorer_goal=Vector2(pet_center-(20 if value=="pet" else (26.0 if value in ["feed","meal","water"] else 47.0/ROOM_SCALE))*room_scale(),floor_y) if value in ["feed","meal","water","pet"] else explorer.position
	if ArtStyle.paper:
		var bowl=FOOD_BOWL if value in ["feed","meal"] else WATER_BOWL
		match value:
			"feed","meal","water": explorer_goal=spot(bowl.x-(95 if p43 else 80),bowl.y-6)
			"clean": explorer_goal=spot(TUB.x-(190 if p43 else 150),488)
			"pet": explorer_goal=Vector2(pet_center-(34 if p43 else 26)*room_scale(),floor_y)
	care_feedback={"feed":"Kibble for ","meal":GameState.foods().foods[pending_food].name+" for ","clean":"Bath time for ","water":"Fresh water for ","pet":"A little love for ","sleep":"Bedtime for "}[value]+state.pet().name+"…"
	return true

func react_to(value: String) -> void:
	last_action=value
	reaction=2.0

func _care_step(delta: float) -> void:
	if not busy(): return
	if action_phase=="approach":
		var difference=action_goal-pet_art.position
		pet_art.facing=signf(difference.x) if absf(difference.x)>2 else -1
		pet_art.mood="run"
		pet_art.travel_speed=54
		pet_art.position=pet_art.position.move_toward(action_goal,delta*(150*unit() if ArtStyle.paper else 74.0))
		explorer.facing=signf(explorer_goal.x-explorer.position.x) if absf(explorer_goal.x-explorer.position.x)>2 else 1
		explorer.travel_speed=50 if explorer.position.distance_to(explorer_goal)>1 else 0
		explorer.mood="run" if explorer.travel_speed>0 else "idle"
		explorer.position=explorer.position.move_toward(explorer_goal,delta*(150*unit() if ArtStyle.paper else 50.0))
		if pet_art.position.distance_to(action_goal)<1 and explorer.position.distance_to(explorer_goal)<1:
			action_phase="acting"
			action_time=0
			Sound.play({"feed":"fox_eat","meal":"fox_eat","water":"fox_drink","clean":"fox_bath","pet":"fox_purr","sleep":"fox_yawn"}[action])
		return
	action_time+=delta
	var frame_before=action_frame
	action_frame=mini(3,int(action_time/.55))
	if action_frame!=frame_before:
		if action=="clean" and action_frame==3: Sound.play("fox_shake")
		if action in ["feed","meal","water","pet"] and action_frame==3: Sound.play("fox_happy",0.08)
		if action in ["feed","meal","water"] and action_frame==1: Sound.play("child_yay",0.06,-5.0)
	explorer.mood="idle"
	explorer.travel_speed=0
	pet_art.mood="happy"
	pet_art.travel_speed=0
	if action_time<care_duration(): return
	var completed=action
	# Effects and consumables publish once, only after the care sequence reaches
	# completion and its existing durable transaction succeeds.
	var taste=""
	var okay=false
	if completed in ["feed","meal"]:
		taste=state.food_taste(pending_food)
		okay=state.feed_food(pending_food)
	else: okay=state.care(completed)
	action=""
	action_phase=""
	action_finished=okay
	var meal_line=" loved it, a favourite!" if taste=="like" else (" ate it, but it's not a favourite." if taste=="dislike" else " enjoyed the meal!")
	care_feedback=(state.pet().name+{"feed":meal_line,"meal":meal_line,"clean":" is clean and fluffy!","water":" feels refreshed!","pet":" loved that!","sleep":" is resting in bed."}[completed]) if okay else "Could not save care. Please try again."
	pet_art.visible=not state.pet().sleeping
	explorer.visible=true
	reaction=2.0
	care_completed.emit(completed,okay)

## Paper care runs longer: the explorer fills the bowl first, the bath has a
## hop in, bubbles and a shake.
func care_duration() -> float:
	if not ArtStyle.paper: return 2.4
	return {"feed":4.2,"meal":4.2,"water":3.8,"clean":4.4,"pet":2.6,"sleep":2.4}.get(action,2.4)

## A56: what the puppets do during each paper care step (time since acting).
func paper_act() -> void:
	var a=action_time
	var bowl=FOOD_BOWL if action in ["feed","meal"] else WATER_BOWL
	match action:
		"feed","meal","water":
			var filling=a<1.5
			# The boy kneels left of the bowl and pours; Foxy waits, then eats
			# or drinks head-down from the right.
			explorer.mood=("kneel_water" if action=="water" else "kneel_pour") if filling else "kneel_pet"
			explorer.facing=1
			pet_art.facing=-1
			pet_art.mood="sit" if filling else ("drink" if action=="water" else "eat")
			if a>0.8 and a<care_duration()-0.4:
				if action=="water": water_full=true
				else: food_full=true
			elif a>=care_duration()-0.4:
				water_full=water_full and action!="water"
				food_full=food_full and action=="water"
		"clean":
			explorer.mood="towel"
			explorer.facing=1
			var tub=spot(TUB.x,TUB.y-100)+Vector2(0,fox_px()*0.5)
			if a<0.5:
				var k=a/0.5
				pet_art.position=action_goal.lerp(tub,k)+Vector2(0,-sin(k*PI)*60*unit())
				pet_art.mood="jump"
			elif a<3.0:
				pet_art.position=tub
				pet_art.mood="bath"
			elif a<3.4:
				var k=(a-3.0)/0.4
				pet_art.position=tub.lerp(action_goal+Vector2(0,30*unit()),k)+Vector2(0,-sin(k*PI)*60*unit())
				pet_art.mood="jump"
			else:
				pet_art.position=action_goal+Vector2(0,30*unit())
				pet_art.mood="shake"
		"pet":
			explorer.mood="kneel_pet"
			explorer.facing=1
			pet_art.facing=-1
			pet_art.mood="petted"
		"sleep":
			pet_art.mood="sleep"

func _process(delta: float) -> void:
	t += delta
	reaction = maxf(0, reaction-delta)
	toy_play_time=maxf(0,toy_play_time-delta)
	toy_play_cooldown=maxf(0,toy_play_cooldown-delta)
	wake_time=maxf(0,wake_time-delta)
	# Soft snores while Foxy sleeps in its bed.
	if bed_occupied() and not busy():
		snore_in-=delta
		if snore_in<=0:
			snore_in=3.2
			Sound.play("fox_snore",0.04)
	if is_instance_valid(state) and not state.state.is_empty():
		var p = state.pet()
		pet_art.visible=not (ArtStyle.enabled and p.sleeping)
		pet_art.child_stage = p.growth_stage != "baby"
		var base_height=30.0 if pet_art.child_stage else 24.0
		var stage_height=float(STAGE_HEIGHTS.get(p.growth_stage,24.0))
		pet_art.scale=Vector2.ONE*room_scale()*stage_height/base_height
		if ArtStyle.paper:
			pet_art.growth=p.growth_stage
			pet_art.scale=Vector2.ONE*fox_px()/(pet_art.fox_height()*1.05)
		explorer.scale=Vector2.ONE*room_scale()
		pet_art.collar = p.equipped_items.has("collar")
		pet_art.reduced_motion = state.state.settings.reduced_motion
		explorer.reduced_motion = pet_art.reduced_motion
		if busy():
			_care_step(delta)
			var posing=action_phase=="acting" and ArtStyle.enabled
			pet_art.visible=not (ArtStyle.enabled and state.pet().sleeping) and not (posing and (action in ["feed","meal","clean","water","pet"] or (action=="sleep" and action_time>.5)))
			if ArtStyle.paper:
				# A56: the paper puppets act each care step; asleep Foxy is the
				# curled paper fox drawn in the bed.
				pet_art.visible=not state.pet().sleeping and not (action=="sleep" and action_phase=="acting")
				if action_phase=="acting": paper_act()
			explorer.visible=true
		elif p.sleeping:
			explorer.visible=true
			pet_art.position = Vector2(bed_bounds.get_center().x,bed_bounds.end.y-4)
			pet_art.mood = "sleep"
		else:
			explorer.visible=true
			var center=pet_center if ArtStyle.enabled else 410.0
			var goal = center
			if placed_toy_slot()>=0: goal = toy_position(placed_toy_slot()).x-17
			if called_x>=0: goal=called_x
			var resting_y=floor_y if ArtStyle.enabled else 281
			# Walking pace grows with the room (P43's camera is closer).
			var pace=maxf(70.0,room_size.x*0.08) if ArtStyle.paper and p43 else 34.0
			pet_art.position = pet_art.position.move_toward(Vector2(goal,resting_y),delta*pace)
			if placed_toy_slot()>=0 and absf(pet_art.position.x-goal)<3 and toy_play_cooldown<=0:
				toy_play_time=1.5
				toy_play_cooldown=4
			pet_art.facing=signf(goal-pet_art.position.x) if absf(goal-pet_art.position.x)>2 else -1
			pet_art.travel_speed=pace if absf(goal-pet_art.position.x)>2 else 0
			pet_art.mood = "run" if pet_art.travel_speed>0 else ("happy" if reaction>0 or toy_play_time>0 else "idle")
	if is_instance_valid(explorer) and not busy():
		var home_point=Vector2(pet_center-20*room_scale(),floor_y)
		var moving=explorer.position.distance_to(home_point)>1
		explorer.position=explorer.position.move_toward(home_point,delta*54)
		explorer.mood="run" if moving else "idle"
		explorer.travel_speed=54 if moving else 0
		explorer.facing=signf(home_point.x-explorer.position.x) if moving else 1
	apply_home_poses()
	if wake_time>0 and ArtStyle.enabled and not ArtStyle.paper: pet_art.visible=false
	if focus_pet: explorer.visible=false
	queue_redraw()

func apply_home_poses() -> void:
	if not is_instance_valid(explorer) or not is_instance_valid(pet_art): return
	explorer.home_pose=null
	pet_art.home_pose=null
	if not ArtStyle.enabled or idle_frames.is_empty(): return
	var frame=0 if state.pet().get("sleeping",false) or pet_art.reduced_motion else [0,0,0,1,2,1,0,3][int(t/.55)%8]
	# At meals the child kneels beside Foxy, watching and laughing.
	if action in ["feed","meal","water"] and action_phase=="acting": frame=[0,1,0,3][action_frame]
	# Petting: the child reaches out to Foxy, then laughs.
	if action=="pet" and action_phase=="acting": frame=[2,0,1,3][action_frame]
	if (not busy() or action in ["pet","feed","meal","water"]) and explorer.mood!="run": set_home_pose(explorer,frame)
	if (not busy() or action=="pet") and pet_art.mood!="run" and state.pet().growth_stage=="baby": set_home_pose(pet_art,4+frame)

func set_home_pose(actor: GrayboxActor, index: int) -> void:
	var spec=idle_specs[index]
	var b=spec.visible_bounds
	actor.home_pose=idle_frames[index]
	actor.home_pose_pivot=Vector2(spec.pivot[0]-b[0],spec.pivot[1]-b[1])
	actor.home_pose_body_height=idle_specs[0 if index<4 else 4].body_height

func bed_occupied() -> bool:
	return is_instance_valid(state) and not state.state.is_empty() and state.pet().sleeping

func sleep_region() -> Rect2:
	return SLEEP_REGIONS[0 if state.pet().growth_stage=="baby" else 1]

func sleep_bounds() -> Rect2:
	if ArtStyle.paper:
		# A56: the curled paper fox, sized by growth stage, centred in the bed.
		var w=fox_px()*(1.12 if p43 else 1.3)
		var tex=rt("fox_sleep")
		var h=w*tex.get_height()/tex.get_width()
		var foot=Vector2(bed_bounds.get_center().x,spot(0,478).y if not p43 else spot(0,BED.y-22).y)
		return Rect2(foot-Vector2(w*0.5,h),Vector2(w,h))
	var region=sleep_region()
	var width=float(STAGE_HEIGHTS.get(state.pet().growth_stage,24.0))*room_scale()*.74
	var height=width*region.size.y/region.size.x
	# The mattress and its front edge stay fixed; only the sleeping pet grows.
	var foot=Vector2(bed_bounds.get_center().x,bed_bounds.position.y+bed_bounds.size.y*.64)
	return Rect2(foot-Vector2(width/2,height*479/496),Vector2(width,height))

func room_source() -> Rect2:
	var source=Vector2(room_texture.get_size())
	var aspect=room_size.x/room_size.y
	var width=minf(source.x,source.y*aspect)
	var height=minf(source.y,source.x/aspect)
	if ArtStyle.paper: return Rect2(clampf(source.x*0.42-width/2,0,source.x-width),source.y-height,width,height)
	return Rect2((source.x-width)/2,source.y-height,width,height)

func room_point(point: Vector2) -> Vector2:
	var area=room_source()
	return (point-area.position)/area.size*room_size

## A56 room pieces (assets/ui/room-paper, tools/build_room_paper.py).
var room_tex: Dictionary={}
func rt(name: String) -> Texture2D:
	if not room_tex.has(name):
		var own=P43_DIR+name+".png"
		room_tex[name]=ArtTexture.load_texture(own if p43 and ResourceLoader.exists(own) else "res://assets/ui/room-paper/%s.png"%name)
	return room_tex[name]
## Draws a room piece by its bottom centre at plate scale.
func piece(name: String, foot: Vector2, width_plate: float, rot=0.0, alpha=1.0) -> void:
	var tex=rt(name)
	var w=width_plate*unit()
	var h=w*tex.get_height()/tex.get_width()
	draw_set_transform(foot,rot,Vector2.ONE)
	draw_texture_rect(tex,Rect2(-w*0.5,-h,w,h),false,Color(1,1,1,alpha))
	draw_set_transform(Vector2.ZERO)
var front_layer: Node2D
func draw_paper_room() -> void:
	draw_texture_rect_region(room_texture,Rect2(Vector2.ZERO,room_size),room_source())
	if not is_instance_valid(front_layer):
		front_layer=Node2D.new()
		front_layer.z_index=1
		front_layer.draw.connect(draw_paper_front)
		add_child(front_layer)
	front_layer.queue_redraw()
	if p43:
		# Soft paper contact shadows under the furniture (no hard ovals).
		for f in [[BED,BED_W*0.5],[TUB,110.0],[FOOD_BOWL,BOWL_W*0.55],[WATER_BOWL,BOWL_W*0.55]]:
			var at: Vector2=spot(f[0].x,f[0].y)
			var half: float=f[1]*unit()
			draw_set_transform(at,0,Vector2(1,0.2))
			draw_texture_rect(ContactShadow.soft(),Rect2(-half,-half,half*2,half*2),false,Color(1,1,1,0.5))
			draw_set_transform(Vector2.ZERO)
		piece("bed_back",spot(BED.x,BED.y),BED_W)
		piece("tub_back",spot(TUB.x,TUB.y),210)
		# Rims behind the actors when nobody is inside (see draw_paper_front).
		if not (bed_occupied() or (action=="sleep" and action_phase=="acting")): piece("bed_front",spot(BED.x+BED_W*0.09,BED.y+2),BED_W*0.83)
		if not (action=="clean" and action_phase=="acting" and action_time>0.3 and action_time<3.2): piece("tub_front",spot(TUB.x,TUB.y+2),210*352.0/330.0)
	else:
		var fs=Color(0.25,0.14,0.05,0.22)
		for x in [372,TUB.x,FOOD_BOWL.x,WATER_BOWL.x]:
			draw_set_transform(spot(x,0)+Vector2(0,floor_y-spot(0,0).y)+Vector2(0,(FOOD_BOWL.y-488 if x in [FOOD_BOWL.x,WATER_BOWL.x] else 0)*unit()),0,Vector2(1,0.18))
			draw_circle(Vector2.ZERO,(60 if x in [FOOD_BOWL.x,WATER_BOWL.x] else 130)*unit(),fs)
			draw_set_transform(Vector2.ZERO)
		piece("bed_back",spot(372,492),250)
		piece("tub_back",spot(TUB.x,TUB.y-62),200)
	var sleeping=bed_occupied() or (action=="sleep" and action_phase=="acting" and action_time>.3)
	if sleeping:
		var breathe=0.0 if pet_art.reduced_motion else sin(t*1.6)*0.02
		var r=sleep_bounds()
		draw_texture_rect(rt("fox_sleep"),Rect2(r.position.x,r.end.y-r.size.y*(1.0+breathe),r.size.x,r.size.y*(1.0+breathe)),false)

## A57 (P58): the placed sun ball on the floor (it rolls a little while Foxy
## plays); while decorating, glowing paper "+" spots and a see-through ball.
func draw_paper_toy(c: CanvasItem) -> void:
	if not is_instance_valid(state) or state.state.is_empty(): return
	var ball: Texture2D=ArtTexture.load_texture("res://assets/ui/decor-p32/sun_ball.png")
	var plus: Texture2D=ArtTexture.load_texture("res://assets/ui/decor-p32/plus.png")
	if ball==null: return
	var d=40.0*unit()
	var placed=placed_toy_slot()
	if decorating:
		for i in 3:
			var at=toy_position(i)
			var r=d*0.6*(1.0+(0.0 if pet_art.reduced_motion else sin(t*3+i)*0.05))
			if i!=toy_preview: c.draw_texture_rect(plus,Rect2(at-Vector2(r,r*2.0),Vector2(r,r)*2),false,Color(1,1,1,0.9))
	var slot=toy_preview if toy_preview>=0 else placed
	if slot<0: return
	var at2=toy_position(slot)
	var roll=0.0 if pet_art.reduced_motion else toy_play_time*4.0
	c.draw_set_transform(at2+Vector2(0,-d*0.5),roll,Vector2.ONE)
	c.draw_texture_rect(ball,Rect2(-Vector2(d,d)*0.5,Vector2(d,d)),false,Color(1,1,1,0.6 if toy_preview>=0 else 1.0))
	c.draw_set_transform(Vector2.ZERO)
var decorating=false

## In front of the puppets: bed and tub front rims, pouring, bubbles, Zs, hearts.
func draw_paper_front() -> void:
	var c=front_layer
	var pc=func(name: String, foot: Vector2, wp: float, rot=0.0, alpha=1.0):
		var tex=rt(name)
		var w=wp*unit()
		var h=w*tex.get_height()/tex.get_width()
		c.draw_set_transform(foot,rot,Vector2.ONE)
		c.draw_texture_rect(tex,Rect2(-w*0.5,-h,w,h),false,Color(1,1,1,alpha))
		c.draw_set_transform(Vector2.ZERO)
	draw_paper_toy(c)
	# The rims go over the actors only while Foxy is inside the bed or the
	# tub; otherwise the boy would look as if he stood inside them.
	var in_bed=bed_occupied() or (action=="sleep" and action_phase=="acting")
	if p43:
		if in_bed: pc.call("bed_front",spot(BED.x+BED_W*0.09,BED.y+2),BED_W*0.83)
	else: pc.call("bed_front",spot(372,500),250)
	if action=="clean" and action_phase=="acting" and action_time>0.4 and action_time<3.1:
		# Rubber duck bobbing on the bath water, inside the tub.
		pc.call("duck",spot(TUB.x+55,TUB.y-(118 if p43 else 44)+(0.0 if pet_art.reduced_motion else sin(t*3)*2)),34,sin(t*3)*0.12)
	var in_tub=action=="clean" and action_phase=="acting" and action_time>0.3 and action_time<3.2
	if p43 and in_tub: pc.call("tub_front",spot(TUB.x,TUB.y+2),210*352.0/330.0)
	else: pc.call("tub_front",spot(TUB.x,TUB.y+4),200)
	# Bowls stand in front of the pair (eating Foxy's head dips behind the rim).
	pc.call("bowl_food_full" if food_full else "bowl_food",spot(FOOD_BOWL.x,FOOD_BOWL.y),BOWL_W)
	pc.call("bowl_water_full" if water_full else "bowl_water",spot(WATER_BOWL.x,WATER_BOWL.y),BOWL_W)
	var a=action_time
	if action_phase=="acting":
		var bowl=FOOD_BOWL if action in ["feed","meal"] else WATER_BOWL
		if action in ["feed","meal","water"] and a<1.5:
			var tip=sin(minf(a,0.4)/0.4*PI*0.5)*0.6
			var hand=spot(bowl.x-14,bowl.y-140)
			if not p43: pc.call("kibble_bag" if action!="water" else "watering_can",hand,80,tip)
			if a>0.35: pc.call("kibble_stream" if action!="water" else "water_stream",spot(bowl.x+6,bowl.y-30),40,0.0,clampf((a-0.35)*4,0,1))
		if action=="clean":
			var tub=spot(TUB.x,TUB.y-40)
			if a>0.4 and a<3.1:
				pc.call("foam",spot(TUB.x-40,TUB.y-(108 if p43 else 2)),100)
				for i in 6:
					var life=fposmod(t*0.6+i*0.17,1.0)
					var x=tub.x+(i-2.5)*28*unit()+sin(t*2+i)*10*unit()
					pc.call("bubble" if i%2==0 else "bubbles",Vector2(x,tub.y-life*170*unit()),26+i%3*8,0.0,1.0-life)
			if a>3.4:
				for i in 8:
					var life=fposmod((a-3.4)*1.6+i*0.13,1.0)
					var dir=Vector2(cos(i*0.8),-0.6+sin(i*1.7)*0.3).normalized()
					pc.call("drop",pet_art.position+Vector2(0,-50*unit())+dir*life*150*unit(),16,0.0,1.0-life)
		if action=="pet" and a>0.3:
			for i in 3:
				var life=fposmod(a*0.8+i*0.33,1.0)
				pc.call("heart",pet_art.position+Vector2((i-1)*30*unit(),-110*unit()-life*80*unit()),30,0.0,1.0-life)
	if bed_occupied() or (action=="sleep" and action_phase=="acting" and a>.3):
		for i in 3:
			var life=fposmod(t*0.35+i*0.33,1.0)
			pc.call("zzz",spot(400+life*60,400-life*120),20+i*6,0.0,1.0-life)
	elif not busy() and is_instance_valid(state) and not state.state.is_empty():
		# Foxy asks: sits by the empty bowl with a little thought bubble.
		var need=state.pet().needs
		var ask=""
		if float(need.get("fullness",100))<35 and not food_full: ask="bowl_food"
		elif float(need.get("energy",100))<25: ask="zzz"
		if not ask.is_empty():
			var top=pet_art.position+Vector2(0,-fox_px()*1.3)
			var bob=0.0 if pet_art.reduced_motion else sin(t*3)*4
			c.draw_circle(top+Vector2(0,bob),30*unit(),Color(1,0.98,0.92))
			c.draw_arc(top+Vector2(0,bob),30*unit(),0,TAU,32,Color(0.55,0.36,0.18),2.0)
			pc.call(ask,top+Vector2(0,bob+14*unit()),38)

func draw_room_art() -> void:
	if ArtStyle.paper:
		draw_paper_room()
		return
	draw_texture_rect_region(room_texture,Rect2(Vector2.ZERO,room_size),room_source())
	if not (action_phase=="acting" and action in ["feed","meal","water"]) or ArtStyle.paper:
		if bowl_texture==null: bowl_texture=ArtTexture.load_texture("res://assets/ui/details-paper/icon_food.png") if ArtStyle.paper else CareArt.icon("feed")
		var bowl: Texture2D=bowl_texture
		bowl.draw_rect(get_canvas_item(),Rect2(pet_center-46,floor_y-6,44,30),false)
	if ArtStyle.paper: return
	# Furniture is a separate stateful object, not baked into the room illustration.
	draw_texture_rect_region(bed_texture,bed_bounds,bed_regions[0])
	if bed_occupied() or (action=="sleep" and action_phase=="acting" and action_time>.5):
		# Sleeping Foxy is independent from the furniture, so age cannot resize the
		# bed or turn every pet back into the baked baby on the old combined frame.
		# Curled up asleep, breathing slowly (two frames).
		var breath=1 if pet_art.reduced_motion or int(t/1.3)%2==0 else 2
		var foot=Vector2(bed_bounds.get_center().x+4*room_scale(),bed_bounds.position.y+bed_bounds.size.y*.66)
		_pet_frame("sleep",breath,foot)
		# Repaint the existing front bolster above the pet's lower contour.
		var front=Rect2(40,475,944,165)
		var dest=Rect2(bed_bounds.position+Vector2(0,335.0/500*bed_bounds.size.y),Vector2(bed_bounds.size.x,165.0/500*bed_bounds.size.y))
		draw_texture_rect_region(bed_texture,dest,front)
	if action_phase=="acting": draw_care_actors()
	if wake_time>0 and not busy():
		_pet_frame("sleep",3,Vector2(bed_bounds.get_center().x-6*room_scale(),floor_y))

func draw_care_actors() -> void:
	if not ArtStyle.enabled or action.is_empty(): return
	if action in ["feed","meal","water"]:
		# The child kneels beside Foxy (idle poses); Foxy eats or drinks.
		_pet_frame("drink" if action=="water" else "eat",action_frame,Vector2(pet_center+_pet_gap(),floor_y))
	elif action=="clean":
		# In the tub with bubbles, bubbles on the head, wet, then a big shake.
		_pet_frame("bathe",action_frame,action_goal)

	elif action=="pet":
		# Leans into the hand, wags, rolls over, then a happy heart.
		_pet_frame("pet",action_frame,Vector2(pet_center+_pet_gap()*0.6,floor_y))

## Bigger Foxes stand a little farther from the kneeling child.
func _pet_gap() -> float:
	return 4.0+(float(STAGE_HEIGHTS.get(state.pet().growth_stage,24.0))-16.0)*room_scale()*0.75

## Draws one pixel Foxy frame with its feet at `at`, sized so the standing
## Foxy matches the growth-stage height used everywhere else in the room.
func _pet_frame(set_name: String, index: int, at: Vector2, flip=false) -> void:
	if not pet_sheets.has(set_name): return
	var frame: Dictionary=pet_frames.sets[set_name][index]
	var standing: float=pet_frames.sets.eat[1].content[3]
	var factor=float(STAGE_HEIGHTS.get(state.pet().growth_stage,24.0))*room_scale()/standing
	var r=Rect2(frame.region[0],frame.region[1],frame.region[2],frame.region[3])
	var pivot=Vector2(frame.pivot[0]-r.position.x,frame.pivot[1]-r.position.y)*factor
	if flip: draw_set_transform(Vector2(at.x*2,0),0,Vector2(-1,1))
	draw_texture_rect_region(pet_sheets[set_name],Rect2(at-pivot,r.size*factor),r)
	if flip: draw_set_transform(Vector2.ZERO)

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
