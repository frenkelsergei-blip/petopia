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
var movers: Array[Dictionary]=[]
var crumbles: Array[Dictionary]=[]
var arrival_title=""
var entry_point=Vector2.ZERO
var bridge_progress=1.0
var crank_angle=0.0
var plate_gates: Dictionary={}
var leaves: Array[Vector3]=[]
var arrival_until=0.0
signal hearts_changed(value: int)

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
		# The HUD covers the top of the screen: keep the child in the lower middle.
		var want_y=clampf(target.position.y-56,half.y,course_height-half.y)
		var y=position.y
		if absf(want_y-y)>14: y=move_toward(y,want_y,maxf(3.0,(absf(want_y-y)-14)*0.35))
		position=Vector2(clampf(target.position.x,half.x,course_width-half.x),clampf(y,half.y,course_height-half.y))
	func snap_to_target() -> void:
		if not is_instance_valid(target): return
		var half=get_viewport_rect().size*0.5/zoom
		position=Vector2(clampf(target.position.x,half.x,course_width-half.x),clampf(target.position.y-56,half.y,course_height-half.y))
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
	var ground=Node2D.new()
	ground.name="Terrain"
	ground.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
	ground.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	ground.draw.connect(func(): draw_room(ground))
	content.add_child(ground)
	var bridge_spec=room.get("bridge",[])
	bridge_progress=0.0 if bridge_locked() else 1.0
	for r in rects("ground"):
		var is_bridge=not bridge_spec.is_empty() and r==Rect2(bridge_spec[0],bridge_spec[1],bridge_spec[2],bridge_spec[3])
		if is_bridge and bridge_locked(): continue
		collider(r,r.size.y<=20 and not is_bridge)
	if room.has("ceiling"):
		var c=room.ceiling
		collider(Rect2(c[0],c[1],c[2],c[3]))
	for gate in room.get("gates",[]):
		if not game.has_ability(gate.ability): collider(Rect2(gate.rect[0],gate.rect[1],gate.rect[2],gate.rect[3]))
	build_challenge()
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
	build_crates()
	var front=Node2D.new()
	front.name="Foreground"
	front.z_index=4
	front.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	front.draw.connect(func(): draw_layer(front,FRONT); draw_ambient(front))
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
		critters.append({"x":float(c.x0),"x0":float(c.x0),"x1":float(c.x1),"y":float(c.y),"dir":1.0,"dizzy":0.0})
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
func collider(rect: Rect2, one_way=false) -> void:
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
		"cave": canvas.draw_rect(view.grow(4),Color("10162a"))
		"tower": for spec in BACK.slice(0,3): draw_layer(canvas,spec)
		_: for spec in BACK: draw_layer(canvas,spec)

## Interior parallax: a far, dark wall slowly behind a nearer, brighter one
## (cave: crystal glow; tower: open arches show the sky layers behind).
func draw_walls(canvas: CanvasItem) -> void:
	var view=view_rect().grow(4)
	match room.get("scenery","meadow"):
		"cave":
			draw_tiled(canvas,"cave_wall",view,0.2,0.22,Color(0.32,0.36,0.55))
			var near_wall=Rect2(view.position.x,view.position.y,view.size.x,view.size.y)
			draw_tiled(canvas,"cave_wall",near_wall,0.55,0.38,Color(0.7,0.75,0.95,0.92))
			pass
		"tower":
			var arch=150.0
			var x=floorf((view.position.x*0.6)/arch)*arch
			while x-view.position.x*0.6<view.size.x+arch:
				var wx=x+view.position.x*0.4
				draw_tiled(canvas,"tower_wall",Rect2(wx,view.position.y,arch*0.62,view.size.y),0.6,0.3,Color(0.9,0.9,0.95))
				x+=arch

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
func strip(canvas: CanvasItem, name: String, x0: float, x1: float, y: float, height: float, tint=Color.WHITE) -> void:
	var texture=tex(name)
	var width=height*texture.get_width()/texture.get_height()
	var top=y-height*float(SURFACE.get(name,0.2))
	# World-aligned phase: neighbouring surfaces continue the same pattern.
	var x=x0
	while x<x1-0.5:
		var phase=fposmod(x,width)
		if width-phase<0.05: phase=0.0
		var w=minf(width-phase,x1-x)
		if w<0.05: break
		canvas.draw_texture_rect_region(texture,Rect2(x,top,w+0.4,height),Rect2(texture.get_width()*phase/width,0,texture.get_width()*w/width,texture.get_height()),tint)
		x+=w

## A room with a crank keeps its bridge raised until the wheel is turned.
func bridge_locked() -> bool:
	return room.has("crank") and not room.crank.id in game.world().opened

## Exits plus secret doors that have been opened.
func active_exits() -> Array:
	var out: Array=room.get("exits",[]).duplicate()
	for sd in room.get("secret_doors",[]):
		if sd.id in game.world().opened:
			out.append({"door":sd.door,"kind":"secret","to":sd.to,"spawn":sd.spawn,"label":sd.label})
	return out

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
	decorate(canvas,scenery)
	var bridge=room.get("bridge",[])
	var index=0
	for r in rects("ground"):
		index+=1
		if not bridge.is_empty() and r==Rect2(bridge[0],bridge[1],bridge[2],bridge[3]):
			if bridge_progress>0.01: strip(canvas,"bridge",r.position.x-6,r.position.x-6+(r.size.x+12)*bridge_progress,r.position.y,30)
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
			# Earth body, then the grassy top strip, then rounded cliff ends.
			var fill=Rect2(r.position.x,r.position.y+10,r.size.x,r.size.y-10)
			var body="cave_wall" if scenery=="cave" else ("tower_wall" if scenery=="tower" else "earth")
			var k=0.32 if body=="earth" else 0.26
			canvas.draw_set_transform(Vector2.ZERO,0,Vector2.ONE*k)
			canvas.draw_texture_rect(tex(body),Rect2(fill.position/k,fill.size/k),true,tint if body=="earth" else Color(0.55,0.58,0.72) if scenery=="cave" else Color(0.7,0.7,0.74))
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
	if scenery=="cave" and room.has("ceiling"):
		var c=room.ceiling
		var bottom=float(c[1]+c[3])
		# Rock ceiling the vines actually hang from.
		canvas.draw_set_transform(Vector2.ZERO,0,Vector2.ONE*0.38)
		canvas.draw_texture_rect(tex("cave_wall"),Rect2(Vector2(c[0],c[1])/0.38,Vector2(c[2],c[3]+6)/0.38),true,Color(0.42,0.46,0.66))
		canvas.draw_set_transform(Vector2.ZERO)
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

## A tower doorway is part of a building: stone wall rising behind it.
func draw_facade(canvas: CanvasItem, at: Array) -> void:
	var base=Vector2(at[0],at[1]+2)
	var r=Rect2(base.x-70,base.y-250,140,250)
	canvas.draw_rect(r.grow(3),Color("3a2a22"))
	draw_tiled(canvas,"tower_wall",r,1.0,0.3,Color(0.95,0.95,0.98))
	var cap=tex("stone_ledge")
	var cw=r.size.x+24
	canvas.draw_texture_rect(cap,Rect2(r.position.x-12,r.position.y-14,cw,cw*cap.get_height()/cap.get_width()),false)

func props(canvas: CanvasItem) -> void:
	var opened: Array=game.world().opened
	if room.has("tower_facade"): draw_facade(canvas,room.tower_facade)
	var size=Vector2(room.size[0],room.size[1])
	for exit in room.get("exits",[]):
		if exit.has("door"):
			var kind="cave" if exit.kind=="cave" else ("wall_open" if exit.kind=="arch_out" else "tower_door")
			piece(canvas,kind,Vector2(exit.door[0],exit.door[1]+2),72 if kind=="cave" else 86)
		elif exit.has("edge"):
			# Path arch at the room edge: the way on is always visible.
			var x=40.0 if exit.edge=="left" else size.x-40.0
			var y=ground_y_at(x)
			piece(canvas,"arch",Vector2(x,y+3),92)
			piece(canvas,"arrow_sign",Vector2(x+(48 if exit.edge=="left" else -48),y+2),34,Color.WHITE,exit.edge=="left")
	if room.has("crank"):
		MeadowCrossingKit.draw_crank(canvas,Vector2(room.crank.pos[0],room.crank.pos[1]),crank_angle)
	var w_state=game.world()
	for sd in room.get("secret_doors",[]):
		piece(canvas,"wall_open" if sd.id in w_state.opened else "wall_closed",Vector2(sd.door[0],sd.door[1]+2),86)
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
		var name="hedgehog_ball" if c.dizzy>0 else ("hedgehog_a" if int(elapsed*5)%2==0 or reduced_motion else "hedgehog_b")
		piece(canvas,name,Vector2(c.x,c.y+2),22,Color.WHITE,c.dir<0)
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
	var font: Font=load(PetUI.MENU_FONT_PATH)
	for sign in room.get("signs",[]):
		var feet=Vector2(sign.pos[0],sign.pos[1]+2)
		piece(canvas,"sign",feet,40)
		# Short painted word on the board; the full text appears when you read it.
		var word: String=sign.get("word","TIP")
		var sz=7 if word.length()<=5 else 6
		var tw=font.get_string_size(word,HORIZONTAL_ALIGNMENT_LEFT,-1,sz).x
		canvas.draw_string(font,feet+Vector2(-tw*0.5+1.5,-29.5),word,HORIZONTAL_ALIGNMENT_LEFT,-1,sz,Color("3a2416"))
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
	for point in game.world().placed.get(room_id,[]):
		piece(canvas,"crate",Vector2(point[0],point[1]+1),CRATE+2)
	for dig in room.get("digs",[]):
		if dig.id in game.world().dug:
			if popped.has(dig.id) and elapsed-float(popped[dig.id])<1.6:
				var t=minf(elapsed-float(popped[dig.id]),0.5)/0.5
				var at=Vector2(dig.pos[0],dig.pos[1]-14-t*24)
				if dig.item=="crate": piece(canvas,"crate",at,20)
				else: canvas.draw_texture_rect(ArtTexture.load_texture(PetUI.COIN_PATH),Rect2(at-Vector2(7,14),Vector2(14,14)),false)
			continue
		# Foxy can smell it: a small mound and sparkle appear when she is close.
		if is_instance_valid(companion) and companion.position.distance_to(Vector2(dig.pos[0],dig.pos[1]))<150:
			var base=Vector2(dig.pos[0],dig.pos[1])
			canvas.draw_colored_polygon(PackedVector2Array([base+Vector2(-12,1),base+Vector2(-7,-5),base+Vector2(0,-7),base+Vector2(7,-5),base+Vector2(12,1)]),Color("6b4426"))
			canvas.draw_colored_polygon(PackedVector2Array([base+Vector2(-8,-1),base+Vector2(-4,-5),base+Vector2(3,-6),base+Vector2(8,-2)]),Color("9a6a3c"))
			var tw=0.55+0.45*sin(elapsed*4.0) if not reduced_motion else 0.9
			for k in range(3):
				var sp=base+Vector2(-9+k*9,-15-((k*7)%10)-(tw*5.0 if not reduced_motion else 0.0))
				var r=2.0+2.5*tw*(1.0 if k!=1 else 1.3)
				var star=func(radius: float) -> PackedVector2Array: return PackedVector2Array([sp+Vector2(0,-radius*1.6),sp+Vector2(radius*0.45,-radius*0.45),sp+Vector2(radius*1.6,0),sp+Vector2(radius*0.45,radius*0.45),sp+Vector2(0,radius*1.6),sp+Vector2(-radius*0.45,radius*0.45),sp+Vector2(-radius*1.6,0),sp+Vector2(-radius*0.45,-radius*0.45)])
				canvas.draw_colored_polygon(star.call(r+1.2),Color(0.35,0.2,0.05,0.85))
				canvas.draw_colored_polygon(star.call(r),Color(1,0.9,0.35))
				canvas.draw_circle(sp,r*0.35,Color(1,1,0.85))
	# Bouncing marker over a door, cave or arch you can go through right now.
	if near.get("kind","")=="door" or near.get("kind","") in ["lever","chest","shrine"]:
		var target: Array=near.data.get("door",near.data.get("pos",[0,0]))
		var bob=0.0 if reduced_motion else absf(sin(elapsed*4.0))*5.0
		var tip=Vector2(target[0],target[1]-(96 if near.kind=="door" else 46)-bob)
		canvas.draw_colored_polygon(PackedVector2Array([tip+Vector2(-9,-12),tip+Vector2(9,-12),tip]),Color("3a2416"))
		canvas.draw_colored_polygon(PackedVector2Array([tip+Vector2(-6,-10),tip+Vector2(6,-10),tip+Vector2(0,-3)]),Color("ffd34d"))
	# Ghost crate where Place would put it.
	if faces.interact[0]=="Place" and is_instance_valid(player):
		var spot=crate_spot()
		if spot!=Vector2.INF:
			var a=0.35+(0.0 if reduced_motion else 0.15*sin(elapsed*5.0))
			piece(canvas,"crate",spot+Vector2(0,1),CRATE+2,Color(1,1,1,a))
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
	if player.is_on_floor() and not on_moving_or_crumbling(): safe_point=player.position
	if player.position.y>size.y+40 or in_water():
		player.reset_to(safe_point)
		companion.position=safe_point-Vector2(24,0)
		companion.reset_physics_interpolation()
		hurt("Splash! Back on solid ground.",false)
	update_challenge(delta)
	collect_coins()
	find_near()
	if Input.is_action_just_pressed("interact"): use()
	if Input.is_action_just_pressed("pet_ability"): sniff()
	for node in content.get_children():
		if node is Node2D and node.name in ["Parallax","Terrain","Foreground"]: node.queue_redraw()

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
		if c.dizzy>0:
			c.dizzy-=delta
			continue
		c.x+=c.dir*28*delta
		if c.x>c.x1: c.dir=-1.0
		if c.x<c.x0: c.dir=1.0
		# Contact box: the hedgehog is ~22 tall; landing on its top is a stomp.
		if absf(player.position.x-c.x)<16 and player.position.y>c.y-26 and player.position.y<c.y+2:
			if player.velocity.y>40 and player.position.y<c.y-10:
				c.dizzy=3.0
				player.velocity.y=-240
				status.emit("Boing! The hedgehog curls up for a moment.")
			else: hurt("The hedgehog bumped you! Hop on top of it.",true,c.x)
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
	for plate in room.get("plates",[]):
		if plate_gates.has(plate.opens):
			var g=plate_gates[plate.opens]
			var open=plate_pressed(plate)
			if open!=g.open:
				g.open=open
				g.shape.set_deferred("disabled",open)
				if open: status.emit("The stone gate slides open!")
	var lanterns: Array=room.get("lanterns",[])
	for i in range(lanterns.size()):
		var at=Vector2(lanterns[i][0],lanterns[i][1])
		if player.position.distance_to(at)<30 and not "%s:%d"%[room_id,i] in game.world().lit:
			game.world_light(room_id,i,at)
			hearts=MAX_HEARTS
			hearts_changed.emit(hearts)
			status.emit("Lantern lit! If you get hurt, you come back here. Hearts refilled.")

func collect_coins() -> void:
	var coins: Array=room.get("coins",[])
	var body=player.position-Vector2(0,15)
	for i in range(coins.size()):
		if body.distance_to(Vector2(coins[i][0],coins[i][1]))<16: game.world_collect_coin(room_id,i)

func find_near() -> void:
	near={}
	var feet=player.position
	var w=game.world()
	for chest in room.get("chests",[]):
		if not chest.id in w.opened and feet.distance_to(Vector2(chest.pos[0],chest.pos[1]))<34: near={"kind":"chest","data":chest}
	for exit in active_exits():
		if exit.has("door") and feet.distance_to(Vector2(exit.door[0],exit.door[1]))<36: near={"kind":"door","data":exit}
	if room.has("crank") and bridge_locked() and feet.distance_to(Vector2(room.crank.pos[0],room.crank.pos[1]))<36: near={"kind":"crank","data":room.crank}
	for lever in room.get("levers",[]):
		if lever.dig in w.dug and not lever.opens in w.opened and feet.distance_to(Vector2(lever.pos[0],lever.pos[1]))<34: near={"kind":"lever","data":lever}
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
		"door": face=["Enter","act_enter"]
		"shrine": face=["Touch","act_use"]
		"lever": face=["Pull","act_use"]
		"crank": face=["Turn","act_use"]
		"crate": face=["Pick up","act_pick"]
		"sign": face=["Read","act_read"]
		_:
			if game.world_crates_free()>0 and player.is_on_floor(): face=["Place","act_place"]
	faces.interact=face
	faces.pet_ability=["Dig","act_dig"] if dig_spot()!={} else ["Find","act_find"]
	var line=""
	match near.get("kind",""):
		"chest": line="Open the treasure chest!"
		"door": line="Enter: "+near.data.label
		"shrine": line="A glowing Sky Feather. Touch it with Foxy!"
		"lever": line="An old lever! Pull it."
		"crank": line="Turn the wheel to lower the bridge!"
		"crate": line="Pick up the crate to use it somewhere else."
		"sign": line=near.data.text
	if line.is_empty():
		if dig_spot()!={}: line="Foxy smells something here! Press Dig."
		for gate in room.get("gates",[]):
			if not game.has_ability(gate.ability) and absf(feet.x-gate.rect[0])<90: line=gate.text
		for exit in room.get("exits",[]):
			if exit.has("edge") and ((exit.edge=="left" and feet.x<140) or (exit.edge=="right" and feet.x>float(room.size[0])-140)):
				line="Path home" if exit.to=="home" else "Path to "+exit.label
		if room.has("boost_hint") and not game.has_ability("foxy_boost") and feet.x>room.boost_hint[0] and feet.x<room.boost_hint[1]:
			line="Too high to jump. Something in the Hidden Cave can help!"
	if line.is_empty(): line=objective()
	prompt=line

## The undug spot Foxy is close enough to dig (within reach of the child).
func dig_spot() -> Dictionary:
	for dig in room.get("digs",[]):
		if not dig.id in game.world().dug and player.position.distance_to(Vector2(dig.pos[0],dig.pos[1]))<46: return dig
	return {}

func objective() -> String:
	var w=game.world()
	if room.get("challenge",false): return "Challenge room: reach the treasure at the end!"
	if not game.has_ability("foxy_boost"): return "Head right and find the Hidden Cave."
	var missing=0
	for r in GameState.world_data().rooms.values():
		for chest in r.get("chests",[]):
			if chest.part.begins_with("robot_") and not chest.id in w.opened: missing+=1
	if missing>0: return "Find %d more robot part%s. Use Double Jump and crates."%[missing,"" if missing==1 else "s"]
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
		"crank":
			if game.world_flag(near.data.id):
				var r=Rect2(room.bridge[0],room.bridge[1],room.bridge[2],room.bridge[3])
				collider(r,false)
				var t=create_tween()
				t.tween_property(self,"bridge_progress",1.0,0.0 if reduced_motion else 1.4)
				t.parallel().tween_property(self,"crank_angle",crank_angle+TAU*2.0,0.0 if reduced_motion else 1.4)
				companion.react(Companion.State.CELEBRATE)
				status.emit("Creak, creak... the bridge comes down!")
		"lever":
			if game.world_flag(near.data.opens):
				companion.react(Companion.State.CELEBRATE)
				status.emit("Rumble... a secret wall slid open by the windmill!")
		"crate":
			if game.world_pick_crate(room_id,near.index):
				build_crates()
				status.emit("Crate back in your bag.")
		"sign": status.emit(near.data.text)
		"":
			if game.world_crates_free()>0: place_crate()
		"shrine":
			var ability: String=near.data.ability
			if not game.has_ability(ability) and game.world_learn(ability):
				player.air_jumps=1
				companion.react(Companion.State.CELEBRATE)
				var info=GameState.world_data().abilities[ability]
				ability_learned.emit(info.title,info.text)

## Foxy points the way to the nearest unopened chest in this room.
func sniff() -> void:
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
	if best==Vector2.INF:
		status.emit("Foxy sniffs around... nothing hidden here.")
		return
	var way="to the right" if best.x>player.position.x+20 else ("to the left" if best.x<player.position.x-20 else "close by")
	if best.y<player.position.y-40: way+=", up high"
	status.emit("Foxy smells treasure "+way+"!")

func dig(spot: Dictionary) -> void:
	var at=Vector2(spot.pos[0],spot.pos[1])
	companion.ability_target=at+Vector2(-14 if companion.position.x<at.x else 14,0)
	companion.react(Companion.State.ABILITY,1.2)
	await get_tree().create_timer(0.9).timeout
	if not is_instance_valid(companion): return
	companion.ability_target=Vector2.INF
	if game.world_dig(spot.id,spot.item):
		popped[spot.id]=elapsed
		if spot.item=="crate" and not "crate_help" in game.world().opened:
			game.world_flag("crate_help")
			ability_learned.emit("Crate","Tap Place to put the crate in front of you (you'll see a see-through crate first). Jump on it to reach higher. Stand next to it and tap Pick up to take it back.")
		var said={"crate":"Foxy dug up a crate! It's in your bag.","lever":"Foxy dug up an old lever! Try pulling it."}
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
		build_crates()
		status.emit("Crate placed. Jump on it!")

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
