extends SceneTree
## A60: tour of the layered Meadow Fields (P71a): the camera at each floor.
## Output: test-results/tour/<n>.png
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(1180,820) if OS.get_environment("SIZE")=="" else Vector2i(int(OS.get_environment("SIZE").split("x")[0]),int(OS.get_environment("SIZE").split("x")[1]))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-results/tour/"))
	var main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory="user://tour/"+str(Time.get_ticks_usec())
	root.add_child(main)
	for i in 10: await physics_frame
	main.game.adopt("Foxy")
	main.show_world()
	for i in 20: await physics_frame
	var w=main.active_world
	var spots=OS.get_environment("SPOTS").split(";") if OS.get_environment("SPOTS")!="" else PackedStringArray(["300,608","1000,608","1100,770","1432,608","1600,470","1800,330","2100,470","2090,262","2140,608","2600,608"])
	var k=0
	for sp in spots:
		var v=sp.split(",")
		if sp.contains(":"):
			var rid=sp.split(":")[0]
			v=sp.split(":")[1].split(",")
			if w.room_id!=rid:
				w.enter(rid,GameState.world_data().rooms[rid].spawns.keys()[0])
				for i in 20: await physics_frame
		w.player.reset_to(Vector2(float(v[0]),float(v[1])-2))
		w.companion.position=w.player.position-Vector2(30,0)
		w.companion.reset_physics_interpolation()
		for i in 50: await physics_frame
		main.ui.visible=false
		for n in main.find_children("*","CanvasLayer",true,false): n.visible=false
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-results/tour/%02d.png"%k)
		print("tour ",k," ",sp," floor=",w.player.is_on_floor()," at ",w.player.position)
		main.ui.visible=true
		k+=1
	quit()
