extends SceneTree
func _initialize() -> void: call_deferred("run")
func settle(n=2) -> void:
	for i in range(n): await physics_frame
	await RenderingServer.frame_post_draw
func run() -> void:
	root.size=Vector2i(390,844)
	var main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory="user://menu-motion/"+str(Time.get_ticks_usec())
	root.add_child(main)
	main.game.adopt("Foxy")
	main.show_menu()
	await settle(15)
	var menu=main.main_menu
	menu.friends.elapsed=0
	var before=menu.actions[1].get_global_rect()
	var shadow=menu.contact_shadow.get_global_rect()
	var stable=true
	var poses=[]
	DirAccess.make_dir_recursive_absolute("res://test-results/menu-motion")
	for i in range(120):
		if i in [20,65]:
			var move=InputEventMouseMotion.new()
			move.position=menu.actions[1].get_global_rect().get_center() if i==20 else Vector2(2,2)
			root.push_input(move,true)
		await settle()
		if not menu.friends.frame_index in poses: poses.append(menu.friends.frame_index)
		stable=stable and before==menu.actions[1].get_global_rect() and shadow==menu.contact_shadow.get_global_rect()
		var frame=root.get_texture().get_image()
		frame.save_png("res://test-results/menu-motion/%03d.png"%i)
		if i==48: frame.save_png("res://docs/screenshots/menu-motion-still.png")
	main.game.set_preference("reduced_motion",true)
	await settle(4)
	var stopped=menu.friends.elapsed
	await settle(15)
	var reduced=menu.friends.frame_index==0 and menu.friends.elapsed==stopped
	root.get_texture().get_image().save_png("res://docs/screenshots/menu-reduced-motion.png")
	var file=FileAccess.open("res://test-results/menu-motion.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"frames":120,"fps":30,"simulation_hz":60,"window":[390,844],"poses_seen":poses,"hitboxes_and_ground_shadow_stable":stable,"reduced_motion_freezes":reduced,"scope":"Actual headed Godot render from an isolated returning profile. Includes hover feedback, four pose petting loop, fixed contact shadow and saved reduced-motion check. Desktop simulation, not physical-device or visual approval."},"\t"))
	file.close()
	main.free()
	await process_frame
	print("PETOPIA MENU MOTION:120 frames, poses ",poses,"; stable anchors ",stable,"; reduced ",reduced)
	quit(0 if stable and reduced and poses.size()==4 else 1)
