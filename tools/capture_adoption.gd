extends SceneTree
var main: Control
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for i in range(15): await physics_frame
	await RenderingServer.frame_post_draw
func capture(label: String) -> void:
	await settle()
	root.get_texture().get_image().save_png("res://docs/screenshots/"+label+".png")
func run() -> void:
	root.size=Vector2i(1280,720)
	main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory="user://adoption-capture/"+str(Time.get_ticks_usec())
	root.add_child(main)
	await settle()
	main.continue_game()
	await capture("adoption-desktop")
	for entry in [["portrait",Vector2i(390,844)],["short-phone",Vector2i(360,640)],["tablet",Vector2i(768,1024)]]:
		root.size=entry[1]
		await capture("adoption-"+entry[0])
	root.size=Vector2i(390,844)
	main.portrait_ui.safe_override=Vector4(16,32,16,28)
	await capture("adoption-notch")
	main.adoption_screen.toggle_settings()
	await capture("adoption-settings")
	main.adoption_screen.toggle_settings()
	main.game.adopt("Foxy")
	main.show_home()
	main.portrait_ui.safe_override=Vector4(-1,-1,-1,-1)
	await capture("home-bed-portrait")
	root.size=Vector2i(1280,720)
	await capture("home-bed-desktop")
	root.size=Vector2i(390,844)
	main.game.care("sleep")
	# Record the actual care feedback without hiding it for the fixture.
	await capture("home-sleep-feedback-portrait")
	for i in range(480): await physics_frame
	await capture("home-sleep-portrait")
	root.size=Vector2i(1280,720)
	await capture("home-sleep-desktop")
	main.free()
	await process_frame
	print("PETOPIA ADOPTION CAPTURES: six adoption views and five home/bed views; isolated save")
	quit()
