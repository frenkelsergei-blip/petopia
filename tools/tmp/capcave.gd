extends SceneTree
func _initialize(): call_deferred("run")
func run():
	root.size=Vector2i(844,390)
	var main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory="user://cc/"+str(Time.get_ticks_usec())
	root.add_child(main)
	main.game.adopt("Foxy")
	main.show_world()
	for i in 10: await physics_frame
	main.active_world.enter("hidden_cave","door")
	var k=0
	for x in [200,700,1150,1700]:
		main.active_world.player.reset_to(Vector2(x,150))
		for i in 60: await physics_frame
		main.active_world.camera.snap_to_target()
		for i in 10: await process_frame
		await RenderingServer.frame_post_draw
		print("x ",x," -> ",main.active_world.player.position," floor ",main.active_world.player.is_on_floor())
		root.get_texture().get_image().save_png(OS.get_environment("OUT")+"cv%d.png"%k);k+=1
	quit()
