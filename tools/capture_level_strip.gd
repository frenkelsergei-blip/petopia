extends SceneTree
## Walks the camera across an adventure and saves one landscape frame per stop,
## for reviewing the whole level's art at actual camera scale.
## Env: LEVEL (W01_L01), STRIP_DIR (res://test-results/level-strip/).
func _initialize() -> void: call_deferred("run")
func settle(n=14) -> void:
	for i in range(n): await physics_frame
	await RenderingServer.frame_post_draw
func run() -> void:
	var level=OS.get_environment("LEVEL") if OS.get_environment("LEVEL")!="" else "W01_L01"
	var out=OS.get_environment("STRIP_DIR") if OS.get_environment("STRIP_DIR")!="" else "res://test-results/level-strip/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	root.size=Vector2i(844,390)
	var main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory="user://level-strip/"+str(Time.get_ticks_usec())
	root.add_child(main)
	main.game.adopt("Foxy")
	main.show_adventure(level)
	await settle()
	var adventure=main.active_adventure
	var width: float=adventure.LAYOUT.world_width
	var i=0
	for x in range(160,int(width),420):
		var anchor=Vector2(x,288)
		for a in adventure.LAYOUT.safe_anchors:
			if absf(a.x-x)<absf(anchor.x-x) or anchor==Vector2(x,288): anchor=a
		adventure.player.reset_to(Vector2(x,anchor.y))
		adventure.companion.position=Vector2(x-40,anchor.y)
		adventure.camera.snap_to_target()
		await settle()
		root.get_texture().get_image().save_png(out+"%02d.png"%i)
		i+=1
	main.free()
	await process_frame
	print("PETOPIA LEVEL STRIP: %d frames of %s"%[i,level])
	quit()
