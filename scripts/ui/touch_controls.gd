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
var action_panels: Dictionary={}

func _ready() -> void:
	joystick_texture=load("res://assets/ui/touch-v1/joystick.png")
	joystick_radius=float(button_size)
	if portrait_bounds.size.x>0:
		var edge=button_size*0.5
		var right=portrait_bounds.end.x
		var y=portrait_bounds.end.y-edge
		joystick_center=Vector2(portrait_bounds.position.x+joystick_radius,portrait_bounds.end.y-joystick_radius)
		create_action("jump",Vector2(right-edge,y),"Jump")
		create_action("interact",Vector2(right-edge,y-button_size-8),"Use")
		create_action("pet_ability",Vector2(right-edge-button_size-button_spacing,y-button_size-8),"Find")
	else:
		joystick_center=Vector2(120,630)
		create_action("jump",Vector2(1178,630),"Jump")
		create_action("interact",Vector2(1078,630),"Use")
		create_action("pet_ability",Vector2(978,630),"Find")
	regions["move_left"]=Rect2(joystick_center-Vector2.ONE*joystick_radius,Vector2(joystick_radius,joystick_radius*2))
	regions["move_right"]=Rect2(joystick_center-Vector2(0,joystick_radius),Vector2(joystick_radius,joystick_radius*2))
	queue_redraw()

func create_action(action: String, xy: Vector2, caption: String) -> void:
	var half=Vector2.ONE*button_size*.5 if portrait_bounds.size.x>0 else Vector2(44,34)
	regions[action]=Rect2(xy-half,half*2)
	var panel=Panel.new()
	panel.position=xy-half
	panel.size=half*2
	panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	panel.add_theme_stylebox_override("panel",PetUI.menu_style(false))
	add_child(panel)
	action_panels[action]=panel
	var label=PetUI.label(panel,caption,Vector2.ZERO,19,PetUI.INK)
	label.add_theme_font_override("font",load(PetUI.MENU_FONT_PATH))
	label.size=half*2
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER

func _draw() -> void:
	if joystick_texture==null: return
	draw_texture_rect_region(joystick_texture,Rect2(joystick_center-Vector2.ONE*joystick_radius,Vector2.ONE*joystick_radius*2),Rect2(64,48,784,784))
	var cap_size=joystick_radius*.8
	draw_texture_rect_region(joystick_texture,Rect2(joystick_center+thumb_offset-Vector2.ONE*cap_size/2,Vector2.ONE*cap_size),Rect2(1158,272,344,344))

func _local(point: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse()*point

func _action_at(point: Vector2) -> String:
	var local=_local(point)
	for action in regions:
		if regions[action].has_point(local): return action
	return ""

func _set_pointer(pointer: int, action: String) -> void:
	var old: String=held_fingers.get(pointer,"")
	if old==action: return
	held_fingers.erase(pointer)
	if not old.is_empty() and not held_fingers.values().has(old): Input.action_release(old)
	if not action.is_empty():
		held_fingers[pointer]=action
		Input.action_press(action)
	for key in action_panels:
		action_panels[key].add_theme_stylebox_override("panel",PetUI.menu_style(held_fingers.values().has(key)))

func _stick(pointer: int, point: Vector2) -> void:
	var offset=_local(point)-joystick_center
	thumb_offset=offset.limit_length(joystick_radius*.48)
	var action="" if absf(offset.x)<joystick_radius*.18 else ("move_left" if offset.x<0 else "move_right")
	_set_pointer(pointer,action)
	queue_redraw()

func _press(pointer: int, point: Vector2) -> bool:
	if joystick_pointer==-2 and _local(point).distance_to(joystick_center)<=joystick_radius:
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
	if event is InputEventScreenTouch:
		handled=_press(event.index,event.position) if event.pressed else _release(event.index)
	elif event is InputEventScreenDrag: handled=_drag(event.index,event.position)
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.device!=-1:
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
