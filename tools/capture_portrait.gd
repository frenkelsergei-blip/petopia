extends SceneTree
## Own-project renders at phone dimensions, isolated from the user's save.
var main: Control
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
func capture(name_value: String) -> void:
	await settle()
	root.get_texture().get_image().save_png("res://docs/screenshots/portrait-"+name_value+".png")
func run() -> void:
	root.size=Vector2i(390,844)
	main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory="user://portrait-captures/"+str(Time.get_ticks_usec())
	root.add_child(main)
	await capture("menu")
	main.show_home()
	await capture("adoption")
	main.game.adopt("Foxy")
	main.show_home()
	await capture("home")
	main.show_map()
	await capture("map")
	main.show_adventure("W01_L02")
	main.active_adventure.player.reset_to(Vector2(950,240))
	main.active_adventure.companion.position=Vector2(908,240)
	await capture("adventure")
	main.game.collect_trail_crates()
	main.toggle_bag()
	await capture("bag")
	main.toggle_bag()
	main.toggle_pause()
	await settle()
	main.portrait_ui.settings_open=true
	await capture("controls")
	main.portrait_ui.settings_open=false
	main.show_ball()
	await capture("fetch")
	main.show_shop()
	await capture("shop")
	main.show_adventure()
	root.size=Vector2i(360,640)
	await capture("small-phone")
	root.size=Vector2i(430,932)
	main.portrait_ui.safe_override=Vector4(16,32,16,28)
	await capture("safe-area")
	main.free()
	await process_frame
	print("PETOPIA: rendered eleven portrait runtime screens.")
	quit()
