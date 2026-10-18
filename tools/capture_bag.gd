extends SceneTree
## Captures the world bag (landscape phone and portrait) with some items.
## Output: BAG_DIR (default res://test-results/bag/).
var main: Control
func _initialize() -> void: call_deferred("run")
func settle(n=20) -> void:
	for i in range(n): await process_frame
	await RenderingServer.frame_post_draw
func run() -> void:
	var out=OS.get_environment("BAG_DIR") if OS.get_environment("BAG_DIR")!="" else "res://test-results/bag/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	root.size=Vector2i(844,390)
	main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory="user://bag-capture/"+str(Time.get_ticks_usec())
	root.add_child(main)
	main.game.adopt("Foxy")
	var inv: Dictionary=main.game.state.get("inventory",{})
	for id in GameState.foods().order: inv[id]=2
	main.game.state.inventory=inv
	main.show_world()
	await settle()
	main.toggle_bag()
	await settle()
	root.get_texture().get_image().save_png(out+"bag-landscape.png")
	main.toggle_bag()
	root.size=Vector2i(390,844)
	await settle()
	main.toggle_bag()
	await settle()
	root.get_texture().get_image().save_png(out+"bag-portrait.png")
	main.free()
	await process_frame
	quit()
