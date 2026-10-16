class_name FollowCamera
extends Camera2D
## Follow after character physics, with the same interpolation clock as the actors.
var target: Node2D
var scenery: Meadow
var course_width=3280.0
func _init() -> void:
	zoom=Vector2(1.7,1.7)
	process_callback=Camera2D.CAMERA2D_PROCESS_PHYSICS
	process_physics_priority=100
	position_smoothing_enabled=false

func _ready() -> void:
	limit_left=0
	limit_right=int(course_width)
	limit_top=0
	limit_bottom=360
	snap_to_target()
func _physics_process(_delta: float) -> void: follow_target()
func follow_target() -> void:
	if not is_instance_valid(target): return
	var half_width=get_viewport_rect().size.x*0.5/zoom.x
	var half_height=get_viewport_rect().size.y*0.5/zoom.y
	position=Vector2(clampf(target.position.x,half_width,course_width-half_width),clampf(minf(252,target.position.y+56),half_height,360-half_height))
	if is_instance_valid(scenery): scenery.camera_x=position.x-half_width
func snap_to_target() -> void:
	follow_target()
	reset_physics_interpolation()
	reset_smoothing()
