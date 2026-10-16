extends Control
## One native placement flow for touch, mouse and keyboard. No prescribed spots.
var app: Control
var level: PicnicAdventure
var tools: TrailCrates
var panel: Panel
var hint: Label
var confirm_button: Button
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 level=app.active_adventure
 tools=level.crates
 TouchControls.release_actions()
 level.player.enabled=false
 level.player.velocity.x=0
 level.player.art.travel_speed=0
 level.player.art.mood="idle" if level.player.is_on_floor() else "jump"
 tools.placing=true
 tools.choose_at(level.player.position+Vector2(level.player.art.facing*36,0),level.player.position)
 panel=PetUI.panel(self,Rect2(0,0,366,180))
 hint=PetUI.label(panel,"",Vector2(12,6),16,PetUI.INK,342)
 PetUI.button(panel,"Left",Rect2(12,58,70,52),func():shift(-6))
 PetUI.button(panel,"Right",Rect2(90,58,70,52),func():shift(6))
 confirm_button=PetUI.button(panel,"Place",Rect2(168,58,186,52),confirm,true)
 PetUI.button(panel,"Cancel",Rect2(12,118,342,50),cancel)
func _physics_process(delta: float) -> void:
 if not is_instance_valid(level) or get_tree().paused:return
 # Placement stops walking input, while an already-airborne child still lands.
 if not level.player.is_on_floor() or level.player.velocity.y!=0:
  level.player.velocity.y+=Explorer.GRAVITY*delta
  level.player.move_and_slide()
  level.player.art.grounded=level.player.is_on_floor()
  level.player.art.mood="idle" if level.player.is_on_floor() else "jump"
func world_rect() -> Rect2:
 if app.portrait_ui.visible:return app.portrait_ui.stage_rect
 return Rect2(Vector2.ZERO,Vector2(get_window().content_scale_size))
func _process(_delta: float) -> void:
 if not is_instance_valid(level):cancel();return
 var portrait=app.portrait_ui.visible
 var safe=app.adventure_ui.safe if is_instance_valid(app.adventure_ui) else (app.portrait_ui.safe_bounds if portrait else Rect2(16,16,1248,688))
 panel.position=Vector2(safe.get_center().x-183,safe.end.y-184)
 var okay=tools.can_place(level.player.position)
 confirm_button.disabled=not okay
 hint.text="Tap the ground or use Left / Right. %d free."%app.game.available_crates() if okay else tools.reason
 if is_instance_valid(app.adventure_ui) and is_instance_valid(app.adventure_ui.controls):
  app.adventure_ui.controls.visible=false
  app.adventure_ui.controls.set_process_input(false)
 for control in app.ui.get_children():
  if control is TouchControls:
   control.visible=false
   control.set_process_input(false)
 if is_instance_valid(app.portrait_ui.controls):
  app.portrait_ui.controls.visible=false
  app.portrait_ui.controls.set_process_input(false)
func choose_screen(point: Vector2) -> void:
 var bounds=world_rect()
 if not bounds.has_point(point):return
 var local=(point-bounds.position)/bounds.size*app.viewport.get_visible_rect().size
 var world_point=app.viewport.canvas_transform.affine_inverse()*local
 tools.choose_at(world_point,level.player.position)
func shift(amount: float) -> void:
 tools.choose_at(Vector2(tools.candidate.x+amount,tools.candidate.y+12),level.player.position)
func _input(event: InputEvent) -> void:
 if event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventMouseButton:
  if panel.get_global_rect().has_point(event.position) or not world_rect().has_point(event.position):return
  for button in app.get_tree().root.find_children("*","Button",true,false):
   if button.is_visible_in_tree() and button.get_global_rect().has_point(event.position):return
 if event.is_action_pressed("pause") or event.is_action_pressed("adventure_bag"):
  cancel()
  get_viewport().set_input_as_handled()
 elif event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
  shift(-6 if event.is_action_pressed("move_left") else 6)
  get_viewport().set_input_as_handled()
 elif event is InputEventScreenTouch and event.pressed:
  choose_screen(event.position)
  get_viewport().set_input_as_handled()
 elif event is InputEventScreenDrag:
  choose_screen(event.position)
  get_viewport().set_input_as_handled()
 elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
  choose_screen(event.position)
  get_viewport().set_input_as_handled()
func confirm() -> void:
 if tools.confirm(level.player.position):cancel()
func cancel() -> void:
 TouchControls.release_actions()
 if is_instance_valid(level):
  tools.placing=false
  tools.queue_redraw()
  level.player.enabled=not level.done
 if is_instance_valid(app.portrait_ui.controls):
  app.portrait_ui.controls.visible=true
  app.portrait_ui.controls.set_process_input(app.portrait_ui.visible)
 for control in app.ui.get_children():
  if control is TouchControls:
   control.visible=true
   control.set_process_input(not app.portrait_ui.visible)
 if is_instance_valid(app.adventure_ui) and is_instance_valid(app.adventure_ui.controls):
  app.adventure_ui.controls.visible=true
  app.adventure_ui.controls.set_process_input(not app.orientation_blocked)
 app.placement_ui=null
 queue_free()
