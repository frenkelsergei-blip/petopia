extends SceneTree
## Visit every public screen at the largest supported displays. With --probe,
## each source image is replaced by a coordinate-coded pattern so
## tools/measure_texture_scale.py can measure screen pixels per source texel.
## Usage: godot --path . --script res://tools/capture_texture_scale.gd -- OUTPUT_DIR [--probe PROBE_DIR]
const SIZES=[["desktop-4k",Vector2i(3840,2160)],["phone-portrait",Vector2i(1290,2796)],["phone-landscape",Vector2i(2796,1290)],["tablet-portrait",Vector2i(2048,2732)]]
var main: Control
var output=""
var shots=0
func _initialize() -> void: call_deferred("run")
func settle(n=6) -> void:
	for i in range(n): await physics_frame
	await RenderingServer.frame_post_draw
func snap(label: String) -> void:
	await settle()
	root.get_texture().get_image().save_png(output.path_join(label+".png"))
	shots+=1
func walk(prefix: String, level: Node) -> void:
	for x in [300,900,1500,2100,2700]:
		level.player.reset_to(Vector2(x,288))
		level.companion.position=Vector2(x-40,288)
		level.camera.snap_to_target()
		await snap(prefix+"-"+str(x))
func run() -> void:
	var args=OS.get_cmdline_user_args()
	output=args[0]
	DirAccess.make_dir_recursive_absolute(output)
	if "--probe" in args:
		var folder=args[args.find("--probe")+1]
		var plan=JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("probes.json")))
		for path in plan:
			var image=Image.load_from_file(folder.path_join(plan[path]))
			ArtTexture.overrides[path]=ImageTexture.create_from_image(image)
	main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory="user://texture-scale/"+str(Time.get_ticks_usec())
	root.add_child(main)
	for entry in SIZES:
		var size_name: String=entry[0]
		root.size=entry[1]
		main.show_menu()
		await snap(size_name+"-menu")
		main.main_menu.toggle_settings()
		await snap(size_name+"-settings")
		main.main_menu.toggle_settings()
		main.show_adoption()
		await snap(size_name+"-adoption")
		if main.game.state.is_empty(): main.game.adopt("Foxy")
		main.show_home()
		await snap(size_name+"-home")
		main.care_ui.toggle_overlay("care")
		await snap(size_name+"-care")
		main.care_ui.toggle_overlay("menu")
		await snap(size_name+"-home-menu")
		main.show_home()
		for care in ["water","feed","clean","sleep"]:
			main.home.request_care(care)
			for tick in range(360):
				if main.home.action_phase=="acting": break
				await physics_frame
			await settle(30)
			await snap(size_name+"-care-"+care)
			main.show_home()
		for screen in ["details","map","shop","collection","decorate","minigames","progress"]:
			main.call("show_"+screen)
			await snap(size_name+"-"+screen)
		main.show_home()
		main.toggle_pause()
		await snap(size_name+"-pause")
		main.toggle_pause()
		main.show_adventure()
		await walk(size_name+"-picnic",main.active_adventure)
		main.toggle_bag()
		await snap(size_name+"-bag")
		main.toggle_bag()
		main.active_adventure.run.basket=true
		main.active_adventure.player.reset_to(Vector2(220,288))
		main.active_adventure.interact()
		await snap(size_name+"-result")
		main.show_adventure("W01_L02")
		await walk(size_name+"-windmill",main.active_adventure)
		main.show_lab()
		await walk(size_name+"-lab",main.active_lab)
		main.show_ball()
		await snap(size_name+"-fetch")
	main.free()
	await process_frame
	print("PETOPIA TEXTURE SCALE CAPTURES: ",shots)
	quit()
