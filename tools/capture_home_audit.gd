extends SceneTree
func _initialize() -> void: call_deferred("run")
func frames(n=12) -> void:
	for i in range(n): await physics_frame
	await RenderingServer.frame_post_draw
func run() -> void:
	var main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory="user://home-audit/"+str(Time.get_ticks_usec())
	root.add_child(main)
	main.game.adopt("Foxy")
	var entries=[[Vector2i(360,640),"01-short-phone"],[Vector2i(844,390),"02-landscape-phone"],[Vector2i(1280,720),"03-desktop"]]
	for entry in entries:
		root.size=entry[0]
		main.show_home()
		await frames()
		root.get_texture().get_image().save_png("res://docs/feedback/2026-10-16-home-crowding/"+entry[1]+".png")
	main.show_details()
	await frames()
	root.get_texture().get_image().save_png("res://docs/feedback/2026-10-16-home-crowding/04-details-blur.png")
	main.free()
	await frames()
	print("PETOPIA HOME AUDIT: four actual native frames, isolated profile; no art approval")
	quit()
