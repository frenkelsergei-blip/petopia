extends SceneTree
func _initialize() -> void: call_deferred("run")
func frames(n=12) -> void:
	for i in range(n): await physics_frame
	await RenderingServer.frame_post_draw
func snap(label: String) -> void:
	await frames()
	root.get_texture().get_image().save_png("res://docs/screenshots/home-flow-"+label+".png")
func run() -> void:
	var main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory="user://home-flow-capture/"+str(Time.get_ticks_usec())
	root.add_child(main)
	main.game.adopt("Foxy")
	for entry in [[Vector2i(390,844),"portrait"],[Vector2i(844,390),"landscape"],[Vector2i(360,640),"short-phone"],[Vector2i(768,1024),"tablet"],[Vector2i(1280,720),"desktop"]]:
		root.size=entry[0]
		main.show_home()
		await snap(entry[1]+"-quiet")
		main.care_ui.toggle_overlay("care")
		await snap(entry[1]+"-care")
		main.care_ui.toggle_overlay("menu")
		await snap(entry[1]+"-menu")
	root.size=Vector2i(390,844)
	main.show_home()
	await frames()
	main.home.request_care("water")
	for tick in range(300):
		if main.home.action_phase=="acting": break
		await physics_frame
	await frames(50)
	await snap("portrait-drinking")
	main.free()
	quit()
