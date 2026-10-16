extends SceneTree
var main: Control
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for i in range(12): await physics_frame
	await RenderingServer.frame_post_draw
func capture(label: String) -> void:
	await settle()
	root.get_texture().get_image().save_png("res://docs/screenshots/menu-"+label+".png")
func run() -> void:
	root.size=Vector2i(1280,720)
	main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory="user://menu-capture/"+str(Time.get_ticks_usec())
	root.add_child(main)
	await capture("desktop")
	root.size=Vector2i(390,844)
	await capture("portrait")
	root.size=Vector2i(360,640)
	await capture("short-phone")
	root.size=Vector2i(768,1024)
	await capture("tablet")
	root.size=Vector2i(390,844)
	main.portrait_ui.safe_override=Vector4(16,32,16,28)
	await capture("notch")
	root.size=Vector2i(360,640)
	main.portrait_ui.safe_override=Vector4(-1,-1,-1,-1)
	await settle()
	main.main_menu.toggle_settings()
	await capture("settings")
	main.main_menu.toggle_settings()
	main.game.adopt("Foxy")
	main.show_adventure("W01_L02")
	await settle()
	main.show_menu()
	root.size=Vector2i(1280,720)
	await capture("continue")
	main.free()
	await process_frame
	print("PETOPIA MENU CAPTURES: seven actual native menu frames; isolated save")
	quit()
