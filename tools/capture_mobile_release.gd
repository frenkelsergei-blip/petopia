extends SceneTree
var main: Control
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for i in range(20): await physics_frame
	await RenderingServer.frame_post_draw
func capture(label: String) -> void:
	await settle()
	root.get_texture().get_image().save_png("res://docs/screenshots/"+label+".png")
func run() -> void:
	root.size=Vector2i(390,844)
	main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory="user://release-capture/"+str(Time.get_ticks_usec())
	root.add_child(main)
	await capture("release-v0.1.0-menu-phone")
	main.game.adopt("Foxy")
	main.show_adventure()
	await capture("release-v0.1.0-controls-phone")
	root.size=Vector2i(1280,720)
	await capture("release-v0.1.0-controls-desktop")
	main.free()
	await process_frame
	print("PETOPIA RELEASE CAPTURES: native menu and controller at phone/desktop sizes; isolated profile")
	quit()
