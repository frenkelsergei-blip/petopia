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
	var out=OS.get_environment("WORLD_DIR") if OS.get_environment("WORLD_DIR")!="" else "res://test-results/world/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	root.size=Vector2i(844,390)
	main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory="user://world-capture/"+str(Time.get_ticks_usec())
	root.add_child(main)
	main.game.adopt("Foxy")
	main.show_world()
	await settle()
	var data=GameState.world_data()
	for id in ["hidden_cave"]:
		var room=data.rooms[id]
		for spawn in room.spawns:
			main.active_world.enter(id,spawn)
			await settle(30)
			printt("CAP",drawn,id,spawn,paused,main.active_world.room_id,main.active_world.player.position,main.orientation_blocked,get_root().get_window().size)
			root.get_texture().get_image().save_png(out+"%s-%s.png"%[id,spawn])
	# A wider look along Meadow Fields.
	main.active_world.enter("meadow_fields","home")
	for x in [500,900,1300]:
		main.active_world.player.reset_to(Vector2(x,288 if x!=900 else 270))
		main.active_world.camera.snap_to_target()
		await settle(12)
		root.get_texture().get_image().save_png(out+"fields-%d.png"%x)
	main.free()
	await process_frame
	print("PETOPIA WORLD CAPTURES done")
	quit()
