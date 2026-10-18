extends SceneTree
## Captures every Green Meadows room of the V2 connected world in landscape,
## with the child and Foxy standing at each room's spawn (and one walk step).
## Output: test-results/world/<room>.png (override with WORLD_DIR).
var main: Control
func _initialize() -> void: call_deferred("run")
var drawn=false
func settle(n=20) -> void:
	for i in range(n): await physics_frame
	drawn=false
	RenderingServer.frame_post_draw.connect(func(): drawn=true,CONNECT_ONE_SHOT)
	var waited=0.0
	while not drawn and waited<5.0:
		await create_timer(0.05).timeout
		waited+=0.05
func run() -> void:
	root.size=Vector2i(1280,720)
	main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory="user://paper/"+str(Time.get_ticks_usec())
	root.add_child(main)
	main.game.adopt("Foxy")
	main.game.state.pets[0].growth_stage="child"
	main.game.set_preference("place_names",false)
	main.show_world()
	await settle(30)
	var w=main.active_world
	w.player.reset_to(Vector2(560,288))
	w.camera.snap_to_target()
	await settle(20)
	root.get_texture().get_image().save_png("/private/tmp/claude-154376277/-Users-sfrenkel-Petopia/00377cb5-9802-4224-8c59-a619dec42db8/scratchpad/paper-1.png")
	Input.action_press("move_right")
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/private/tmp/claude-154376277/-Users-sfrenkel-Petopia/00377cb5-9802-4224-8c59-a619dec42db8/scratchpad/paper-2.png")
	Input.action_release("move_right")
	quit()
