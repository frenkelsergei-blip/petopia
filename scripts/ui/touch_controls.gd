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
const PAPER_DEFAULT_ICON={"act_find":"ic_find","act_use":"ic_use","act_jump":"ic_jump"}
var paper_faces: Dictionary={}
var paper_discs: Dictionary={}
var font: Font

func _ready() -> void:
	if ArtStyle.paper:
		joystick_texture=ArtTexture.load_texture(PAPER_UI+"stick_base.png")
		knob_texture=ArtTexture.load_texture(PAPER_UI+"stick_knob.png")
		font=load(PetUI.MENU_FONT_PATH)
	else:
		joystick_texture=ArtTexture.load_texture("res://assets/ui/kit-v1/stick_base.png")
		knob_texture=ArtTexture.load_texture("res://assets/ui/kit-v1/stick_knob.png")
	# Bigger stick for small thumbs (was button_size); the paper ring is calmer and smaller.
	joystick_radius=float(button_size)*(1.0 if ArtStyle.paper else 1.2)*stick_scale
	if portrait_bounds.size.x>0:
		# V02: one row of square wooden tiles, icon above caption, Jump nearest the thumb.
		var tile=tile_size()
		var b=portrait_bounds
		var y=b.end.y-tile.y*.5
		# Left-handed: mirror the layout (stick right, Jump at the far left).
		var side=-1.0 if left_handed else 1.0
		var edge=b.position.x if left_handed else b.end.x
		joystick_center=Vector2(b.end.x-joystick_radius if left_handed else b.position.x+joystick_radius,b.end.y-joystick_radius)
		create_action("jump",Vector2(edge-side*tile.x*.5,y),"Jump","act_jump")
		create_action("interact",Vector2(edge-side*(tile.x*1.5+button_spacing),y),"Use","act_use")
		create_action("pet_ability",Vector2(edge-side*(tile.x*2.5+button_spacing*2),y),"Find","act_find")
	else:
		joystick_center=Vector2(120,630)
		create_action("jump",Vector2(1178,630),"Jump")
		create_action("interact",Vector2(1078,630),"Use")
		create_action("pet_ability",Vector2(978,630),"Find")
	regions["move_left"]=Rect2(joystick_center-Vector2.ONE*joystick_radius,Vector2(joystick_radius,joystick_radius*2))
	regions["move_right"]=Rect2(joystick_center-Vector2(0,joystick_radius),Vector2(joystick_radius,joystick_radius*2))
	queue_redraw()

## Round kit action buttons: square hit area, art drawn at its own proportion.
func tile_size() -> Vector2:
	var side=button_size*1.2
	if portrait_bounds.size.x>0:
		# Three buttons and the stick must fit the safe width at every setting.
		var room=(portrait_bounds.size.x-joystick_radius*2-button_spacing*3)/3.0
		side=clampf(room,48.0,side)
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
	draw_texture_rect(joystick_texture,Rect2(joystick_center-Vector2.ONE*joystick_radius,Vector2.ONE*joystick_radius*2),false)
	var cap_size=joystick_radius*(1.2 if ArtStyle.paper else .72)
	draw_texture_rect(knob_texture,Rect2(joystick_center+thumb_offset-Vector2.ONE*cap_size/2,Vector2.ONE*cap_size),false)
	for action in paper_faces: draw_paper_button(action)

func draw_paper_button(action: String) -> void:
	var r: Rect2=regions[action]
	var held=held_fingers.values().has(action)
	var k=(0.92 if held else 1.0)*(1.0+0.12*float(pop.get(action,0.0)))
	var size=r.size*k
	var box=Rect2(r.get_center()-size*0.5,size)
	if not paper_discs.has(action): paper_discs[action]=ArtTexture.load_texture(PAPER_UI+PAPER_BUTTON[action][0]+".png")
	draw_texture_rect(paper_discs[action],box,false,Color(0.85,0.85,0.85) if held else Color.WHITE)
	var glyph: Texture2D=paper_faces[action][1]
	if glyph!=null:
		var side=size.x*0.42
		draw_texture_rect(glyph,Rect2(box.position+Vector2((size.x-side)*0.5,size.y*0.17),Vector2(side,side)),false)
	var caption: String=paper_faces[action][0]
	var points=int(clampf(size.x*0.2,11,20))
	draw_string(font,Vector2(box.position.x,box.position.y+size.y*0.86),caption,HORIZONTAL_ALIGNMENT_CENTER,size.x,points,Color("5a3418"))

func _process(delta: float) -> void:
	for action in pop.keys():
		if pop[action]>0.0:
			pop[action]=maxf(0.0,pop[action]-delta*5.5)
			queue_redraw()
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
	var action="" if absf(offset.x)<joystick_radius*.18 else ("move_left" if offset.x<0 else "move_right")
	_set_pointer(pointer,action)
	queue_redraw()

## The stick reacts a little outside its ring.
const STICK_REACH=1.45
func _press(pointer: int, point: Vector2) -> bool:
	if joystick_pointer==-2 and _local(point).distance_to(joystick_center)<=joystick_radius*STICK_REACH:
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
	elif event is InputEventMouseMotion: handled=_drag(-1,event.position)
	if handled: get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:
		held_fingers.clear()
		joystick_pointer=-2
		thumb_offset=Vector2.ZERO
		release_actions()
		queue_redraw()

func _exit_tree() -> void: release_actions()

static func release_actions() -> void:
	for action in ["move_left","move_right","jump","interact","pet_ability"]: Input.action_release(action)
