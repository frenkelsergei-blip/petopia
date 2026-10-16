extends SceneTree
## Render this project's own scenes to review images; never reads the desktop.
var prefix="graybox"
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
func snapshot(name_value: String) -> void:
	await settle()
	var screenshot=root.get_texture().get_image()
	var result=screenshot.save_png("res://docs/screenshots/"+name_value.replace("graybox",prefix)+".png")
	if result!=OK:
		push_error("Could not render graybox screenshot: "+name_value)
		quit(1)
func run() -> void:
	var args=OS.get_cmdline_user_args()
	if not args.is_empty(): prefix=args[0]
	ArtStyle.enabled=prefix!="graybox"
	root.size=Vector2i(1280,720)
	root.content_scale_size=Vector2i(1280,720)
	var main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory="user://capture-profiles/"+str(Time.get_ticks_usec())
	root.add_child(main)
	main.show_hub()
	await snapshot("graybox-hub")
	main.show_lab()
	await settle()
	await snapshot("graybox-lab")
	main.game.adopt("Foxy")
	main.show_home()
	await snapshot("graybox-home")
	main.show_adventure()
	main.active_adventure.player.reset_to(Vector2(845,288))
	main.active_adventure.companion.position=Vector2(800,288)
	await snapshot("graybox-picnic")
	main.show_ball()
	await settle()
	main.active_ball.aim_time=PI/(2*1.7)
	main.active_ball.set_process(false)
	await snapshot("graybox-ball")
	main.active_ball.set_process(true)
	main.active_ball.throw_ball()
	for tick in range(50): await physics_frame
	main.active_ball.set_process(false)
	await snapshot("graybox-ball-fetch")
	main.show_adventure("W01_L02")
	main.active_adventure.player.reset_to(Vector2(950,240))
	main.active_adventure.companion.position=Vector2(908,240)
	main.active_adventure.interact()
	await snapshot("graybox-windmill")
	main.active_adventure.player.reset_to(Vector2(2130,288))
	main.active_adventure.companion.position=Vector2(2180,288)
	main.active_adventure.ability()
	await snapshot("graybox-pet-help")
	# Isolated visual fixture for owned-object preview; never touches the user's profile.
	var fixture=main.game.state.duplicate(true)
	fixture.inventory.ball_sun=1
	main.game.commit(fixture)
	main.show_decorate()
	main.home.toy_preview=1
	await snapshot("graybox-decoration")
	main.show_adventure("W01_L02")
	main.game.collect_trail_crates()
	main.active_adventure.player.reset_to(Vector2(1578,288))
	main.game.place_trail_crate_at("W01_L02",Vector2(1544,260))
	main.game.place_trail_crate_at("W01_L02",Vector2(1512,260))
	main.game.place_trail_crate_at("W01_L02",Vector2(1512,236))
	main.active_adventure.player.reset_to(Vector2(1512,224))
	main.active_adventure.companion.position=Vector2(1570,272)
	await snapshot("graybox-crate-steps")
	main.toggle_bag()
	await snapshot("graybox-adventure-bag")
	main.free()
	await process_frame
	print("PETOPIA: rendered eleven runtime screenshots from the project.")
	quit()
