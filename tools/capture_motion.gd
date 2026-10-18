extends SceneTree
## Records the explorer and Foxy running and jumping in Meadow Fields: a strip
## of frames around the child (MOTION_DIR, default res://test-results/motion/).
var main: Control
func _initialize() -> void: call_deferred("run")
func shot(out: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+name+".png")
func run() -> void:
	var out=OS.get_environment("MOTION_DIR") if OS.get_environment("MOTION_DIR")!="" else "res://test-results/motion/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	root.size=Vector2i(844,390)
	main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory="user://motion/"+str(Time.get_ticks_usec())
	root.add_child(main)
	main.game.adopt("Foxy")
	main.show_world()
	for i in 30: await physics_frame
	main.active_world.player.reset_to(Vector2(1040,288))
	main.active_world.camera.snap_to_target()
	for i in 20: await physics_frame
	Input.action_press("move_right")
	for i in 40: await physics_frame
	for k in 8:
		for i in 3: await physics_frame
		await shot(out,"run-%d"%k)
	Input.action_press("jump")
	for k in 10:
		for i in 4: await physics_frame
		if k==1: Input.action_release("jump")
		await shot(out,"jump-%d"%k)
	Input.action_release("move_right")
	for i in 40: await physics_frame
	await shot(out,"idle")
	main.free()
	await process_frame
	quit()
