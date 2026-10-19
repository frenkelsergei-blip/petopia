class_name TouchControls
extends Node2D
## Captured circular stick plus independent action fingers; keyboard/gamepad share
## the same InputMap. Sliding outside the ring does not abandon the held stick.
var regions: Dictionary={}
var held_fingers: Dictionary={}
var portrait_bounds=Rect2()
var button_size=60
var button_spacing=12
var joystick_center=Vector2.ZERO
var joystick_radius=60.0
var joystick_pointer=-2
var thumb_offset=Vector2.ZERO
var joystick_texture: Texture2D
var knob_texture: Texture2D
var action_panels: Dictionary={}
## Settings: joystick size, and left-handed (stick right, buttons left).
var stick_scale=1.0
var left_handed=false

## A55 paper controls (P10): cardboard ring with a cream disc and brass knob,
## coloured paper buttons with a cream caption band.
const PAPER_UI="res://assets/ui/paper-v1/"
const PAPER_BUTTON={"pet_ability":["btn_orange","ic_find"],"interact":["btn_blue","ic_use"],"jump":["btn_blue2","ic_jump"]}
const PAPER_DEFAULT_ICON={"act_find":"ic_find","act_use":"ic_use","act_jump":"ic_jump","act_dig":"ic_dig","act_enter":"ic_enter","act_open":"ic_open","act_pick":"ic_pick","act_place":"ic_place","act_read":"ic_talk"}
## A57 (P40): torn-paper discs, icons in cream on green/gold, navy on cream,
## the caption under the disc.
const P32_HUD="res://assets/ui/hud-p32/"
const P32_KIT="res://assets/ui/hud2-p32/"
const P32_DISC={"pet_ability":"disc_green","interact":"disc_cream","jump":"disc_gold"}
const P32_ICON={"act_find":"w_paw","act_dig":"w_dig","act_jump":"w_up","act_use":"n_use","act_enter":"n_enter","act_open":"n_open","act_pick":"n_pick","act_place":"n_place","act_read":"n_talk"}
var P32: bool:
	get: return ResourceLoader.exists(P32_KIT+"disc_green.png")
var paper_faces: Dictionary={}
var paper_discs: Dictionary={}
var font: Font

func _ready() -> void:
	if ArtStyle.paper and P32:
		joystick_texture=ArtTexture.load_texture(P32_HUD+"stick_base.png")
		knob_texture=ArtTexture.load_texture(P32_HUD+"stick_knob.png")
		font=load(PetUI.MENU_FONT_PATH)
	elif ArtStyle.paper:
		joystick_texture=ArtTexture.load_texture(PAPER_UI+"stick_base.png")
		knob_texture=ArtTexture.load_texture(PAPER_UI+"stick_knob.png")
		font=load(PetUI.MENU_FONT_PATH)
	else:
		joystick_texture=ArtTexture.load_texture("res://assets/ui/kit-v1/stick_base.png")
		knob_texture=ArtTexture.load_texture("res://assets/ui/kit-v1/stick_knob.png")
	# Bigger stick for small thumbs (was button_size); the paper ring is calmer and smaller.
	# P40: the paper stick is a little smaller than the old ring (setting can enlarge it).
	# A big, easy stick for small thumbs (the size setting scales it further).
	joystick_radius=float(button_size)*(1.4 if ArtStyle.paper and P32 else 1.25)*stick_scale
	if portrait_bounds.size.x>0:
		# V02: one row of square wooden tiles, icon above caption, Jump nearest the thumb.
		var b=portrait_bounds
		# Bigger stick, but never so big that it meets the action buttons.
		joystick_radius=minf(joystick_radius,minf((b.size.x-3*48.0-button_spacing*4)*0.5,b.size.y*0.47))
		var tile=tile_size()
		var y=b.end.y-tile.y*.5
		# Left-handed: mirror the layout (stick right, Jump at the far left).
		var side=-1.0 if left_handed else 1.0
		var edge=b.position.x if left_handed else b.end.x
		joystick_center=Vector2(b.end.x-joystick_radius if left_handed else b.position.x+joystick_radius,b.end.y-joystick_radius)
		create_action("jump",Vector2(edge-side*tile.x*.5,y),"Jump","act_jump")
		create_action("interact",Vector2(edge-side*(tile.x*1.5+button_spacing),y),"Use","act_use")
		create_action("pet_ability",Vector2(edge-side*(tile.x*2.5+button_spacing*2),y),"Find","act_find")
	else:
		# The bigger stick keeps a margin from the screen edges.
		joystick_center=Vector2(maxf(120.0,joystick_radius+30.0),720.0-maxf(90.0,joystick_radius+22.0))
		create_action("jump",Vector2(1178,630),"Jump")
		create_action("interact",Vector2(1078,630),"Use")
		create_action("pet_ability",Vector2(978,630),"Find")
	home_center=joystick_center
	regions["move_left"]=Rect2(joystick_center-Vector2.ONE*joystick_radius,Vector2(joystick_radius,joystick_radius*2))
	regions["move_right"]=Rect2(joystick_center-Vector2(0,joystick_radius),Vector2(joystick_radius,joystick_radius*2))
	queue_redraw()

## Round kit action buttons: square hit area, art drawn at its own proportion.
func tile_size() -> Vector2:
	var side=button_size*1.2
	if portrait_bounds.size.x>0:
		# Three buttons and the stick must fit the safe width at every setting.
		var room=(portrait_bounds.size.x-joystick_radius*2-button_spacing*3)/3.0
		side=clampf(floorf(room)-1.0,48.0,side)
	return Vector2.ONE*side

func create_action(action: String, xy: Vector2, caption: String, icon="") -> void:
	var half=tile_size()*.5 if portrait_bounds.size.x>0 else Vector2(44,34)
	regions[action]=Rect2(xy-half,half*2)
	var panel=Panel.new()
	panel.position=xy-half
	panel.size=half*2
	panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	PetUI.set_piece(panel,"action")
	add_child(panel)
	action_panels[action]=panel
	if ArtStyle.paper and PAPER_BUTTON.has(action):
		panel.visible=false
		paper_faces[action]=[caption,ArtTexture.load_texture(PAPER_UI+PAPER_BUTTON[action][1]+".png")]
		if P32: paper_faces[action]=[caption,ArtTexture.load_texture(P32_KIT+P32_ICON[{"pet_ability":"act_find","interact":"act_use","jump":"act_jump"}[action]]+".png")]
	if icon.is_empty():
		PetUI.compose(panel,caption,null,"row",19)
	else:
		PetUI.compose(panel,caption,CareArt.icon(icon),"round_label")

## Context buttons: show what the action does here (Enter, Open, Dig...).
var faces: Dictionary={}
func set_face(action: String, caption: String, icon: String) -> void:
	if not action_panels.has(action) or faces.get(action,"")==caption+icon: return
	faces[action]=caption+icon
	if paper_faces.has(action):
		var glyph: Texture2D=ArtTexture.load_texture(PAPER_UI+PAPER_DEFAULT_ICON[icon]+".png") if PAPER_DEFAULT_ICON.has(icon) else CareArt.icon(icon)
		if P32 and P32_ICON.has(icon):
			# Icons sit on their disc colour: cream glyphs on green/gold, navy on cream.
			var key: String=P32_ICON[icon]
			if action=="interact" and key.begins_with("w_"): key="n_"+key.substr(2)
			if action!="interact" and key.begins_with("n_"): key="w_"+key.substr(2)
			if ResourceLoader.exists(P32_KIT+key+".png"): glyph=ArtTexture.load_texture(P32_KIT+key+".png")
		paper_faces[action]=[caption,glyph]
		pop[action]=0.0 if reduced_motion_pref else 1.0
		queue_redraw()
		return
	PetUI.compose(action_panels[action],caption,CareArt.icon(icon),"round_label")
	var panel: Control=action_panels[action]
	if not reduced_motion_pref:
		panel.pivot_offset=panel.size*0.5
		panel.scale=Vector2.ONE*1.12
		create_tween().tween_property(panel,"scale",Vector2.ONE,0.18)
var reduced_motion_pref=false
var pop: Dictionary={}

func _draw() -> void:
	if joystick_texture==null: return
	# Faint while resting so the world shows through; solid under the thumb.
	var a=STICK_ACTIVE_ALPHA if joystick_pointer!=-2 else STICK_IDLE_ALPHA
	if ArtStyle.paper and P32:
		for k in 4: draw_circle(joystick_center+Vector2(0,4),joystick_radius*(1.04-k*0.03),Color(0.05,0.1,0.2,0.06*a))
	draw_texture_rect(joystick_texture,Rect2(joystick_center-Vector2.ONE*joystick_radius,Vector2.ONE*joystick_radius*2),false,Color(1,1,1,a))
	var cap_size=joystick_radius*((.98 if P32 else .62) if ArtStyle.paper else .72)
	if ArtStyle.paper and P32:
		# P40: the knob casts a soft shadow on the ring.
		for k in 3: draw_circle(joystick_center+thumb_offset+Vector2(2,4),cap_size*(0.56-k*0.05),Color(0.05,0.15,0.35,0.1*a))
	draw_texture_rect(knob_texture,Rect2(joystick_center+thumb_offset-Vector2.ONE*cap_size/2,Vector2.ONE*cap_size),false,Color(1,1,1,a))
	for action in paper_faces: draw_paper_button(action)

func draw_paper_button(action: String) -> void:
	var r: Rect2=regions[action]
	var held=held_fingers.values().has(action)
	var k=(0.92 if held else 1.0)*(1.0+0.12*float(pop.get(action,0.0)))
	var size=r.size*k
	var box=Rect2(r.get_center()-size*0.5,size)
	if not paper_discs.has(action): paper_discs[action]=ArtTexture.load_texture((P32_KIT+P32_DISC[action] if P32 else PAPER_UI+PAPER_BUTTON[action][0])+".png")
	if P32:
		# Just the disc and its icon (no words): the icon says what it does.
		var d=size.x*0.94
		var disc=Rect2(box.get_center()-Vector2(d,d)*0.5,Vector2(d,d))
		# The same light, even shadow as every paper button, then a white border.
		var sh: Texture2D=ConceptScreen.soft_shadow(paper_discs[action])
		if sh: draw_texture_rect(sh,ConceptScreen.shadow_rect(disc.grow(d*0.04),sh),false,Color(1,1,1,ConceptScreen.BUTTON_SHADOW))
		draw_circle(disc.get_center(),d*0.54,Color("fffaf0"))
		draw_texture_rect(paper_discs[action],disc,false,Color(0.85,0.85,0.85) if held else Color.WHITE)
		var g: Texture2D=paper_faces[action][1]
		if g!=null:
			var side=d*0.56
			var fit=Vector2(g.get_width(),g.get_height())*side/maxf(g.get_width(),g.get_height())
			var gr=Rect2(disc.get_center()-fit*0.5,fit)
			var gs: Texture2D=ConceptScreen.soft_shadow(g)
			if gs: draw_texture_rect(gs,ConceptScreen.shadow_rect(gr,gs),false,Color(1,1,1,ConceptScreen.BUTTON_SHADOW*0.8))
			draw_texture_rect(g,gr,false)
		return
	draw_texture_rect(paper_discs[action],box,false,Color(0.85,0.85,0.85) if held else Color.WHITE)
	var glyph: Texture2D=paper_faces[action][1]
	if glyph!=null:
		# Fit the glyph in the coloured disc keeping its own proportions.
		var side=size.x*0.42
		var fit=Vector2(glyph.get_width(),glyph.get_height())
		fit*=side/maxf(fit.x,fit.y)
		var centre=box.position+Vector2(size.x*0.5,size.y*0.17+side*0.5)
		draw_texture_rect(glyph,Rect2(centre-fit*0.5,fit),false)
	var caption: String=paper_faces[action][0]
	var points=int(clampf(size.x*0.2,11,20))
	draw_string(font,Vector2(box.position.x,box.position.y+size.y*0.86),caption,HORIZONTAL_ALIGNMENT_CENTER,size.x,points,Color("5a3418"))

func _process(delta: float) -> void:
	for action in pop.keys():
		if pop[action]>0.0:
			pop[action]=maxf(0.0,pop[action]-delta*5.5)
			queue_redraw()
	# A mouse release outside the window never arrives: let go when the
	# button is up, so the stick springs back and the child stops.
	if joystick_pointer==-1 and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): _release(-1)
	if held_fingers.has(-1) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): _release(-1)
	for pointer in held_fingers:
		var action: String=held_fingers[pointer]
		if not action.is_empty() and not Input.is_action_pressed(action): Input.action_press(action)

func _local(point: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse()*point

func _action_at(point: Vector2) -> String:
	var local=_local(point)
	for action in regions:
		if regions[action].has_point(local): return action
	return ""

func _set_pointer(pointer: int, action: String) -> void:
	var old: String=held_fingers.get(pointer,"")
	# Room changes release all actions while a thumb may still be held; press
	# again so the stick never silently stops moving the child.
	if old==action and (action.is_empty() or Input.is_action_pressed(action)): return
	held_fingers.erase(pointer)
	if not old.is_empty() and not held_fingers.values().has(old): Input.action_release(old)
	if not action.is_empty():
		held_fingers[pointer]=action
		Input.action_press(action)
	if not paper_faces.is_empty(): queue_redraw()
	for key in action_panels:
		PetUI.set_piece(action_panels[key],"action_pressed" if held_fingers.values().has(key) else "action")

func _stick(pointer: int, point: Vector2) -> void:
	var offset=_local(point)-joystick_center
	thumb_offset=offset.limit_length(joystick_radius*.48)
	# Small dead zone: a slight push left or right is enough.
	var action="" if absf(offset.x)<joystick_radius*.1 else ("move_left" if offset.x<0 else "move_right")
	_set_pointer(pointer,action)
	queue_redraw()

## The stick reacts a little outside its ring.
const STICK_REACH=1.45
## Floating stick: it rests faintly at home and jumps to wherever the thumb
## lands on the movement side of the screen, then goes home when released.
const STICK_IDLE_ALPHA=0.4
const STICK_ACTIVE_ALPHA=0.9
var home_center=Vector2.ZERO
func move_zone() -> Rect2:
	var b=portrait_bounds if portrait_bounds.size.x>0 else Rect2(0,0,1280,720)
	var w=b.size.x*0.45
	return Rect2(b.end.x-w if left_handed else b.position.x,b.position.y+b.size.y*0.3,w,b.size.y*0.7)
func _press(pointer: int, point: Vector2) -> bool:
	var local=_local(point)
	if joystick_pointer==-2 and local.distance_to(joystick_center)<=joystick_radius*STICK_REACH:
		joystick_pointer=pointer
		_stick(pointer,point)
		return true
	if joystick_pointer==-2 and move_zone().has_point(local) and not _action_at(point) in ["jump","interact","pet_ability"]:
		# The stick comes to the thumb (kept fully on screen).
		var z=move_zone()
		var b=portrait_bounds if portrait_bounds.size.x>0 else Rect2(0,0,1280,720)
		joystick_center=Vector2(clampf(local.x,b.position.x+joystick_radius,b.end.x-joystick_radius),clampf(local.y,z.position.y+joystick_radius*0.5,b.end.y-joystick_radius))
		joystick_pointer=pointer
		_stick(pointer,point)
		return true
	var action=_action_at(point)
	if action.begins_with("move_"): return false
	_set_pointer(pointer,action)
	return not action.is_empty()

func _release(pointer: int) -> bool:
	var owned=held_fingers.has(pointer) or joystick_pointer==pointer
	if joystick_pointer==pointer:
		joystick_pointer=-2
		thumb_offset=Vector2.ZERO
		if home_center!=Vector2.ZERO: joystick_center=home_center
		queue_redraw()
	_set_pointer(pointer,"")
	return owned

func _drag(pointer: int, point: Vector2) -> bool:
	# A finger already down on the stick when the controls were rebuilt adopts it.
	if joystick_pointer==-2 and not held_fingers.has(pointer) and _local(point).distance_to(joystick_center)<=joystick_radius*STICK_REACH:
		joystick_pointer=pointer
	if joystick_pointer==pointer:
		_stick(pointer,point)
		return true
	if held_fingers.has(pointer):
		var action=_action_at(point)
		_set_pointer(pointer,"" if action.begins_with("move_") else action)
		return true
	return false

func _input(event: InputEvent) -> void:
	var handled=false
	# Browsers and phones also send each touch as an emulated mouse event.
	# Only real touches own the stick: an emulated mouse move could grab it
	# after a rebuild, and its release would then never arrive (stuck walking).
	if event is InputEventMouse and event.device==InputEvent.DEVICE_ID_EMULATION: return
	if event is InputEventScreenTouch:
		handled=_press(event.index,event.position) if event.pressed else _release(event.index)
	elif event is InputEventScreenDrag: handled=_drag(event.index,event.position)
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		handled=_press(-1,event.position) if event.pressed else _release(-1)
	# Only a held button drags: a hovering mouse must never grab the stick.
	elif event is InputEventMouseMotion and event.button_mask&MOUSE_BUTTON_MASK_LEFT: handled=_drag(-1,event.position)
	if handled: get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_WM_MOUSE_EXIT,NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
		held_fingers.clear()
		joystick_pointer=-2
		thumb_offset=Vector2.ZERO
		release_actions()
		queue_redraw()

func _exit_tree() -> void: release_actions()

static func release_actions() -> void:
	for action in ["move_left","move_right","jump","interact","pet_ability"]: Input.action_release(action)
