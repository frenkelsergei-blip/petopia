extends SceneTree
## Feet check: the explorer standing on each kind of ground (main strip,
## ledges, raised ground) in every room, cropped around the boots.
## Output: test-results/feet/.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(1180,820)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-results/feet/"))
	var main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory="user://feet/"+str(Time.get_ticks_usec())
	root.add_child(main)
	for i in 10: await physics_frame
	main.game.adopt("Foxy")
	main.show_world()
	for i in 20: await physics_frame
	var data=GameState.world_data()
	var shots=[]
	for rid in data.rooms:
		var g: Array=data.rooms[rid].ground
		for i in mini(g.size(),6):
			var r: Array=g[i]
			if float(r[2])<60: continue
			shots.append([rid,i,Vector2(float(r[0])+minf(float(r[2])*0.5,90.0),float(r[1]))])
	var w=main.active_world
	for s in shots:
		if w.room_id!=s[0]:
			w.enter(s[0],"")
			for i in 15: await physics_frame
		var p=w.player
		p.global_position=s[2]-Vector2(0,2)
		p.velocity=Vector2.ZERO
		for i in 30: await physics_frame
		main.ui.visible=false
		for n in main.find_children("*","CanvasLayer",true,false): n.visible=false
		if is_instance_valid(main.adventure_ui): main.adventure_ui.visible=false
		for i in 3: await process_frame
		await RenderingServer.frame_post_draw
		var img=root.get_texture().get_image()
		img.save_png("res://test-results/feet/%s_%d.png"%[s[0],s[1]])
		print("feet ",s[0]," ",s[1]," on_floor=",p.is_on_floor()," y=",p.global_position.y)
	quit()
