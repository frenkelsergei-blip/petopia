class_name MeadowWorld
extends Node2D
## V2 connected Green Meadows (GDD V2 "Metroidvania connected world").
## Rooms come from data/world/green_meadows.json; progress lives in
## GameState.world(). Scenery is a seven-layer parallax built from separate
## transparent strips (GDD scroll factors), terrain is drawn from the meadow
## kit over plain rectangle colliders, and the child/Foxy reuse V1 actors.
signal status(message: String)
signal left_world
signal ability_learned(title: String, text: String)

const ART="res://assets/art/meadows-v2/"
## [layer, scroll factor, bottom as fraction of view height, height fraction]
const BACK=[["sky",0.05,1.15,1.35],["mountains",0.10,0.78,0.55],["hills",0.20,0.86,0.42],["town",0.35,0.95,0.40],["midground",0.60,1.06,0.74]]
const FRONT=["foreground",1.20,1.10,0.38]
## Hidden Cave depth: far cavern, distant formations, near pillars (each
## layer has hanging stalactites at its top and rocks at its bottom), and a
## dark foreground frame in front of the play area.
const CAVE_BACK=[["cave_far",0.08,1.0,1.0],["cave_back",0.20,1.0,1.0],["cave_mid",0.45,1.02,1.0]]
const CAVE_FRONT=["cave_front",1.20,1.04,1.0]
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
var crate_bodies: Array[StaticBody2D]=[]
var digging=""
var dig_until=0.0
var popped: Dictionary={}
## What the two context buttons do right now: action -> [caption, icon].
var faces={"interact":["Use","act_use"],"pet_ability":["Find","act_find"]}
const CRATE=24.0
## Challenge (kid-friendly): hearts are lost on thorns, critters and falls;
## at zero the child returns to the last lantern with full hearts and keeps
## everything collected. No game over.
const MAX_HEARTS=3
var hearts=MAX_HEARTS
var hurt_until=0.0
var critters: Array[Dictionary]=[]
const GATES={"home":"gate_home","meadow_fields":"gate_meadow","river_crossing":"gate_river"}
## Friendly critters per place: they bump you back gently; hop on top to make
## them dizzy for a moment. Flyers bob up and down on their path.
const CRITTERS={
	"hedgehog":{"art":"hedgehog","h":22.0,"speed":28.0,"fly":false,"anim":5.0,"stomp":"Boing! The hedgehog curls up for a moment.","bump":"The hedgehog bumped you! Hop on top of it."},
	"crab":{"art":"crab","h":20.0,"speed":22.0,"fly":false,"anim":6.0,"stomp":"Boing! The crystal crab takes a little nap.","bump":"The crystal crab pinched you! Hop on top of it."},
	"frog":{"art":"frog","h":20.0,"speed":26.0,"fly":false,"anim":3.0,"stomp":"Boing! The frog sits down, a bit dizzy.","bump":"The frog bumped you! Hop on top of it."},
	"bat":{"art":"bat","h":20.0,"speed":34.0,"fly":true,"anim":8.0,"stomp":"Boing! The bat flips over, dizzy.","bump":"The bat flapped into you! Jump on it or wait for it to pass."},
	"bee":{"art":"bee","h":18.0,"speed":26.0,"fly":true,"anim":10.0,"stomp":"Boing! The bumblebee buzzes in circles.","bump":"The bumblebee bumped you! Jump on it or wait for it to pass."}}
var movers: Array[Dictionary]=[]
var crumbles: Array[Dictionary]=[]
var arrival_title=""
var entry_point=Vector2.ZERO
var bridge_progress=1.0
var moss: PicnicResident
var lag_time=0.0
var regrow_at: Dictionary={}
var super_jump=false
## Crates stay in the bag until you choose "Place a crate" there; only then
## does Use become Place with a see-through crate in front of you.
var placing=false
var crank_angle=0.0
var bridge_body: StaticBody2D
var plate_gates: Dictionary={}
var leaves: Array[Vector3]=[]
var arrival_until=0.0
signal hearts_changed(value: int)

class WorldCamera extends FollowCamera:
	var course_height=360.0
	## Smooth view: follow the child's interpolated (on-screen) position every
	## rendered frame, so the parallax layers drawn from this camera never
	## shake against the screen.
	func _init() -> void:
		super._init()
		process_callback=Camera2D.CAMERA2D_PROCESS_IDLE
		physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	var prev_at=Vector2.ZERO
	var cur_at=Vector2.ZERO
	# Runs after the child moved (priority 100): remember the last two steps.
	func _physics_process(_delta: float) -> void:
		if not is_instance_valid(target): return
		prev_at=cur_at
		cur_at=target.position
	func _process(_delta: float) -> void: follow_target()
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
		if cur_at==Vector2.ZERO or cur_at.distance_to(target.position)>60:
			prev_at=target.position
			cur_at=target.position
		var at: Vector2=prev_at.lerp(cur_at,Engine.get_physics_interpolation_fraction())
		# The HUD covers the top of the screen: keep the child in the lower middle.
		var want_y=clampf(at.y-56,half.y,course_height-half.y)
		var y=position.y
		if absf(want_y-y)>14: y=lerpf(y,want_y-signf(want_y-y)*14.0,clampf(get_process_delta_time()*8.0,0.0,1.0))
		position=Vector2(clampf(at.x,half.x,course_width-half.x),clampf(y,half.y,course_height-half.y))
	func snap_to_target() -> void:
		if not is_instance_valid(target): return
		var half=get_viewport_rect().size*0.5/zoom
		prev_at=target.position
		cur_at=target.position
		position=Vector2(clampf(target.position.x,half.x,course_width-half.x),clampf(target.position.y-56,half.y,course_height-half.y))
		reset_physics_interpolation()
		reset_smoothing()

func tex(name: String) -> Texture2D:
	if not textures.has(name): textures[name]=ArtTexture.load_texture(ART+name+".png")
	return textures[name]

## Scenery is redrawn every rendered frame from the smooth camera.
func _process(_delta: float) -> void:
	if not is_instance_valid(content): return
	for node in content.get_children():
		if node is Node2D and node.name in ["Parallax","Walls","Terrain","Foreground"]: node.queue_redraw()

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
	if not room_id.is_empty() and room_id!=id: bring_crates_along()
	var place: String=GameState.world_data().rooms[id].get("scenery","meadow")
	Sound.music("meadow" if place=="meadow" else "cave")
	placing=false
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
	entry_point=safe_point
	# Strips must not wrap: with repeat on, each layer's top edge sampled its
	# own opaque bottom row and drew a dark line across the screen.
	var back=Node2D.new()
	back.name="Parallax"
	back.z_index=-10
	back.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	back.draw.connect(func(): draw_backdrop(back))
	content.add_child(back)
	var walls=Node2D.new()
	walls.name="Walls"
	walls.z_index=-9
	walls.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
	walls.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	walls.draw.connect(func(): draw_walls(walls))
	content.add_child(walls)
	# Only true tiling fills repeat. Every other sprite draws with repeat off:
	# with it on, phones' odd scaling sampled each sprite's opposite edge and
	# drew thin dark lines along tops of ground strips, props and gates.
	var fills=Node2D.new()
	fills.name="TerrainFill"
	fills.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
	fills.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	fills.draw.connect(func(): draw_fills(fills))
	content.add_child(fills)
	var ground=Node2D.new()
	ground.name="Terrain"
	ground.texture_repeat=CanvasItem.TEXTURE_REPEAT_DISABLED
	ground.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	ground.draw.connect(func(): draw_room(ground))
	content.add_child(ground)
	var bridge_spec=room.get("bridge",[])
	bridge_progress=0.0 if bridge_locked() else 1.0
	for r in rects("ground"):
		var is_bridge=not bridge_spec.is_empty() and r==Rect2(bridge_spec[0],bridge_spec[1],bridge_spec[2],bridge_spec[3])
		if is_bridge and bridge_locked(): continue
		var made=collider(r,r.size.y<=20 and not is_bridge)
		if is_bridge: bridge_body=made
	if room.has("ceiling"):
		var c=room.ceiling
		collider(Rect2(c[0],c[1],c[2],c[3]))
	for gate in room.get("gates",[]):
		if not game.has_ability(gate.ability): collider(Rect2(gate.rect[0],gate.rect[1],gate.rect[2],gate.rect[3]))
	build_challenge()
	player=Explorer.new()
	player.position=safe_point
	player.air_jumps=1 if game.has_ability("foxy_boost") else 0
	player.boosted.connect(func(): boost_at=player.position; boost_until=elapsed+0.35)
	player.landed.connect(func(): dust(player.position,5,8.0))
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
	companion.art.growth=game.pet().growth_stage
	companion.art.collar=game.pet().equipped_items.has("collar")
	companion.art.reduced_motion=reduced_motion
	build_crates()
	moss=null
	if room.has("npc"):
		moss=PicnicResident.new()
		moss.reduced_motion=reduced_motion
		moss.position=Vector2(room.npc.pos[0],room.npc.pos[1])
		content.add_child(moss)
	var front=Node2D.new()
	front.name="Foreground"
	front.z_index=4
	front.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	front.draw.connect(func(): draw_layer(front,CAVE_FRONT if room.get("scenery","meadow")=="cave" else FRONT); draw_ambient(front))
	content.add_child(front)
	camera=WorldCamera.new()
	camera.target=player
	camera.course_width=size.x
	camera.course_height=size.y
	camera.position_smoothing_enabled=false
	content.add_child(camera)
	camera.make_current()
	game.world_enter(id,spawn)
	arrival_title=room.title
	arrival_until=elapsed+1.6
	status.emit(room.title)

## Moving log rafts, crumbling stone and critters for this room.
func build_challenge() -> void:
	critters.clear()
	movers.clear()
	crumbles.clear()
	for c in room.get("critters",[]):
		var kind: String=c.get("kind","hedgehog")
		critters.append({"kind":kind,"x":float(c.x0),"x0":float(c.x0),"x1":float(c.x1),"y":float(c.y),"cy":float(c.y),"dir":1.0,"dizzy":0.0,"seed":float(c.x0)*0.01})
	for m in room.get("movers",[]):
		var r=Rect2(m.rect[0],m.rect[1],m.rect[2],m.rect[3])
		var body=AnimatableBody2D.new()
		body.sync_to_physics=true
		body.position=r.get_center()
		body.collision_layer=1
		body.collision_mask=0
		var shape=CollisionShape2D.new()
		var box=RectangleShape2D.new()
		box.size=r.size
		shape.shape=box
		shape.one_way_collision=true
		body.add_child(shape)
		content.add_child(body)
		movers.append({"body":body,"base":r.get_center(),"to":Vector2(m.to[0],m.to[1]),"period":float(m.period),"size":r.size})
	plate_gates.clear()
	for g in room.get("plate_gates",[]):
		var r=Rect2(g.rect[0],g.rect[1],g.rect[2],g.rect[3])
		var body=StaticBody2D.new()
		body.position=r.get_center()
		body.collision_layer=1
		body.collision_mask=0
		var shape=CollisionShape2D.new()
		var box=RectangleShape2D.new()
		box.size=r.size
		shape.shape=box
		body.add_child(shape)
		content.add_child(body)
		plate_gates[g.id]={"shape":shape,"rect":r,"open":false}
	for c in room.get("crumbles",[]):
		var r=Rect2(c[0],c[1],c[2],c[3])
		var body=StaticBody2D.new()
		body.position=r.get_center()
		body.collision_layer=1
		body.collision_mask=0
		var shape=CollisionShape2D.new()
		var box=RectangleShape2D.new()
		box.size=r.size
		shape.shape=box
		body.add_child(shape)
		content.add_child(body)
		crumbles.append({"body":body,"shape":shape,"rect":r,"timer":-1.0,"gone":0.0})

## Placed crates are solid boxes you can stand on (and stack two high).
func build_crates() -> void:
	for body in crate_bodies:
		if is_instance_valid(body): body.queue_free()
	crate_bodies.clear()
	for point in game.world().placed.get(room_id,[]):
		var body=StaticBody2D.new()
		body.position=Vector2(point[0],point[1]-CRATE*0.5)
		body.collision_layer=1
		body.collision_mask=0
		var shape=CollisionShape2D.new()
		var box=RectangleShape2D.new()
		box.size=Vector2(CRATE,CRATE)
		shape.shape=box
		body.add_child(shape)
		content.add_child(body)
		crate_bodies.append(body)

func rects(key: String) -> Array[Rect2]:
	var out: Array[Rect2]=[]
	for r in room.get(key,[]): out.append(Rect2(r[0],r[1],r[2],r[3]))
	return out

## Thin ledges are one-way: jump up through them from below, land on top.
func collider(rect: Rect2, one_way=false) -> StaticBody2D:
	var body=StaticBody2D.new()
	body.position=rect.get_center()
	body.collision_layer=1
	body.collision_mask=0
	var shape=CollisionShape2D.new()
	var box=RectangleShape2D.new()
	box.size=rect.size
	shape.shape=box
	shape.one_way_collision=one_way
	body.add_child(shape)
	content.add_child(body)
	return body

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
		"cave": for spec in CAVE_BACK: draw_layer(canvas,spec)
		"tower": draw_tower_inside(canvas,view)
		_: for spec in BACK: draw_layer(canvas,spec)

## Inside the Old Tower: one continuous round tower wall (windows, torches,
## far stairs) moving a little slower than the climb, so it has depth.
func draw_tower_inside(canvas: CanvasItem, view: Rect2) -> void:
	var t=tex("tower_in")
	var size=Vector2(room.size[0],room.size[1])
	var w=420.0
	var h=w*t.get_height()/t.get_width()
	var factor=0.85
	var shift=view.position*(1.0-factor)
	var x=floorf((view.position.x-shift.x)/w)*w+shift.x
	while x<view.end.x:
		var y=floorf((view.position.y-shift.y)/h)*h+shift.y
		while y<view.end.y:
			canvas.draw_texture_rect(t,Rect2(x,y,w+0.5,h+0.5),false)
			y+=h
		x+=w
	# Soft shade at the bottom so the floor reads as the ground.
	canvas.draw_rect(Rect2(view.position.x,size.y-90,view.size.x,90),Color(0.1,0.07,0.05,0.18))

## Interior parallax: a far, dark wall slowly behind a nearer, brighter one
## (cave: crystal glow; tower: open arches show the sky layers behind).
func draw_walls(canvas: CanvasItem) -> void:
	var view=view_rect().grow(4)
	match room.get("scenery","meadow"):
		"cave": pass
		"tower": pass

## Fill `area` with a tiling texture that scrolls at `factor`.
func draw_tiled(canvas: CanvasItem, name: String, area: Rect2, factor: float, scale_value: float, tint=Color.WHITE) -> void:
	var texture=tex(name)
	var offset=area.position*(1.0-factor)
	canvas.draw_set_transform(offset,0,Vector2.ONE*scale_value)
	var local=Rect2((area.position-offset)/scale_value,area.size/scale_value)
	canvas.draw_texture_rect(texture,local,true,tint)
	canvas.draw_set_transform(Vector2.ZERO)

## --- Living world: moving water, drifting leaves, cave fireflies and beams.
func draw_ambient(canvas: CanvasItem) -> void:
	if reduced_motion: return
	var view=view_rect()
	var scenery: String=room.get("scenery","meadow")
	if scenery=="meadow":
		for k in range(14):
			var seed_x=fposmod(k*211.0,1000.0)
			var t=elapsed*(0.18+0.05*(k%4))+k*0.37
			var x=view.position.x+fposmod(seed_x+t*90.0-view.position.x*0.15,view.size.x+60)-30
			var y=view.position.y+fposmod(k*57.0+t*38.0,view.size.y*0.9)
			var a=t*3.0+k
			var c=Color(0.55,0.75,0.25,0.85) if k%3 else Color(0.95,0.6,0.25,0.85)
			canvas.draw_set_transform(Vector2(x+sin(t*2.0)*10.0,y),a,Vector2(1,0.5))
			canvas.draw_circle(Vector2.ZERO,2.6,c)
			canvas.draw_set_transform(Vector2.ZERO)
	elif scenery=="cave":
		for k in range(4):
			var bx=fposmod(k*380.0+120.0,float(room.size[0]))
			var pulse=0.06+0.03*sin(elapsed*0.8+k)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(bx,150),Vector2(bx+40,150),Vector2(bx+120,290),Vector2(bx+30,290)]),Color(0.7,0.85,1.0,pulse))
		for k in range(16):
			var t=elapsed*0.4+k*1.7
			var x=fposmod(k*97.0+sin(t)*30.0,float(room.size[0]))
			var y=190.0+fposmod(k*23.0,80.0)+cos(t*1.3)*10.0
			var glow=0.5+0.5*sin(elapsed*3.0+k)
			canvas.draw_circle(Vector2(x,y),5.0,Color(0.6,1.0,0.7,0.12*glow))
			canvas.draw_circle(Vector2(x,y),1.6,Color(0.85,1.0,0.6,0.9*glow))

## Friendly animals: birds cross the sky, butterflies drift, and one or two
## ground animals sit near the path (set per room in the data as "fauna").
func draw_fauna(canvas: CanvasItem) -> void:
	var scenery: String=room.get("scenery","meadow")
	var view=view_rect()
	if scenery=="meadow":
		# Birds live in the world and always fly forward across the room at
		# their own pace, so walking back never drags them backwards.
		var span=float(room.size[0])+400.0
		for k in range(int(span/700.0)+1):
			var speed=34.0+k%3*9.0
			var x=fposmod(elapsed*speed+k*700.0+k*k*37.0,span)-200.0
			if x<view.position.x-60 or x>view.end.x+60: continue
			var y=view.position.y+view.size.y*(0.16+0.06*(k%3))+sin(elapsed*1.5+k)*6
			var frame="bird_a" if reduced_motion or int(elapsed*6+k)%2==0 else "bird_b"
			piece(canvas,frame,Vector2(x,y),12)
		for k in range(3):
			var bx=float(k*700+300)
			var y=ground_y_at(bx)-22-sin(elapsed*1.7+k)*8
			var x=bx+sin(elapsed*0.6+k)*40
			piece(canvas,"butterfly_a" if reduced_motion or int(elapsed*8+k)%2==0 else "butterfly_b",Vector2(x,y),9)
	for f in room.get("fauna",[]):
		var feet=Vector2(f.pos[0],f.pos[1]+2)
		var kind: String=f.kind
		if kind=="bunny":
			var hop=fposmod(elapsed+f.pos[0],5.0)
			var up=0.0 if reduced_motion or hop>0.6 else sin(hop/0.6*PI)*8.0
			piece(canvas,"bunny_hop" if up>1 else "bunny_sit",feet-Vector2(0,up),15,Color.WHITE,f.get("flip",false))
		else: piece(canvas,kind,feet,15 if kind=="squirrel" else 11,Color.WHITE,f.get("flip",false))

## Moving shimmer and sparkles over every stretch of water.
func draw_water_motion(canvas: CanvasItem) -> void:
	if reduced_motion: return
	for w in room.get("waters",[]):
		var r=Rect2(w[0],w[1],w[2],w[3])
		for k in range(10):
			var y=r.position.y+6+fposmod(k*13.0,r.size.y*0.6)
			var len=18.0+float((k*7)%14)
			var x=r.position.x+fposmod(k*53.0+elapsed*(26.0+k*3.0),r.size.x-len)
			canvas.draw_line(Vector2(x,y),Vector2(x+len,y),Color(1,1,1,0.35+0.25*sin(elapsed*2.0+k)),1.4)
		for k in range(6):
			var sp=Vector2(r.position.x+fposmod(k*71.0+elapsed*12.0,r.size.x),r.position.y+4+fposmod(k*19.0,r.size.y*0.5))
			var tw=maxf(0,sin(elapsed*4.0+k*1.9))
			canvas.draw_circle(sp,1.5*tw+0.2,Color(1,1,1,0.9*tw))

## --- Room -------------------------------------------------------------------
func piece(canvas: CanvasItem, name: String, feet: Vector2, height: float, tint=Color.WHITE, flip=false) -> void:
	var texture=tex(name)
	var width=height*texture.get_width()/texture.get_height()
	if flip: canvas.draw_set_transform(Vector2(feet.x*2,0),0,Vector2(-1,1))
	canvas.draw_texture_rect(texture,Rect2(feet-Vector2(width*0.5,height),Vector2(width,height)),false,tint)
	if flip: canvas.draw_set_transform(Vector2.ZERO)

## Repeat a strip piece across [x0,x1], top of the walking surface at y.
func strip(canvas: CanvasItem, name: String, x0: float, x1: float, y: float, height: float, tint=Color.WHITE, shift=0.0) -> void:
	var texture=tex(name)
	var width=height*texture.get_width()/texture.get_height()
	var top=y-height*float(SURFACE.get(name,0.2))
	# World-aligned phase: neighbouring surfaces continue the same pattern.
	var x=x0
	while x<x1-0.5:
		var phase=fposmod(x+shift,width)
		if width-phase<0.05: phase=0.0
		var w=minf(width-phase,x1-x)
		if w<0.05: break
		canvas.draw_texture_rect_region(texture,Rect2(x,top,w+0.4,height),Rect2(texture.get_width()*phase/width,0,texture.get_width()*w/width,texture.get_height()),tint)
		x+=w

## A room with a crank keeps its bridge raised until the wheel is turned.
func bridge_locked() -> bool:
	return room.has("crank") and not room.crank.id in game.world().opened

## Exits plus secret doors that have been opened.
func door_locked(exit: Dictionary) -> bool:
	return exit.has("lock") and not (exit.lock+"_used") in game.world().opened

func active_exits() -> Array:
	var out: Array=room.get("exits",[]).duplicate()
	for sd in room.get("secret_doors",[]):
		if sd.id in game.world().opened:
			out.append({"door":sd.door,"kind":"secret","to":sd.to,"spawn":sd.spawn,"label":sd.label})
	return out

## From the bag: get ready to put a crate down (Use becomes Place).
func start_placing() -> void:
	if game.world_crates_free()<=0: return
	placing=true
	status.emit("Walk to a spot and tap Place to put the crate down. Open the bag to keep it instead.")

## From the bag: eat a jump carrot, the next jump is a big one.
func use_carrot() -> void:
	if super_jump or not game.world_use_carrot(): return
	Sound.play("carrot")
	super_jump=true
	status.emit("Crunch! Your next jump is a big one.")

## Crates travel with you: leaving a room puts the crates you placed back in
## the bag, unless one is holding a pressure plate (a gate stays open).
func bring_crates_along() -> void:
	var keep=[]
	var placed: Array=game.world().placed.get(room_id,[])
	for plate in room.get("plates",[]):
		var r=Rect2(plate.rect[0],plate.rect[1]-30,plate.rect[2],plate.rect[3]+34)
		for i in placed.size():
			if r.has_point(Vector2(placed[i][0],placed[i][1]-2)): keep.append(i)
	var back=game.world_collect_crates(room_id,keep)
	if back>0: status.emit("%d crate%s came along in your bag."%[back,"" if back==1 else "s"])

func plate_pressed(plate: Dictionary) -> bool:
	var r=Rect2(plate.rect[0],plate.rect[1]-30,plate.rect[2],plate.rect[3]+34)
	for point in game.world().placed.get(room_id,[]):
		if r.has_point(Vector2(point[0],point[1]-2)): return true
	return is_instance_valid(player) and player.is_on_floor() and r.has_point(player.position)

func ground_y_at(x: float) -> float:
	var best=float(room.size[1])
	for r in rects("ground"):
		if r.size.y>20 and x>=r.position.x and x<=r.end.x: best=minf(best,r.position.y)
	return best

func exposed(r: Rect2, side: float) -> bool:
	var probe=Vector2(r.position.x-2 if side<0 else r.end.x+2,r.position.y+6)
	for other in rects("ground"):
		if other!=r and other.size.y>20 and other.has_point(probe): return false
	return true

func draw_room(canvas: CanvasItem) -> void:
	var scenery: String=room.get("scenery","meadow")
	var tint=Color(0.62,0.68,0.9) if scenery=="cave" else (Color(0.85,0.86,0.9) if scenery=="tower" else Color.WHITE)
	for lm in room.get("landmarks",[]): landmark(canvas,lm)
	for w in room.get("waters",[]):
		MeadowCrossingKit.draw_river(canvas,Rect2(w[0],w[1],w[2],w[3]))
	draw_water_motion(canvas)
	draw_fauna(canvas)
	decorate(canvas,scenery)
	var bridge=room.get("bridge",[])
	var index=0
	for r in rects("ground"):
		index+=1
		if not bridge.is_empty() and r==Rect2(bridge[0],bridge[1],bridge[2],bridge[3]):
			# The bridge slides out from under the near bank across the river
			# (its planks travel with it), using only the bridge art.
			if bridge_progress>0.01:
				var length=r.size.x+12
				strip(canvas,"bridge",r.position.x-6,r.position.x-6+length*bridge_progress,r.position.y,30,Color.WHITE,length*(1.0-bridge_progress))
		elif r.size.y<=20:
			var name="crystal_ledge" if scenery=="cave" else ("stone_ledge" if scenery=="tower" and index%2==0 else ("scaffold" if scenery=="tower" else ("float_big" if r.size.x>=110 else "float_small")))
			var texture=tex(name)
			# Wide ledges repeat the piece at its own size instead of stretching it.
			var count=maxi(1,int(round(r.size.x/130.0)))
			var seg=r.size.x/count
			for k in range(count):
				var width=seg*1.12
				var height=width*texture.get_height()/texture.get_width()
				canvas.draw_texture_rect(texture,Rect2(r.position.x+k*seg-seg*0.06,r.position.y-height*float(SURFACE[name]),width,height),false)
		else:
			# Earth body (TerrainFill), then the grassy top strip, then cliff ends.
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

## Tiling fills only (earth under the ground strips, the cave ceiling rock).
func draw_fills(canvas: CanvasItem) -> void:
	var scenery: String=room.get("scenery","meadow")
	var tint=Color(0.62,0.68,0.9) if scenery=="cave" else (Color(0.85,0.86,0.9) if scenery=="tower" else Color.WHITE)
	for r in rects("ground"):
		if r.size.y<=20: continue
		var fill=Rect2(r.position.x,r.position.y+10,r.size.x,r.size.y-10)
		var body="cave_wall" if scenery=="cave" else ("tower_wall" if scenery=="tower" else "earth")
		var k=0.32 if body=="earth" else 0.26
		canvas.draw_set_transform(Vector2.ZERO,0,Vector2.ONE*k)
		canvas.draw_texture_rect(tex(body),Rect2(fill.position/k,fill.size/k),true,tint if body=="earth" else Color(0.55,0.58,0.72) if scenery=="cave" else Color(0.7,0.7,0.74))
		canvas.draw_set_transform(Vector2.ZERO)
	if scenery=="cave" and room.has("ceiling"):
		var c=room.ceiling
		canvas.draw_set_transform(Vector2.ZERO,0,Vector2.ONE*0.38)
		canvas.draw_texture_rect(tex("cave_wall"),Rect2(Vector2(c[0],c[1])/0.38,Vector2(c[2],c[3]+6)/0.38),true,Color(0.42,0.46,0.66))
		canvas.draw_set_transform(Vector2.ZERO)

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
	if scenery=="cave" and room.has("ceiling"):
		var c=room.ceiling
		var bottom=float(c[1]+c[3])
		# The rock ceiling itself is drawn by draw_fills (it tiles).
		# Rocky rim: the crystal ledge piece upside down, repeated along the edge.
		var rim=tex("crystal_ledge")
		var rh=34.0
		var rw=rh*rim.get_width()/rim.get_height()
		var x=float(c[0])-rw*0.3
		while x<float(c[0]+c[2]):
			canvas.draw_set_transform(Vector2(0,bottom*2+rh*0.35),0,Vector2(1,-1))
			canvas.draw_texture_rect(rim,Rect2(x,bottom-rh*0.65+rh*0.35-rh*0.35,rw,rh),false,Color(0.7,0.74,0.92))
			canvas.draw_set_transform(Vector2.ZERO)
			x+=rw*0.82
		for k in range(int(float(room.size[0])/240)):
			var vines=tex("cave_vines")
			var h=70.0
			var w=h*vines.get_width()/vines.get_height()
			canvas.draw_texture_rect(vines,Rect2(130+k*240-w*0.5,bottom-4,w,h),false,Color(0.82,0.88,1))
	if scenery=="tower":
		for k in range(int(float(room.size[1])/180)):
			piece(canvas,"lantern",Vector2(40 if k%2==0 else float(room.size[0])-40,120+k*180),44)

func landmark(canvas: CanvasItem, lm: Dictionary) -> void:
	if lm.kind=="windmill" and lm.h>0:
		var feet=Vector2(lm.pos[0],lm.pos[1]+4)
		# A landmark stands back in the field: slightly hazy, behind the path.
		piece(canvas,"windmill",feet,lm.h,Color(0.9,0.93,1.0))
		var body=tex("windmill")
		var w=lm.h*body.get_width()/body.get_height()
		var hub=feet+Vector2(0,-lm.h*0.70)
		var sails=tex("windmill_sails")
		var d=lm.h*0.9
		var angle=0.0 if reduced_motion else elapsed*0.6
		canvas.draw_set_transform(hub,angle,Vector2.ONE)
		canvas.draw_texture_rect(sails,Rect2(-d*0.5,-d*0.5,d,d),false,Color(0.9,0.93,1.0))
		canvas.draw_set_transform(Vector2.ZERO)

## The Old Tower seen from outside: a whole round tower whose own doorway
## is the room exit (drawn instead of a separate door piece).
const TOWER_H=250.0
func draw_facade(canvas: CanvasItem, at: Array) -> void:
	var t=tex("tower_ext")
	var w=TOWER_H*t.get_width()/t.get_height()
	var base=Vector2(at[0],at[1]+10)
	canvas.draw_texture_rect(t,Rect2(base.x-w*0.5,base.y-TOWER_H,w,TOWER_H),false)

func props(canvas: CanvasItem) -> void:
	var opened: Array=game.world().opened
	if room.has("tower_facade"): draw_facade(canvas,room.tower_facade)
	var size=Vector2(room.size[0],room.size[1])
	for exit in room.get("exits",[]):
		if exit.has("door"):
			# Doorways built into their walls (tower interior and its locked top door).
			var kind="cave" if exit.kind=="cave" else "tower_arch_open"
			if exit.has("lock"): kind="tower_arch_locked" if door_locked(exit) else "tower_arch_unlocked"
			var facade: Array=room.get("tower_facade",[])
			# The tower drawing already has its doorway; no second door on top.
			if not (facade.size()==2 and absf(float(facade[0])-float(exit.door[0]))<4):
				piece(canvas,kind,Vector2(exit.door[0],exit.door[1]+2),72 if kind=="cave" else 86)
			pass
		elif exit.has("edge"):
			# A gate themed for the place it leads to, with its picture on top
			# (cottage = home, windmill = Meadow Fields, waves = River Crossing).
			var x=40.0 if exit.edge=="left" else size.x-40.0
			var y=ground_y_at(x)
			piece(canvas,GATES.get(exit.to,"gate_meadow"),Vector2(x,y+3),104)
	if room.has("crank"):
		MeadowCrossingKit.draw_crank(canvas,Vector2(room.crank.pos[0],room.crank.pos[1]),crank_angle)
	var w_state=game.world()
	if room.has("basket") and not room.basket.id in w_state.opened:
		var bob=0.0 if reduced_motion else sin(elapsed*2.0)*1.5
		ArtStyle.draw_prop(canvas,"basket",Vector2(room.basket.pos[0],room.basket.pos[1]+bob),Vector2(28,29))
	if room.has("npc") and "picnic_done" in w_state.opened:
		ArtStyle.draw_picnic(canvas,Vector2(room.npc.pos[0]+46,room.npc.pos[1]),true)
	for sd in room.get("secret_doors",[]): draw_secret_door(canvas,sd)
	for lever in room.get("levers",[]):
		if lever.dig in w_state.dug:
			piece(canvas,"lever_on" if lever.opens in w_state.opened else "lever_off",Vector2(lever.pos[0],lever.pos[1]+3),30)
	for plate in room.get("plates",[]):
		var pr=Rect2(plate.rect[0],plate.rect[1],plate.rect[2],plate.rect[3])
		var art=tex("plate_down" if plate_pressed(plate) else "plate_up")
		var ph=pr.size.x*1.3*art.get_height()/art.get_width()
		canvas.draw_texture_rect(art,Rect2(pr.position.x-pr.size.x*0.15,pr.end.y-ph+3,pr.size.x*1.3,ph),false)
	for gid in plate_gates:
		var g=plate_gates[gid]
		piece(canvas,"wall_open" if g.open else "wall_closed",Vector2(g.rect.get_center().x,g.rect.end.y+2),g.rect.size.y)
	var lit: Array=game.world().lit
	var lanterns: Array=room.get("lanterns",[])
	for i in range(lanterns.size()):
		var on="%s:%d"%[room_id,i] in lit
		var feet=Vector2(lanterns[i][0],lanterns[i][1]+2)
		if on:
			# Soft steady glow; only the brightness flickers a little.
			var flick=0.0 if reduced_motion else 0.03*sin(elapsed*7.0+i*2.0)
			for ring in range(4):
				canvas.draw_circle(feet-Vector2(-9,40),10.0+ring*6.0,Color(1,0.82,0.4,0.07+flick))
		piece(canvas,"lantern_lit" if on else "lantern_unlit",feet,56)
	for t in room.get("thorns",[]):
		var r=Rect2(t[0],t[1],t[2],t[3])
		# Thorns repeat at their own small size along the patch, never stretched.
		var th=tex("thorns")
		var h=22.0
		var seg=h*th.get_width()/th.get_height()
		var count=maxi(1,int(round(r.size.x/seg)))
		var step=r.size.x/count
		for k in range(count):
			canvas.draw_texture_rect(th,Rect2(r.position.x+k*step+(step-seg)*0.5,r.end.y-h+3,seg,h),false)
	for c in critters:
		var spec: Dictionary=CRITTERS[c.kind]
		var flap=int(elapsed*spec.anim)%2==0 or reduced_motion
		var name: String=spec.art+("_dizzy" if c.dizzy>0 else ("_a" if flap else "_b"))
		if c.kind=="hedgehog" and c.dizzy>0: name="hedgehog_ball"
		if c.kind=="frog" and c.dizzy<=0: name="frog_b" if c.cy<c.y-2 else "frog_a"
		piece(canvas,name,Vector2(c.x,c.cy+2),spec.h,Color.WHITE,c.dir<0)
	for m in movers:
		var body: AnimatableBody2D=m.body
		var logs=tex("log_platform")
		var w=m.size.x*1.15
		var h=w*logs.get_height()/logs.get_width()
		canvas.draw_texture_rect(logs,Rect2(body.position.x-w*0.5,body.position.y-m.size.y*0.5-h*0.18,w,h),false)
	for c in crumbles:
		if c.gone>0: continue
		var r: Rect2=c.rect
		var shake=Vector2(sin(elapsed*60)*1.2,0) if c.timer>=0 and not reduced_motion else Vector2.ZERO
		var st=tex("crumble")
		var h=r.size.x*st.get_height()/st.get_width()
		canvas.draw_texture_rect(st,Rect2(r.position+shake-Vector2(0,h*0.15),Vector2(r.size.x,h)),false,Color(1,0.85,0.8) if c.timer>=0 else Color.WHITE)
	for sign in room.get("signs",[]):
		var feet=Vector2(sign.pos[0],sign.pos[1]+2)
		piece(canvas,"sign",feet,40)
		# A small painted hint symbol, centred on the board (measured in
		# sign.png: board centre at 51%/31%, ~9 px tall at this size).
		# The full hint shows when you Read the sign.
		var bulb=CareArt.icon("hint")
		var mark=7.5
		var centre=feet+Vector2(0.34,-27.8)
		canvas.draw_texture_rect(bulb,Rect2(centre-Vector2.ONE*mark*0.5,Vector2.ONE*mark),false)
	for gate in room.get("gates",[]):
		if not game.has_ability(gate.ability):
			var r=Rect2(gate.rect[0],gate.rect[1],gate.rect[2],gate.rect[3])
			piece(canvas,"thorn_gate",Vector2(r.get_center().x,r.end.y+2),r.size.y)
	# The Sky Feather on its stand; once taken the stand stays, empty and
	# softly glowing, and the feather flies up into the bag.
	if room.has("shrine"):
		var at=Vector2(room.shrine.pos[0],room.shrine.pos[1]+2)
		if not game.has_ability(room.shrine.ability):
			var bob=0.0 if reduced_motion else sin(elapsed*2.2)*2.0
			piece(canvas,"shrine",at+Vector2(0,bob*0.3),56)
		else:
			piece(canvas,"shrine_empty",at,27)
			if elapsed<feather_until:
				var k=1.0-(feather_until-elapsed)/1.8
				var from=at+Vector2(0,-30)
				# Rise and hover over the stand, then fly to the bag button.
				var view=view_rect()
				var hover=from+Vector2(0,-36+sin(elapsed*6.0)*2.0)
				var to=Vector2(view.end.x-60,view.position.y+20)
				var p=from.lerp(hover,smoothstep(0.0,0.25,k)) if k<0.45 else hover.lerp(to,smoothstep(0.45,1.0,k))
				var feather_h=40.0 if k<0.45 else lerpf(40.0,16.0,(k-0.45)/0.55)
				if not reduced_motion: canvas.draw_circle(p+Vector2(0,-feather_h*0.5),feather_h*0.7,Color(0.7,0.95,1.0,0.25*(1.0-k)))
				piece(canvas,"sky_feather",p,feather_h,Color(1,1,1,1.0-maxf(0.0,k-0.8)*5.0))
	for chest in room.get("chests",[]):
		var open=chest.id in opened
		piece(canvas,"chest_open" if open else "chest",Vector2(chest.pos[0],chest.pos[1]+2),28)
		if opened_at.has(chest.id):
			var t=elapsed-float(opened_at[chest.id])
			if t<2.2:
				var lift=minf(t,0.6)/0.6
				piece(canvas,chest.part,Vector2(chest.pos[0],chest.pos[1]-30-lift*22),26)
	for point in game.world().placed.get(room_id,[]):
		piece(canvas,"crate",Vector2(point[0],point[1]+1),CRATE+2)
	for dig in room.get("digs",[]):
		if dig.id in game.world().dug:
			if popped.has(dig.id) and elapsed-float(popped[dig.id])<1.6:
				var t=minf(elapsed-float(popped[dig.id]),0.5)/0.5
				var at=Vector2(dig.pos[0],dig.pos[1]-14-t*24)
				var shown={"crate":"crate","key":"pickup_key","snack":"pickup_apple","carrot":"pickup_carrot"}
				if shown.has(dig.item): piece(canvas,shown[dig.item],at,18)
				elif dig.item!="lever": canvas.draw_texture_rect(ArtTexture.load_texture(PetUI.COIN_PATH),Rect2(at-Vector2(7,14),Vector2(14,14)),false)
			# The little hole stays where Foxy dug.
			piece(canvas,"dug_hole",Vector2(dig.pos[0],dig.pos[1]+2),8)
			continue
		# Foxy can smell it: a small mound and sparkle appear when she is close.
		if is_instance_valid(companion) and companion.position.distance_to(Vector2(dig.pos[0],dig.pos[1]))<smell_range():
			var base=Vector2(dig.pos[0],dig.pos[1]+2)
			var glint=not reduced_motion and int(elapsed*2.0+dig.pos[0])%3==0
			piece(canvas,"mound_glint" if glint else "mound",base,(14.0*166/113) if glint else 14.0)
			if not reduced_motion:
				for k in 2:
					var tw=fposmod(elapsed*0.8+k*0.5+dig.pos[0]*0.01,1.0)
					var sp=base+Vector2(-8+k*16,-14-tw*14)
					piece(canvas,"twinkle",sp,8.0*sin(tw*PI)+0.5,Color(1,1,1,sin(tw*PI)))
	# Bouncing marker over a door, cave or arch you can go through right now.
	if near.get("kind","")=="door" or near.get("kind","") in ["lever","chest","shrine"]:
		var target: Array=near.data.get("door",near.data.get("pos",[0,0]))
		var bob=0.0 if reduced_motion else absf(sin(elapsed*4.0))*5.0
		piece(canvas,"mark_down",Vector2(target[0],target[1]-(92 if near.kind=="door" else 42)-bob),16)
	# Ghost crate where Place would put it.
	if faces.interact[0]=="Place" and is_instance_valid(player):
		var spot=crate_spot()
		if spot!=Vector2.INF:
			var a=0.35+(0.0 if reduced_motion else 0.15*sin(elapsed*5.0))
			piece(canvas,"crate",spot+Vector2(0,1),CRATE+2,Color(1,1,1,a))
	for item in room.get("pickups",[]):
		if not pickup_visible(item): continue
		var bob=0.0 if reduced_motion else sin(elapsed*2.6+item.pos[0])*1.5
		var h=14.0 if item.kind in ["apple","fish"] else 16.0
		if item.kind=="carrot" and not reduced_motion: canvas.draw_circle(Vector2(item.pos[0],item.pos[1]-10),10,Color(1,0.85,0.3,0.15+0.1*sin(elapsed*4.0)))
		piece(canvas,"pickup_"+item.kind,Vector2(item.pos[0],item.pos[1]-2+bob),h)
	# Foxy found something: a bouncing "!" bubble over Foxy.
	if not found.is_empty() and is_instance_valid(companion):
		var hop=0.0 if reduced_motion else absf(sin(elapsed*5.0))*4.0
		piece(canvas,"mark_found",companion.position+Vector2(0,-28-hop),22)
	# Guide: on screen a bouncing arrow over the goal; off screen a golden
	# arrow at the screen edge with where it leads ("To Hidden Cave").
	if game.preferences().show_goal and is_instance_valid(player):
		var target=goal_target()
		if target!=Vector2.INF and target.distance_to(player.position)>60:
			var view=view_rect()
			var bob=0.0 if reduced_motion else sin(elapsed*4.0)*3.0
			if view.grow(-20).has_point(target):
				piece(canvas,"mark_down",target+Vector2(0,-62+bob),22)
			else:
				var right=target.x>player.position.x
				var y=clampf(player.position.y-34,view.position.y+90,view.end.y-60)
				var x=view.end.x-34+bob if right else view.position.x+34-bob
				piece(canvas,"mark_arrow",Vector2(x,y+12),24,Color.WHITE,not right)
	draw_bits(canvas)
	# Double jump: a soft puff of air under the feet, fading out.
	if elapsed<boost_until:
		var k=1.0-(boost_until-elapsed)/0.35
		for i in range(5):
			var a=PI*(0.15+0.7*i/4.0)
			canvas.draw_circle(boost_at+Vector2(cos(a)*(6+k*14),sin(a)*3+k*4),3.5*(1.0-k)+1.0,Color(1,1,1,0.75*(1.0-k)))
	if not snack_icon.is_empty() and elapsed<snack_until and is_instance_valid(companion):
		var t=1.0-(snack_until-elapsed)/1.8
		var at=companion.position+Vector2(0,-30-t*10)
		canvas.draw_circle(at,11,Color(1,1,1,0.9))
		canvas.draw_texture_rect(CareArt.icon("food_"+snack_icon),Rect2(at-Vector2(8,8),Vector2(16,16)),false,Color(1,1,1,1.0-maxf(0,t-0.7)*3))
		if t<0.8 and int(elapsed*6)%2==0: canvas.draw_texture_rect(CareArt.icon("heart"),Rect2(at+Vector2(8,-14),Vector2(8,8)),false)
	var taken: Array=game.world().coins
	var coin=ArtTexture.load_texture(PetUI.COIN_PATH)
	var coins: Array=room.get("coins",[])
	for i in range(coins.size()):
		if "%s:%d"%[room_id,i] in taken: continue
		var bob=0.0 if reduced_motion else sin(elapsed*2.4+i)*1.5
		canvas.draw_texture_rect(coin,Rect2(coins[i][0]-7,coins[i][1]-7+bob,14,14),false)

func dust(at: Vector2, count: int, spread=14.0) -> void:
	if reduced_motion: return
	for i in count:
		bits.append({"p":at+Vector2(randf_range(-spread,spread),randf_range(-3,2)),"v":Vector2(randf_range(-30,30),randf_range(-34,-8)),"life":0.0,"max":randf_range(0.45,0.8),"kind":"dust","size":randf_range(3.0,6.0)})
func sparkle(at: Vector2, count: int, color=Color("ffe27a")) -> void:
	if reduced_motion: return
	for i in count:
		var a=randf()*TAU
		bits.append({"p":at,"v":Vector2(cos(a),sin(a))*randf_range(40,90),"life":0.0,"max":randf_range(0.4,0.7),"kind":"spark","size":randf_range(2.0,3.5),"color":color})
## A crumbling stone breaks into four pieces of its own art that tumble down.
func break_apart(r: Rect2) -> void:
	dust(r.get_center()+Vector2(0,r.size.y*0.5),8,r.size.x*0.4)
	if reduced_motion: return
	var st=tex("crumble")
	var h=r.size.x*st.get_height()/st.get_width()
	for i in 4:
		var src=Rect2(st.get_width()*i/4.0,0,st.get_width()/4.0,st.get_height())
		var at=Vector2(r.position.x+r.size.x*(i+0.5)/4.0,r.position.y-h*0.15+h*0.5)
		bits.append({"p":at,"v":Vector2(randf_range(-30,30),randf_range(-60,-20)),"life":0.0,"max":1.4,"kind":"chunk","size":r.size.x/4.0,"h":h,"rot":0.0,"spin":randf_range(-5,5),"src":src})
func update_bits(delta: float) -> void:
	for b in bits:
		b.life+=delta
		b.p+=b.v*delta
		match b.kind:
			"chunk":
				b.v.y+=520*delta
				b.rot+=b.spin*delta
			"dust": b.v*=0.9
			"spark": b.v*=0.88
	bits=bits.filter(func(b): return b.life<b.max)
func draw_bits(canvas: CanvasItem) -> void:
	for b in bits:
		var k=b.life/b.max
		match b.kind:
			"dust": canvas.draw_circle(b.p,b.size*(0.6+k),Color(0.93,0.88,0.76,0.55*(1.0-k)))
			"spark":
				var s=b.size*(1.0-k*0.5)
				var c: Color=b.color
				c.a=1.0-k
				canvas.draw_colored_polygon(PackedVector2Array([b.p+Vector2(0,-s*2),b.p+Vector2(s*0.5,0),b.p+Vector2(0,s*2),b.p+Vector2(-s*0.5,0)]),c)
				canvas.draw_colored_polygon(PackedVector2Array([b.p+Vector2(-s*2,0),b.p+Vector2(0,s*0.5),b.p+Vector2(s*2,0),b.p+Vector2(0,-s*0.5)]),c)
			"chunk":
				canvas.draw_set_transform(b.p,b.rot,Vector2.ONE)
				canvas.draw_texture_rect_region(tex("crumble"),Rect2(-b.size*0.5,-b.h*0.5,b.size,b.h),b.src,Color(1,1,1,1.0-maxf(0.0,k-0.7)*3.3))
				canvas.draw_set_transform(Vector2.ZERO)

## The secret hillside door: the opening, with the paw slab sliding into the
## ground as it opens (and back up as it closes).
func draw_secret_door(canvas: CanvasItem, sd: Dictionary) -> void:
	var feet=Vector2(sd.door[0],sd.door[1]+2)
	var t=tex("secret_open")
	var h=86.0
	var w=h*t.get_width()/t.get_height()
	var box=Rect2(feet-Vector2(w*0.5,h),Vector2(w,h))
	canvas.draw_texture_rect(t,box,false)
	var k: float=door_open.get(sd.id,1.0 if sd.id in game.world().opened else 0.0)
	if k>=0.999: return
	var slab=tex("secret_slab")
	var r=Rect2(box.position+Vector2(box.size.x*0.228,box.size.y*0.277),Vector2(box.size.x*0.556,box.size.y*0.679))
	r.position.y+=r.size.y*k
	# Only the part above the ground shows; the rest has sunk into the earth.
	var visible=clampf(feet.y-r.position.y,0.0,r.size.y)
	if visible<=0.5: return
	var src=Rect2(0,0,slab.get_width(),slab.get_height()*visible/r.size.y)
	var shake=Vector2(sin(elapsed*50)*0.8,0) if k>0.01 and k<0.99 and not reduced_motion else Vector2.ZERO
	canvas.draw_texture_rect_region(slab,Rect2(r.position+shake,Vector2(r.size.x,visible)),src)

func slide_secret_door(id: String, opening: bool, at: Vector2) -> void:
	door_open[id]=0.0 if opening else 1.0
	var t=create_tween()
	t.tween_method(func(v: float): door_open[id]=v,door_open[id],1.0 if opening else 0.0,0.0 if reduced_motion else 1.1).set_trans(Tween.TRANS_SINE)
	for i in 4: t.parallel().tween_callback(func(): dust(at,5,30.0)).set_delay(i*0.25)

## Foxy helps on its own: when you come near something hidden, Foxy runs to
## the spot, sits by it with a "!" and barks until you come and press Dig.
func foxy_discovers(delta: float) -> void:
	var dug: Array=game.world().dug
	if not found.is_empty() and (found.id in dug or player.position.distance_to(Vector2(found.pos[0],found.pos[1]))>smell_range()*1.8):
		found={}
		companion.point_target=Vector2.INF
	if found.is_empty():
		if not game.pet_too_weak().is_empty() or companion.ability_target!=Vector2.INF: return
		var best=INF
		for d in room.get("digs",[]):
			if d.id in dug: continue
			var at=Vector2(d.pos[0],d.pos[1])
			var gap=absf(at.x-player.position.x)
			if gap<smell_range() and absf(at.y-player.position.y)<90 and gap<best:
				best=gap
				found=d
		if found.is_empty(): return
		var side=-1.0 if player.position.x<float(found.pos[0]) else 1.0
		companion.point_target=Vector2(float(found.pos[0])+side*16.0,float(found.pos[1]))
		found_yip=0.6
		status.emit("%s found something! Go to %s and press Dig."%[game.pet().name,game.pet().name])
	# A happy bark now and then while you are not there yet.
	if player.position.distance_to(Vector2(found.pos[0],found.pos[1]))>50:
		found_yip-=delta
		if found_yip<=0:
			found_yip=2.6
			Sound.play("fox_yip",0.1)
			Sound.play("ui_open",0.1,-10.0)

## Where the next goal is: in this room its own spot, otherwise the exit that
## leads there (shortest way through the rooms). INF when there is no goal.
func goal_target() -> Vector2:
	var goal: Dictionary=game.world_goal()
	if String(goal.get("room","")).is_empty(): return Vector2.INF
	if goal.room==room_id:
		goal_label="Goal"
		var at: Array=goal.get("at",[])
		return Vector2(at[0],at[1]) if at.size()==2 else Vector2.INF
	var rooms: Dictionary=GameState.world_data().rooms
	var opened: Array=game.world().opened
	var links=func(id: String) -> Array:
		var out=[]
		for e in rooms[id].exits: out.append(e.to)
		for sd in rooms[id].get("secret_doors",[]):
			if sd.id in opened: out.append(sd.to)
		return out
	# Breadth-first search for the first step toward the goal room.
	var first: Dictionary={}
	var queue=[]
	for to in links.call(room_id):
		if rooms.has(to) and not first.has(to):
			first[to]=to
			queue.append(to)
	while not queue.is_empty() and not first.has(goal.room):
		var here: String=queue.pop_front()
		for to in links.call(here):
			if rooms.has(to) and not first.has(to) and to!=room_id:
				first[to]=first[here]
				queue.append(to)
	if not first.has(goal.room): return Vector2.INF
	var step: String=first[goal.room]
	goal_label="To "+String(rooms[step].title)
	for e in active_exits():
		if e.to!=step: continue
		if e.has("door"): return Vector2(e.door[0],e.door[1])
		var x=40.0 if e.edge=="left" else float(room.size[0])-40.0
		return Vector2(x,ground_y_at(x))
	return Vector2.INF

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
	# A safe point only where there is solid ground on both sides of the feet,
	# so coming back never lands on an edge that slides straight back in.
	if player.is_on_floor() and not on_moving_or_crumbling() and solid_at(player.position.x-18,player.position.y) and solid_at(player.position.x+18,player.position.y): safe_point=player.position
	if player.position.y>size.y+40 or in_water():
		recover_from_fall()
		return
	update_challenge(delta)
	keep_foxy_close(delta)
	collect_pickups()
	game.world_tick(delta)
	var weak=game.pet_too_weak()
	player.air_jumps=1 if game.has_ability("foxy_boost") and weak.is_empty() else 0
	collect_coins()
	if region_complete() and not "meadows_complete" in game.world().opened and game.world_flag("meadows_complete"):
		companion.react(Companion.State.CELEBRATE,2.0)
		Sound.play("fanfare",0.0)
		ability_learned.emit("Green Meadows complete!","You found all four robot parts and helped Moss with the picnic. Mystic Forest opens in a future adventure. Well done, explorer!")
	foxy_discovers(delta)
	update_bits(delta)
	find_near()
	if super_jump and Input.is_action_just_pressed("jump") and player.is_on_floor():
		super_jump=false
		player.velocity.y=-390.0
		Sound.play("super_jump",0.0)
	if Input.is_action_just_pressed("interact"): use()
	if Input.is_action_just_pressed("pet_ability"): sniff()


## Foxy never gets left behind: if far away or well below while the child
## stands somewhere, Foxy hops to the child's side.
func keep_foxy_close(delta: float) -> void:
	var gap=companion.position.distance_to(player.position)
	var below=companion.position.y>player.position.y+50
	if player.is_on_floor() and (gap>170 or (below and gap>60)): lag_time+=delta
	else: lag_time=0.0
	if lag_time>1.1:
		lag_time=0.0
		companion.position=player.position-Vector2(22.0*player.art.facing,4)
		companion.velocity=Vector2(0,-120)
		companion.reset_physics_interpolation()
		companion.safe_trail.clear()
		companion.react(Companion.State.CELEBRATE,0.6)

func pickup_visible(item: Dictionary) -> bool:
	if item.get("regrow",false): return elapsed>=float(regrow_at.get(item.id,0.0))
	return not item.id in game.world().opened

func collect_pickups() -> void:
	var data=GameState.world_data()
	for item in room.get("pickups",[]):
		if not pickup_visible(item): continue
		if (player.position-Vector2(0,10)).distance_to(Vector2(item.pos[0],item.pos[1]-10))>20: continue
		var info: Dictionary=data.items[item.kind]
		match item.kind:
			"apple","fish":
				# Into the bag as a snack: give it to Foxy whenever you like.
				if game.world_pick_food(item.id,"apple" if item.kind=="apple" else "fish_treat"):
					companion.react(Companion.State.CELEBRATE,0.8)
					Sound.play("pickup")
					status.emit("%s in your bag! Open the bag to give it to %s."%[info.name,game.pet().name])
			"carrot":
				if game.world_add_carrot():
					regrow_at[item.id]=elapsed+20.0
					Sound.play("pickup")
					status.emit("Jump carrot in your bag (%d). Open the bag and tap it for one big jump."%game.world().carrots)
				elif not super_jump:
					regrow_at[item.id]=elapsed+20.0
					super_jump=true
					status.emit("Your bag is full of carrots, so you ate this one: your next jump is a big one!")
			"key":
				game.world_flag(item.id)
				Sound.play("key",0.0)
				ability_learned.emit("Golden key","You found a golden key! It must open a locked door somewhere... maybe at the top of the Old Tower.")
			"note":
				game.world_flag(item.id)
				Sound.play("pickup")
				ability_learned.emit("Clue",item.get("clue","A clue!"))

func in_water() -> bool:
	for w in room.get("waters",[]):
		if Rect2(w[0],w[1]+10,w[2],w[3]).has_point(player.position): return true
	return false

func on_moving_or_crumbling() -> bool:
	var feet=player.position+Vector2(0,2)
	for m in movers:
		if Rect2(m.body.position-m.size*0.5-Vector2(4,6),m.size+Vector2(8,10)).has_point(feet): return true
	for c in crumbles:
		if c.rect.grow(6).has_point(feet): return true
	return false

## Lose one heart. Knock back unless it was a fall (already moved to safety).
func hurt(message: String, knock=true, from_x=0.0) -> void:
	if elapsed<hurt_until: return
	hurt_until=elapsed+1.2
	Sound.play("hurt")
	Sound.play("child_ouch",0.08)
	# Gentle mode (Settings): bumps still push you back, but no heart is lost.
	if game.preferences().gentle:
		if knock:
			var away=-1.0 if from_x>player.position.x else 1.0
			player.velocity=Vector2(away*170,-210)
		status.emit(message)
		return
	hearts-=1
	hearts_changed.emit(hearts)
	if knock:
		var dir=-1.0 if from_x>player.position.x else 1.0
		player.velocity=Vector2(dir*170,-210)
	if hearts<=0:
		respawn()
		return
	status.emit(message)

## Out of hearts: never jump to another room. Return to the lit lantern in
## this room, or to where you came in, with a short fade so it is clear.
## Ground (floor or ledge) right under this point?
func solid_at(x: float, y: float) -> bool:
	var bridge: Array=room.get("bridge",[])
	for r in rects("ground"):
		if not bridge.is_empty() and bridge_locked() and r==Rect2(bridge[0],bridge[1],bridge[2],bridge[3]): continue
		if x>=r.position.x and x<=r.end.x and absf(r.position.y-y)<3.0: return true
	for point in game.world().placed.get(room_id,[]):
		if absf(point[0]-x)<CRATE*0.5 and absf(point[1]-CRATE-y)<3.0: return true
	return false

## Fell in the water or off the bottom: one smooth splash, a short fade, and
## you stand back on safe ground (no repeated snapping back and forth).
func recover_from_fall() -> void:
	var wet=in_water()
	transitioning=true
	player.enabled=false
	player.velocity=Vector2.ZERO
	TouchControls.release_actions()
	if wet: Sound.play("splash")
	var back=func():
		player.reset_to(safe_point)
		companion.position=safe_point-Vector2(24,0)
		companion.reset_physics_interpolation()
		camera.snap_to_target()
	var done=func():
		player.enabled=true
		transitioning=false
		hurt_until=0.0
		hurt("Splash! Back on solid ground." if wet else "Oops! Back on solid ground.",false)
	if reduced_motion:
		back.call()
		done.call()
		return
	var tween=create_tween()
	tween.tween_property(fade,"color:a",0.85,0.22)
	tween.tween_callback(back)
	tween.tween_interval(0.15)
	tween.tween_property(fade,"color:a",0.0,0.3)
	tween.tween_callback(done)

func respawn() -> void:
	hearts=MAX_HEARTS
	hearts_changed.emit(hearts)
	var point=entry_point
	var lanterns: Array=room.get("lanterns",[])
	var lit: Array=game.world().lit
	var best=INF
	for i in range(lanterns.size()):
		var at=Vector2(lanterns[i][0],lanterns[i][1])
		if "%s:%d"%[room_id,i] in lit and absf(at.x-player.position.x)<best:
			best=absf(at.x-player.position.x)
			point=at
	var where="the lantern" if best<INF else "where you came in"
	Sound.play("heart",0.0)
	status.emit("Foxy helps you up! Back at %s, hearts full. You kept everything you found."%where)
	var move=func():
		player.reset_to(point)
		companion.position=point-Vector2(24,0)
		companion.reset_physics_interpolation()
		camera.snap_to_target()
	if reduced_motion:
		move.call()
		return
	transitioning=true
	var tween=create_tween()
	tween.tween_property(fade,"color:a",0.85,0.25)
	tween.tween_callback(move)
	tween.tween_interval(0.25)
	tween.tween_property(fade,"color:a",0.0,0.3)
	tween.tween_callback(func(): transitioning=false)

func update_challenge(delta: float) -> void:
	var body_point=player.position-Vector2(0,14)
	if elapsed>=hurt_until and not reduced_motion: player.art.modulate.a=1.0
	elif elapsed<hurt_until: player.art.modulate.a=0.45+0.45*float(int(elapsed*10)%2) if not reduced_motion else 0.7
	for t in room.get("thorns",[]):
		if Rect2(t[0],t[1]-6,t[2],t[3]+8).has_point(player.position): hurt("Ouch, thorns! Jump over them.",true,t[0]+t[2]*0.5)
	for c in critters:
		var spec: Dictionary=CRITTERS[c.kind]
		if c.dizzy>0:
			c.dizzy-=delta
			# Dizzy flyers drift down a little, then float back up.
			if spec.fly: c.cy=move_toward(c.cy,c.y+10,delta*20)
			continue
		var hop=0.0
		if c.kind=="frog":
			# Frogs hop: move only while in the air.
			var k=fposmod(elapsed+c.seed,1.6)
			if k<0.5:
				hop=sin(k/0.5*PI)*18.0
				c.x+=c.dir*spec.speed*3.2*delta
		else: c.x+=c.dir*spec.speed*delta
		if c.x>c.x1: c.dir=-1.0
		if c.x<c.x0: c.dir=1.0
		c.cy=c.y-hop+(sin(elapsed*2.2+c.seed)*14.0 if spec.fly else 0.0)
		# Contact box around the critter; landing on top is a bounce.
		var top=c.cy-spec.h
		if absf(player.position.x-c.x)<spec.h*0.7 and player.position.y>top-4 and player.position.y<c.cy+(38.0 if spec.fly else 2.0):
			if player.velocity.y>40 and player.position.y<top+spec.h*0.5:
				c.dizzy=3.0
				player.velocity.y=-240
				Sound.play("boing")
				status.emit(spec.stomp)
			else: hurt(spec.bump,true,c.x)
	for m in movers:
		var phase=0.5-0.5*cos(elapsed*TAU/m.period)
		m.body.position=m.base+m.to*phase
	for c in crumbles:
		if c.gone>0:
			c.gone-=delta
			if c.gone<=0: c.shape.set_deferred("disabled",false)
			continue
		var standing=player.is_on_floor() and c.rect.grow(4).has_point(player.position+Vector2(0,2))
		if standing and c.timer<0: c.timer=1.1
		if c.timer>=0:
			c.timer-=delta
			if c.timer<0:
				c.gone=2.6
				c.shape.set_deferred("disabled",true)
				break_apart(c.rect)
				Sound.play("crate_place",0.1)
	for plate in room.get("plates",[]):
		if plate_gates.has(plate.opens):
			var g=plate_gates[plate.opens]
			var open=plate_pressed(plate)
			if open!=g.open:
				g.open=open
				Sound.play("rumble",0.0,-6.0)
				g.shape.set_deferred("disabled",open)
				if open: status.emit("The stone gate slides open!")
	var lanterns: Array=room.get("lanterns",[])
	for i in range(lanterns.size()):
		var at=Vector2(lanterns[i][0],lanterns[i][1])
		if player.position.distance_to(at)<30 and not "%s:%d"%[room_id,i] in game.world().lit:
			game.world_light(room_id,i,at)
			Sound.play("lantern",0.0)
			hearts=MAX_HEARTS
			hearts_changed.emit(hearts)
			game.world_rest(20.0)
			status.emit("Lantern lit! A little rest for %s, hearts refilled, and you come back here if you get hurt."%game.pet().name)

func collect_coins() -> void:
	var coins: Array=room.get("coins",[])
	var body=player.position-Vector2(0,15)
	for i in range(coins.size()):
		if body.distance_to(Vector2(coins[i][0],coins[i][1]))<16 and game.world_collect_coin(room_id,i):
			Sound.play("coin")
			sparkle(Vector2(coins[i][0],coins[i][1]),6)

func find_near() -> void:
	near={}
	var feet=player.position
	var w=game.world()
	for chest in room.get("chests",[]):
		if not chest.id in w.opened and feet.distance_to(Vector2(chest.pos[0],chest.pos[1]))<34: near={"kind":"chest","data":chest}
	for exit in active_exits():
		if exit.has("door") and feet.distance_to(Vector2(exit.door[0],exit.door[1]))<36: near={"kind":"door","data":exit}
	if room.has("npc") and feet.distance_to(Vector2(room.npc.pos[0],room.npc.pos[1]))<44: near={"kind":"npc","data":room.npc}
	if room.has("basket") and not room.basket.id in w.opened and feet.distance_to(Vector2(room.basket.pos[0],room.basket.pos[1]))<34: near={"kind":"basket","data":room.basket}
	if room.has("crank") and feet.distance_to(Vector2(room.crank.pos[0],room.crank.pos[1]))<36: near={"kind":"crank","data":room.crank}
	for lever in room.get("levers",[]):
		if lever.dig in w.dug and feet.distance_to(Vector2(lever.pos[0],lever.pos[1]))<34: near={"kind":"lever","data":lever}
	if room.has("shrine") and not game.has_ability(room.shrine.ability) and feet.distance_to(Vector2(room.shrine.pos[0],room.shrine.pos[1]))<42: near={"kind":"shrine","data":room.shrine}
	if near.is_empty():
		var placed: Array=w.placed.get(room_id,[])
		for i in range(placed.size()):
			if absf(feet.x-placed[i][0])<30 and absf(feet.y-placed[i][1])<30: near={"kind":"crate","index":i}
	if near.is_empty():
		for sign in room.get("signs",[]):
			if feet.distance_to(Vector2(sign.pos[0],sign.pos[1]))<44: near={"kind":"sign","data":sign}
	# The context button says exactly what Use will do here.
	var face=["Use","act_use"]
	match near.get("kind",""):
		"chest": face=["Open","act_open"]
		"door": face=["Open","act_open"] if door_locked(near.data) and near.data.lock in w.opened else (["Locked","act_enter"] if door_locked(near.data) else ["Enter","act_enter"])
		"shrine": face=["Touch","act_use"]
		"lever": face=["Pull","act_use"]
		"crank": face=["Lower","act_use"] if bridge_locked() else ["Raise","act_use"]
		"npc": face=["Talk","act_read"]
		"basket": face=["Take","act_pick"]
		"crate": face=["Pick up","act_pick"]
		"sign": face=["Read","act_read"]
		_:
			if placing and game.world_crates_free()>0 and player.is_on_floor(): face=["Place","act_place"]
	faces.interact=face
	faces.pet_ability=["Dig","act_dig"] if dig_spot()!={} else ["Find","act_find"]
	var line=""
	match near.get("kind",""):
		"chest": line="Open the treasure chest!"
		"door":
			if door_locked(near.data): line="Unlock the door with the golden key!" if near.data.lock in w.opened else "Locked! A golden key must be hidden somewhere..."
			else: line="Enter: "+near.data.label
		"shrine": line="The Sky Feather! Touch it to take it: Foxy learns Double Jump."
		"lever": line="Pull the lever to close the secret wall again." if near.data.opens in w.opened else "An old lever! Pull it."
		"crank": line="Turn the wheel to lower the bridge!" if bridge_locked() else "Turn the wheel to raise the bridge again."
		"npc": line="Moss the bunny. Talk to Moss!"
		"basket": line="Moss's picnic basket! Take it."
		"crate": line="Pick up the crate to put it back in your bag."
		"sign": line=sign_text(near.data)
	if line.is_empty():
		if dig_spot()!={}: line="Foxy smells something here! Press Dig."
		for gate in room.get("gates",[]):
			if not game.has_ability(gate.ability) and absf(feet.x-gate.rect[0])<90: line=gate.text
		for exit in room.get("exits",[]):
			if exit.has("edge") and ((exit.edge=="left" and feet.x<140) or (exit.edge=="right" and feet.x>float(room.size[0])-140)):
				line="Path home" if exit.to=="home" else "Path to "+exit.label
		if room.has("boost_hint") and not game.has_ability("foxy_boost") and feet.x>room.boost_hint[0] and feet.x<room.boost_hint[1]:
			line="Too high to jump. Something in the Hidden Cave can help!"
	if line.is_empty() and not found.is_empty(): line="%s found something! Go to the ! and press Dig."%game.pet().name
	if line.is_empty(): line=objective()
	prompt=line

## A51: an older Foxy with a strong bond smells from farther and digs faster.
const SMELL={"baby":120.0,"child":150.0,"teen":190.0,"adult":230.0}
const DIG_TIME={"baby":1.1,"child":0.9,"teen":0.7,"adult":0.6}
func smell_range() -> float:
	return SMELL.get(game.pet().growth_stage,150.0)+minf(60.0,float(game.pet().bond_xp)*0.3)

## The undug spot Foxy is close enough to dig (within reach of the child).
func dig_spot() -> Dictionary:
	for dig in room.get("digs",[]):
		if not dig.id in game.world().dug and player.position.distance_to(Vector2(dig.pos[0],dig.pos[1]))<46: return dig
	return {}

func region_complete() -> bool:
	var w=game.world()
	if not "picnic_done" in w.opened: return false
	for r in GameState.world_data().rooms.values():
		for chest in r.get("chests",[]):
			if chest.part.begins_with("robot_") and not chest.id in w.opened: return false
	return true

## Signs can change once you have what they hint at (e.g. the Sky Feather).
func sign_text(sign: Dictionary) -> String:
	var after: Dictionary=sign.get("after",{})
	if not after.is_empty() and game.has_ability(after.ability): return after.text
	return sign.text

func objective() -> String:
	if room.get("challenge",false): return "Challenge room: reach the treasure at the end!"
	if not "picnic_asked" in game.world().opened and room_id=="meadow_fields": return "Moss the bunny looks worried. Go and talk to Moss."
	return String(game.world_goal().text)+"."

func use() -> void:
	match near.get("kind",""):
		"chest":
			var chest=near.data
			if game.world_open_chest(chest.id,chest.part):
				opened_at[chest.id]=elapsed
				Sound.play("chest",0.0)
				sparkle(Vector2(chest.pos[0],chest.pos[1]-20),16)
				companion.react(Companion.State.CELEBRATE)
				status.emit("You found a toy part: %s! (+10 coins)"%GameState.world_data().parts[chest.part])
		"door":
			if door_locked(near.data):
				if near.data.lock in game.world().opened and game.world_flag(near.data.lock+"_used"):
					companion.react(Companion.State.CELEBRATE)
					Sound.play("key",0.0)
					status.emit("Click! The golden key opens the door.")
				else:
					Sound.play("ui_error")
					status.emit("Locked! Find the golden key first.")
			else:
				Sound.play("door")
				go(near.data.to,near.data.spawn)
		"npc": talk_to_moss()
		"basket":
			if game.world_flag("picnic_basket"):
				Sound.play("pickup",0.0)
				companion.react(Companion.State.CELEBRATE)
				status.emit(GameState.world_data().quest.steps.carry)
		"crank":
			if not bridge_locked():
				if game.world_unflag(near.data.id):
					if is_instance_valid(bridge_body): bridge_body.queue_free()
					Sound.play("crank",0.0)
					Sound.play("bridge",0.0)
					var up=create_tween()
					up.tween_property(self,"bridge_progress",0.0,0.0 if reduced_motion else 1.2)
					up.parallel().tween_property(self,"crank_angle",crank_angle-TAU*2.0,0.0 if reduced_motion else 1.2)
					status.emit("Creak... the bridge goes back up.")
			elif game.world_flag(near.data.id):
				var r=Rect2(room.bridge[0],room.bridge[1],room.bridge[2],room.bridge[3])
				bridge_body=collider(r,false)
				Sound.play("crank",0.0)
				Sound.play("bridge",0.0)
				var t=create_tween()
				t.tween_property(self,"bridge_progress",1.0,0.0 if reduced_motion else 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				t.parallel().tween_property(self,"crank_angle",crank_angle+TAU*2.0,0.0 if reduced_motion else 1.4)
				companion.react(Companion.State.CELEBRATE)
				status.emit("Creak, creak... the bridge comes down!")
		"lever":
			# Levers work both ways: pull again to close the wall.
			if near.data.opens in game.world().opened:
				if game.world_unflag(near.data.opens):
					for sd in room.get("secret_doors",[]):
						if sd.id==near.data.opens: slide_secret_door(sd.id,false,Vector2(sd.door[0],sd.door[1]))
					Sound.play("lever")
					Sound.play("rumble",0.0)
					status.emit("Rumble... the secret wall slides shut. Pull again to open it.")
			elif game.world_flag(near.data.opens):
				for sd in room.get("secret_doors",[]):
					if sd.id==near.data.opens: slide_secret_door(sd.id,true,Vector2(sd.door[0],sd.door[1]))
				Sound.play("lever")
				Sound.play("rumble",0.0)
				companion.react(Companion.State.CELEBRATE)
				status.emit("Rumble... a secret wall slid open by the windmill!")
		"crate":
			if game.world_pick_crate(room_id,near.index):
				Sound.play("crate_pick")
				build_crates()
				status.emit("Crate back in your bag (%d ready). Place it in any room."%game.world_crates_free())
		"sign":
			Sound.play("ui_open")
			status.emit(sign_text(near.data))
		"":
			if placing and game.world_crates_free()>0: place_crate()
		"shrine":
			var ability: String=near.data.ability
			if not game.has_ability(ability) and game.world_learn(ability):
				player.air_jumps=1
				feather_until=elapsed+1.8
				companion.react(Companion.State.CELEBRATE)
				Sound.play("ability",0.0)
				status.emit("The Sky Feather is in your bag!")
				var info=GameState.world_data().abilities[ability]
				# Let the feather fly to the child first, then explain the ability.
				get_tree().create_timer(0.0 if reduced_motion else 1.9).timeout.connect(func(): ability_learned.emit(info.title,info.text))

## Foxy points the way to the nearest unopened chest in this room.
func sniff() -> void:
	var weak=game.pet_too_weak()
	if not weak.is_empty():
		companion.react(Companion.State.WAIT)
		status.emit("%s is too %s to help. Give a snack from your bag, or rest at home."%[game.pet().name,"hungry" if weak=="hungry" else "sleepy"])
		return
	var spot=dig_spot()
	if spot!={}:
		dig(spot)
		return
	var opened: Array=game.world().opened
	var best=Vector2.INF
	for chest in room.get("chests",[]):
		var at=Vector2(chest.pos[0],chest.pos[1])
		if not chest.id in opened and (best==Vector2.INF or at.distance_to(player.position)<best.distance_to(player.position)): best=at
	companion.react(Companion.State.INVESTIGATE)
	Sound.play("fox_sniff")
	if best==Vector2.INF:
		status.emit("Foxy sniffs around... nothing hidden here.")
		return
	var way="to the right" if best.x>player.position.x+20 else ("to the left" if best.x<player.position.x-20 else "close by")
	if best.y<player.position.y-40: way+=", up high"
	status.emit("Foxy smells treasure "+way+"!")

func talk_to_moss() -> void:
	var w=game.world()
	var steps: Dictionary=GameState.world_data().quest.steps
	if is_instance_valid(moss): moss.react("wave",1.6)
	if "picnic_done" in w.opened:
		status.emit("Moss: Thank you again! Come back for another picnic any time.")
	elif "picnic_basket" in w.opened:
		if game.world_finish_picnic():
			if is_instance_valid(moss): moss.react("happy",2.5)
			companion.react(Companion.State.CELEBRATE)
			ability_learned.emit("Picnic time!",steps.done)
	else:
		game.world_flag("picnic_asked")
		ability_learned.emit("The Lost Picnic",steps.ask)

## Snack from the bag: Foxy eats it right here, with a little food bubble.
var snack_icon=""
var snack_until=0.0
var boost_at=Vector2.ZERO
var boost_until=0.0
var feather_until=0.0
## Foxy's own discovery: the dig spot it is pointing at (empty: none).
var found: Dictionary={}
var found_yip=0.0
var goal_label=""
## Little effects: dust puffs, sparkles, falling stone chunks.
## Each: {p,v,life,max,kind,size,rot,spin,src}
var bits: Array[Dictionary]=[]
## Secret doors: 0 closed .. 1 open (slides the slab into the ground).
var door_open: Dictionary={}
func give_snack(id: String) -> void:
	var taste=game.food_taste(id)
	if not game.feed_food(id): return
	Sound.play("fox_eat")
	snack_icon=id
	snack_until=elapsed+1.8
	companion.react(Companion.State.CELEBRATE,1.4)
	var name: String=game.pet().name
	status.emit("%s loved it! More energy for exploring."%name if taste!="dislike" else "%s ate it... not a favourite, but it helps."%name)

func dig(spot: Dictionary) -> void:
	var at=Vector2(spot.pos[0],spot.pos[1])
	companion.ability_target=at+Vector2(-14 if companion.position.x<at.x else 14,0)
	companion.react(Companion.State.ABILITY,1.2)
	Sound.play("fox_dig")
	await get_tree().create_timer(DIG_TIME.get(game.pet().growth_stage,0.9)).timeout
	if not is_instance_valid(companion): return
	companion.ability_target=Vector2.INF
	if game.world_dig(spot.id,spot.item):
		popped[spot.id]=elapsed
		dust(at,10,12.0)
		sparkle(at+Vector2(0,-10),10)
		Sound.play("pickup" if spot.item=="crate" else "coins_many")
		if spot.item=="crate" and not "crate_help" in game.world().opened:
			game.world_flag("crate_help")
			ability_learned.emit("Crate","The crate is in your bag. When you need to reach higher, open the bag and tap Place a crate, then tap Place where you want it. Stand next to it and tap Pick up to put it back.")
		if spot.item=="key":
			Sound.play("key",0.0)
			ability_learned.emit("Golden key","%s dug up a golden key! It opens the locked door at the top of the Old Tower."%game.pet().name)
		var said={"crate":"Foxy dug up a crate! It's in your bag.","lever":"Foxy dug up an old lever! Try pulling it.","key":"The golden key is yours!","snack":"Foxy dug up an apple! It's in your bag.","carrot":"Foxy dug up a jump carrot! It's in your bag."}
		status.emit(said.get(spot.item,"Foxy dug up 5 coins!"))

## Put a crate on the ground in front of the child (or on another crate).
func crate_spot() -> Vector2:
	var x=player.position.x+player.art.facing*26
	var top=INF
	for r in rects("ground"):
		if x>=r.position.x+4 and x<=r.end.x-4 and r.position.y>=player.position.y-2 and r.position.y<top: top=r.position.y
	for point in game.world().placed.get(room_id,[]):
		if absf(point[0]-x)<CRATE and absf(point[1]-player.position.y)<CRATE+4 and point[1]-CRATE<top: top=point[1]-CRATE
	if top==INF or top>player.position.y+40: return Vector2.INF
	return Vector2(x,top)

func place_crate() -> void:
	var x=player.position.x+player.art.facing*26
	var top=INF
	for r in rects("ground"):
		if x>=r.position.x+4 and x<=r.end.x-4 and r.position.y>=player.position.y-2 and r.position.y<top: top=r.position.y
	for point in game.world().placed.get(room_id,[]):
		if absf(point[0]-x)<CRATE and point[1]-CRATE>=player.position.y-2-CRATE and point[1]-CRATE<top and absf(point[1]-player.position.y)<CRATE+4: top=point[1]-CRATE
	if top==INF or top>player.position.y+40:
		status.emit("There's no ground there for a crate.")
		return
	for point in game.world().placed.get(room_id,[]):
		if absf(point[0]-x)<CRATE*0.8 and absf(point[1]-top)<2:
			status.emit("Something is already there.")
			return
	if game.world_place_crate(room_id,Vector2(x,top)):
		placing=false
		Sound.play("crate_place")
		build_crates()
		status.emit("Crate placed. Jump on it! Stand next to it and tap Pick up to put it back in your bag.")

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
	tween.tween_property(fade,"color:a",1.0,0.3)
	tween.tween_callback(func(): enter(to,spawn))
	tween.tween_interval(0.35)
	tween.tween_property(fade,"color:a",0.0,0.35)
	tween.tween_callback(func(): transitioning=false)
