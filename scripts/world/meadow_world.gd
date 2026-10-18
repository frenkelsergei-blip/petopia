class_name MeadowWorld
extends Node2D
## V2 connected Green Meadows (GDD V2 "Metroidvania connected world").
## Rooms come from data/world/green_meadows.json; progress lives in
## GameState.world(). Scenery is a seven-layer parallax built from separate
## transparent strips (GDD scroll factors), terrain is drawn from the meadow
## kit over plain rectangle colliders, and the child/Foxy reuse V1 actors.
signal status(message: String)
signal left_world

const ART="res://assets/art/meadows-v2/"
## [layer, scroll factor, bottom as fraction of view height, height fraction]
const BACK=[["sky",0.05,1.15,1.35],["mountains",0.10,0.78,0.55],["hills",0.20,0.86,0.42],["town",0.35,0.95,0.40],["midground",0.60,1.06,0.74]]
const FRONT=["foreground",1.20,1.10,0.38]
## Piece: fraction of image height from its top to the walking surface.
const SURFACE={"ground_top":0.24,"float_big":0.2,"float_small":0.22,"stone_ledge":0.24,"crystal_ledge":0.3,"scaffold":0.08,"stone":0.12,"bridge":0.62,"cap_left":0.22,"cap_right":0.22}

var game: GameState
var reduced_motion=false
var room_id=""
var room: Dictionary
var title="Green Meadows"
var prompt=""
var player: Explorer
var companion: Companion
var camera: WorldCamera
var content: Node2D
var fade: ColorRect
var transitioning=false
var elapsed=0.0
var near: Dictionary={}
var safe_point=Vector2.ZERO
var opened_at: Dictionary={}
var textures: Dictionary={}

class WorldCamera extends FollowCamera:
	var course_height=360.0
	func _ready() -> void:
		limit_left=0
		limit_right=int(course_width)
		limit_top=0
		limit_bottom=int(course_height)
		snap_to_target()
	## Horizontal follow as V1; vertical follow only outside a small dead zone,
	## so ordinary jumps do not bob the view but tall rooms scroll.
	func follow_target() -> void:
		if not is_instance_valid(target): return
		var half=get_viewport_rect().size*0.5/zoom
		var want_y=clampf(target.position.y-36,half.y,course_height-half.y)
		var y=position.y
		if absf(want_y-y)>28: y=move_toward(y,want_y,maxf(2.0,absf(want_y-y)-28))
		position=Vector2(clampf(target.position.x,half.x,course_width-half.x),clampf(y,half.y,course_height-half.y))
	func snap_to_target() -> void:
		if not is_instance_valid(target): return
		var half=get_viewport_rect().size*0.5/zoom
		position=Vector2(clampf(target.position.x,half.x,course_width-half.x),clampf(target.position.y-36,half.y,course_height-half.y))
		reset_physics_interpolation()
		reset_smoothing()

func tex(name: String) -> Texture2D:
	if not textures.has(name): textures[name]=ArtTexture.load_texture(ART+name+".png")
	return textures[name]

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_PAUSABLE
	var overlay=CanvasLayer.new()
	overlay.layer=5
	add_child(overlay)
	fade=ColorRect.new()
	fade.color=Color(0.05,0.08,0.14,0)
	fade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(fade)
	var w=game.world()
	enter(w.room,w.spawn)

## Build a room. Everything room-specific lives under `content`.
func enter(id: String, spawn: String) -> void:
	if not GameState.world_data().rooms.has(id): id=GameState.world_data().start[0]
	room_id=id
	room=GameState.world_data().rooms[id]
	title=room.title
	if is_instance_valid(content):
		remove_child(content)
		content.queue_free()
	content=Node2D.new()
	content.name="Room_"+id
	add_child(content)
	move_child(content,0)
	var size=Vector2(room.size[0],room.size[1])
	var spawns: Dictionary=room.spawns
	var at=spawns.get(spawn,spawns.values()[0])
	safe_point=Vector2(at[0],at[1])
	var back=Node2D.new()
	back.name="Parallax"
	back.z_index=-10
	back.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
	back.draw.connect(func(): draw_backdrop(back))
	content.add_child(back)
	var ground=Node2D.new()
	ground.name="Terrain"
	ground.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
	ground.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	ground.draw.connect(func(): draw_room(ground))
	content.add_child(ground)
	for r in rects("ground"): collider(r)
	for gate in room.get("gates",[]):
		if not game.has_ability(gate.ability): collider(Rect2(gate.rect[0],gate.rect[1],gate.rect[2],gate.rect[3]))
	player=Explorer.new()
	player.position=safe_point
	player.air_jumps=1 if game.has_ability("foxy_boost") else 0
	content.add_child(player)
	player.art.reduced_motion=reduced_motion
	companion=Companion.new()
	companion.leader=player
	companion.position=safe_point-Vector2(30,0)
	companion.anchor=safe_point
	companion.fall_limit=size.y+30
	companion.safe_anchors=safe_anchors()
	companion.jump_links=jump_links()
	content.add_child(companion)
	companion.art.child_stage=game.pet().growth_stage!="baby"
	companion.art.collar=game.pet().equipped_items.has("collar")
	companion.art.reduced_motion=reduced_motion
	var front=Node2D.new()
	front.name="Foreground"
	front.z_index=4
	front.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
	front.draw.connect(func(): draw_layer(front,FRONT))
	content.add_child(front)
	camera=WorldCamera.new()
	camera.target=player
	camera.course_width=size.x
	camera.course_height=size.y
	camera.position_smoothing_enabled=false
	content.add_child(camera)
	camera.make_current()
	game.world_enter(id,spawn)
	status.emit(room.title)

func rects(key: String) -> Array[Rect2]:
	var out: Array[Rect2]=[]
	for r in room.get(key,[]): out.append(Rect2(r[0],r[1],r[2],r[3]))
	return out

func collider(rect: Rect2) -> void:
	var body=StaticBody2D.new()
	body.position=rect.get_center()
	body.collision_layer=1
	body.collision_mask=0
	var shape=CollisionShape2D.new()
	var box=RectangleShape2D.new()
	box.size=rect.size
	shape.shape=box
	body.add_child(shape)
	content.add_child(body)

func safe_anchors() -> Array[Vector2]:
	var out: Array[Vector2]=[]
	for r in rects("ground"):
		var x=r.position.x+12
		while x<r.end.x-12:
			out.append(Vector2(x,r.position.y))
			x+=80
	return out

## Foxy follows across ledges a single jump apart (her own jump reaches ~48).
func jump_links() -> Array[Vector4]:
	var out: Array[Vector4]=[]
	var ground=rects("ground")
	for a in ground:
		for b in ground:
			if a==b: continue
			var rise=a.position.y-b.position.y
			if rise<-120 or rise>44: continue
			if b.position.x>=a.end.x-4 and b.position.x-a.end.x<=90:
				out.append(Vector4(a.end.x-6,a.position.y,b.position.x+14,b.position.y))
			elif b.end.x<=a.position.x+4 and a.position.x-b.end.x<=90:
				out.append(Vector4(a.position.x+6,a.position.y,b.end.x-14,b.position.y))
	return out

func view_rect() -> Rect2:
	var inverse=get_viewport().canvas_transform.affine_inverse()
	var size=Vector2(get_viewport().get_visible_rect().size)
	var a=inverse*Vector2.ZERO
	var b=inverse*size
	return Rect2(a,b-a)

## --- Parallax -------------------------------------------------------------
func draw_layer(canvas: CanvasItem, spec: Array, tint=Color.WHITE) -> void:
	var view=view_rect()
	var texture=tex(spec[0])
	var factor: float=spec[1]
	var height=view.size.y*float(spec[3])
	var width=height*texture.get_width()/texture.get_height()
	# Lower in the room = reference. Climbing moves far layers down slowly.
	var reference_top=float(room.size[1])-view.size.y
	var bottom=view.position.y+view.size.y*float(spec[2])-(view.position.y-reference_top)*factor*0.6
	var base=view.position.x*(1.0-factor)
	var first=floorf((view.position.x-base)/width)
	var x=base+first*width
	while x<view.end.x:
		canvas.draw_texture_rect(texture,Rect2(x,bottom-height,width+0.6,height),false,tint)
		x+=width

func draw_backdrop(canvas: CanvasItem) -> void:
	var view=view_rect()
	match room.get("scenery","meadow"):
		"cave":
			canvas.draw_rect(view.grow(4),Color("1b2236"))
			draw_tiled(canvas,"cave_wall",view.grow(4),0.45,0.35,Color(0.72,0.76,0.95))
		"tower":
			for spec in BACK.slice(0,3): draw_layer(canvas,spec)
			draw_tiled(canvas,"tower_wall",view.grow(4),0.5,0.3,Color(0.92,0.92,0.95))
		_:
			for spec in BACK: draw_layer(canvas,spec)

## Fill `area` with a tiling texture that scrolls at `factor`.
func draw_tiled(canvas: CanvasItem, name: String, area: Rect2, factor: float, scale_value: float, tint=Color.WHITE) -> void:
	var texture=tex(name)
	var offset=area.position*(1.0-factor)
	canvas.draw_set_transform(offset,0,Vector2.ONE*scale_value)
	var local=Rect2((area.position-offset)/scale_value,area.size/scale_value)
	canvas.draw_texture_rect(texture,local,true,tint)
	canvas.draw_set_transform(Vector2.ZERO)

## --- Room -------------------------------------------------------------------
func piece(canvas: CanvasItem, name: String, feet: Vector2, height: float, tint=Color.WHITE, flip=false) -> void:
	var texture=tex(name)
	var width=height*texture.get_width()/texture.get_height()
	if flip: canvas.draw_set_transform(Vector2(feet.x*2,0),0,Vector2(-1,1))
	canvas.draw_texture_rect(texture,Rect2(feet-Vector2(width*0.5,height),Vector2(width,height)),false,tint)
	if flip: canvas.draw_set_transform(Vector2.ZERO)

## Repeat a strip piece across [x0,x1], top of the walking surface at y.
func strip(canvas: CanvasItem, name: String, x0: float, x1: float, y: float, height: float, tint=Color.WHITE) -> void:
	var texture=tex(name)
	var width=height*texture.get_width()/texture.get_height()
	var top=y-height*float(SURFACE.get(name,0.2))
	var x=x0
	while x<x1-0.5:
		var w=minf(width,x1-x)
		canvas.draw_texture_rect_region(texture,Rect2(x,top,w+0.4,height),Rect2(0,0,texture.get_width()*w/width,texture.get_height()),tint)
		x+=w

func exposed(r: Rect2, side: float) -> bool:
	var probe=Vector2(r.position.x-2 if side<0 else r.end.x+2,r.position.y+6)
	for other in rects("ground"):
		if other!=r and other.size.y>20 and other.has_point(probe): return false
	return true

func draw_room(canvas: CanvasItem) -> void:
	var scenery: String=room.get("scenery","meadow")
	var tint=Color(0.62,0.68,0.9) if scenery=="cave" else (Color(0.85,0.86,0.9) if scenery=="tower" else Color.WHITE)
	if room.has("water"):
		var w=room.water
		MeadowCrossingKit.draw_river(canvas,Rect2(w[0],w[1],w[2],w[3]))
	decorate(canvas,scenery)
	var bridge=room.get("bridge",[])
	var index=0
	for r in rects("ground"):
		index+=1
		if not bridge.is_empty() and r==Rect2(bridge[0],bridge[1],bridge[2],bridge[3]):
			strip(canvas,"bridge",r.position.x-6,r.end.x+6,r.position.y,30)
		elif r.size.y<=20:
			var name="crystal_ledge" if scenery=="cave" else ("stone_ledge" if scenery=="tower" and index%2==0 else ("scaffold" if scenery=="tower" else ("float_big" if r.size.x>=110 else "float_small")))
			var texture=tex(name)
			var width=r.size.x*1.12
			var height=width*texture.get_height()/texture.get_width()
			canvas.draw_texture_rect(texture,Rect2(r.position.x-r.size.x*0.06,r.position.y-height*float(SURFACE[name]),width,height),false)
		else:
			# Earth body, then the grassy top strip, then rounded cliff ends.
			var fill=Rect2(r.position.x,r.position.y+10,r.size.x,r.size.y-10)
			canvas.draw_set_transform(Vector2.ZERO,0,Vector2.ONE*0.32)
			canvas.draw_texture_rect(tex("earth"),Rect2(fill.position/0.32,fill.size/0.32),true,tint)
			canvas.draw_set_transform(Vector2.ZERO)
			var lip="ground_top" if scenery=="meadow" else "stone"
			var lip_tint=Color(0.5,0.56,0.82) if scenery=="cave" else tint
			strip(canvas,lip,r.position.x,r.end.x,r.position.y,66 if lip=="ground_top" else 44,lip_tint)
			for side in [-1.0,1.0]:
				if scenery=="meadow" and exposed(r,side):
					var cap="cap_left" if side<0 else "cap_right"
					var h=78.0
					var w=h*tex(cap).get_width()/tex(cap).get_height()
					var x=r.position.x-w*0.3 if side<0 else r.end.x-w*0.7
					canvas.draw_texture_rect(tex(cap),Rect2(x,r.position.y-h*SURFACE[cap],w,h),false,tint)
	props(canvas)

## Grounded decoration on the wide floors, deterministic per room.
func decorate(canvas: CanvasItem, scenery: String) -> void:
	var kinds=[["flower_bush",30.0],["boulder",24.0],["fence",22.0],["lamp",56.0]]
	if scenery=="cave": kinds=[["crystals",34.0],["boulder",22.0]]
	if scenery=="tower": kinds=[["crate",26.0],["boulder",22.0]]
	var busy: Array[float]=[]
	for key in ["chests","signs"]:
		for entry in room.get(key,[]): busy.append(float(entry.pos[0]))
	for exit in room.get("exits",[]):
		if exit.has("door"): busy.append(float(exit.door[0]))
	if room.has("shrine"): busy.append(float(room.shrine.pos[0]))
	for r in rects("ground"):
		if r.size.y<=20: continue
		var x=r.position.x+70
		var i=int(r.position.x/37)
		while x<r.end.x-60:
			var clear=true
			for b in busy: clear=clear and absf(b-x)>60
			if clear:
				var kind=kinds[i%kinds.size()]
				piece(canvas,kind[0],Vector2(x,r.position.y+3),kind[1],Color(0.92,0.95,0.92) if scenery=="meadow" else Color(0.75,0.8,0.95),i%3==0)
			x+=150+float((i*53)%90)
			i+=1
	if scenery=="cave":
		for k in range(int(float(room.size[0])/220)):
			piece(canvas,"cave_vines",Vector2(110+k*220,236),90,Color(0.8,0.85,1))
	if scenery=="tower":
		for k in range(int(float(room.size[1])/180)):
			piece(canvas,"lantern",Vector2(40 if k%2==0 else float(room.size[0])-40,120+k*180),44)

func props(canvas: CanvasItem) -> void:
	var opened: Array=game.world().opened
	for exit in room.get("exits",[]):
		if exit.has("door"): piece(canvas,"cave" if exit.kind=="cave" else "door",Vector2(exit.door[0],exit.door[1]+2),72)
	for sign in room.get("signs",[]): piece(canvas,"sign",Vector2(sign.pos[0],sign.pos[1]+2),40)
	for gate in room.get("gates",[]):
		if not game.has_ability(gate.ability):
			var r=Rect2(gate.rect[0],gate.rect[1],gate.rect[2],gate.rect[3])
			piece(canvas,"thorn_gate",Vector2(r.get_center().x,r.end.y+2),r.size.y)
	if room.has("shrine"):
		var learned=game.has_ability(room.shrine.ability)
		var bob=0.0 if reduced_motion else sin(elapsed*2.2)*2.0
		piece(canvas,"shrine",Vector2(room.shrine.pos[0],room.shrine.pos[1]+2+(0.0 if learned else bob*0.3)),56,Color(0.75,0.75,0.8) if learned else Color.WHITE)
	for chest in room.get("chests",[]):
		var open=chest.id in opened
		piece(canvas,"chest_open" if open else "chest",Vector2(chest.pos[0],chest.pos[1]+2),28)
		if opened_at.has(chest.id):
			var t=elapsed-float(opened_at[chest.id])
			if t<2.2:
				var lift=minf(t,0.6)/0.6
				piece(canvas,chest.part,Vector2(chest.pos[0],chest.pos[1]-30-lift*22),26)
	var taken: Array=game.world().coins
	var coin=ArtTexture.load_texture(PetUI.COIN_PATH)
	var coins: Array=room.get("coins",[])
	for i in range(coins.size()):
		if "%s:%d"%[room_id,i] in taken: continue
		var bob=0.0 if reduced_motion else sin(elapsed*2.4+i)*1.5
		canvas.draw_texture_rect(coin,Rect2(coins[i][0]-7,coins[i][1]-7+bob,14,14),false)

## --- Play -------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	elapsed+=delta
	if not is_instance_valid(player) or transitioning: return
	var size=Vector2(room.size[0],room.size[1])
	var open_left=false
	var open_right=false
	for exit in room.get("exits",[]):
		if not exit.has("edge"): continue
		if exit.edge=="left": open_left=true
		if exit.edge=="right": open_right=true
		if (exit.edge=="left" and player.position.x<=10) or (exit.edge=="right" and player.position.x>=size.x-10):
			go(exit.to,exit.spawn)
			return
	# Walls only where there is no exit, so walking off an open edge always leaves.
	player.position.x=clampf(player.position.x,2.0 if open_left else 8.0,size.x-(2.0 if open_right else 8.0))
	if player.is_on_floor(): safe_point=player.position
	if player.position.y>size.y+40:
		player.reset_to(safe_point)
		status.emit("Oops! Back on solid ground.")
	collect_coins()
	find_near()
	if Input.is_action_just_pressed("interact"): use()
	if Input.is_action_just_pressed("pet_ability"): sniff()
	for node in content.get_children():
		if node is Node2D and node.name in ["Parallax","Terrain","Foreground"]: node.queue_redraw()

func collect_coins() -> void:
	var coins: Array=room.get("coins",[])
	var body=player.position-Vector2(0,15)
	for i in range(coins.size()):
		if body.distance_to(Vector2(coins[i][0],coins[i][1]))<16: game.world_collect_coin(room_id,i)

func find_near() -> void:
	near={}
	var feet=player.position
	var opened: Array=game.world().opened
	for chest in room.get("chests",[]):
		if not chest.id in opened and feet.distance_to(Vector2(chest.pos[0],chest.pos[1]))<34: near={"kind":"chest","data":chest}
	for exit in room.get("exits",[]):
		if exit.has("door") and feet.distance_to(Vector2(exit.door[0],exit.door[1]))<36: near={"kind":"door","data":exit}
	if room.has("shrine") and feet.distance_to(Vector2(room.shrine.pos[0],room.shrine.pos[1]))<42: near={"kind":"shrine","data":room.shrine}
	var line=""
	match near.get("kind",""):
		"chest": line="Use · Open the treasure chest"
		"door": line="Use · Go to "+near.data.label
		"shrine": line="Use · Touch the glowing feather" if not game.has_ability(near.data.ability) else "Foxy Boost: press Jump again in the air"
	if line.is_empty():
		for gate in room.get("gates",[]):
			if not game.has_ability(gate.ability) and absf(feet.x-gate.rect[0])<90: line=gate.text
		for sign in room.get("signs",[]):
			if feet.distance_to(Vector2(sign.pos[0],sign.pos[1]))<44: line=sign.text
		if room.has("boost_hint") and not game.has_ability("foxy_boost") and feet.x>room.boost_hint[0] and feet.x<room.boost_hint[1]:
			line="That ledge is too high. Maybe Foxy can learn something in the Hidden Cave!"
	if line.is_empty(): line=objective()
	prompt=line

func objective() -> String:
	var w=game.world()
	if not game.has_ability("foxy_boost"): return "Explore to the right. Find the Hidden Cave past the river."
	var missing=0
	for r in GameState.world_data().rooms.values():
		for chest in r.get("chests",[]):
			if not chest.id in w.opened: missing+=1
	if missing>0: return "Use Foxy Boost to reach high ledges. %d toy part%s still hidden."%[missing,"" if missing==1 else "s"]
	return "All robot parts found! Head home to build later."

func use() -> void:
	match near.get("kind",""):
		"chest":
			var chest=near.data
			if game.world_open_chest(chest.id,chest.part):
				opened_at[chest.id]=elapsed
				companion.react(Companion.State.CELEBRATE)
				status.emit("You found a toy part: %s! (+10 coins)"%GameState.world_data().parts[chest.part])
		"door": go(near.data.to,near.data.spawn)
		"shrine":
			var ability: String=near.data.ability
			if not game.has_ability(ability) and game.world_learn(ability):
				player.air_jumps=1
				companion.react(Companion.State.CELEBRATE)
				status.emit(GameState.world_data().abilities[ability].text)

## Foxy points the way to the nearest unopened chest in this room.
func sniff() -> void:
	var opened: Array=game.world().opened
	var best=Vector2.INF
	for chest in room.get("chests",[]):
		var at=Vector2(chest.pos[0],chest.pos[1])
		if not chest.id in opened and (best==Vector2.INF or at.distance_to(player.position)<best.distance_to(player.position)): best=at
	companion.react(Companion.State.INVESTIGATE)
	if best==Vector2.INF:
		status.emit("Foxy sniffs around... nothing hidden here.")
		return
	var way="to the right" if best.x>player.position.x+20 else ("to the left" if best.x<player.position.x-20 else "close by")
	if best.y<player.position.y-40: way+=", up high"
	status.emit("Foxy smells treasure "+way+"!")

func go(to: String, spawn: String) -> void:
	if to=="home":
		left_world.emit()
		return
	transitioning=true
	TouchControls.release_actions()
	if reduced_motion:
		enter(to,spawn)
		transitioning=false
		return
	var tween=create_tween()
	tween.tween_property(fade,"color:a",1.0,0.18)
	tween.tween_callback(func(): enter(to,spawn))
	tween.tween_property(fade,"color:a",0.0,0.22)
	tween.tween_callback(func(): transitioning=false)
