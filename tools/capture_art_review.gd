extends SceneTree
## Capture the reported areas in the actual game, without desktop capture or HUD cover.
var main: Control
func _initialize() -> void: call_deferred("run")
func settle(count=6) -> void:
	for i in range(count): await physics_frame
	await RenderingServer.frame_post_draw
func world_shot(name_value: String) -> void:
	await settle()
	main.viewport.get_texture().get_image().save_png("res://docs/screenshots/review-"+name_value+".png")
func run() -> void:
	root.size=Vector2i(1280,720)
	root.content_scale_size=Vector2i(1280,720)
	ArtStyle.enabled=true
	main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory="user://art-review/"+str(Time.get_ticks_usec())
	root.add_child(main)
	main.game.adopt("Foxy")
	main.show_lab()
	main.active_lab.player.reset_to(Vector2(650,288))
	main.active_lab.companion.position=Vector2(605,288)
	main.active_lab.camera.snap_to_target()
	await world_shot("bank-and-gap")
	main.active_lab.player.reset_to(Vector2(1400,272))
	main.active_lab.companion.position=Vector2(1360,272)
	main.active_lab.camera.snap_to_target()
	await world_shot("joined-steps")
	main.active_lab.player.reset_to(Vector2(1670,288))
	main.active_lab.interact()
	main.active_lab.player.reset_to(Vector2(1800,288))
	main.active_lab.companion.position=Vector2(1760,288)
	main.active_lab.camera.snap_to_target()
	await world_shot("wooden-bridge")
	main.show_adventure("W01_L02")
	main.game.collect_trail_crates()
	main.active_adventure.player.reset_to(Vector2(1578,288))
	for point in [Vector2(1544,260),Vector2(1512,260),Vector2(1512,236)]: main.game.place_trail_crate_at("W01_L02",point)
	main.active_adventure.player.reset_to(Vector2(1512,224))
	main.active_adventure.companion.position=Vector2(1570,272)
	main.active_adventure.camera.snap_to_target()
	await world_shot("crate-steps")
	main.show_adventure()
	main.active_adventure.player.reset_to(Vector2(500,288))
	await settle(8)
	Input.action_press("jump")
	await settle(15)
	Input.action_release("jump")
	main.viewport.get_texture().get_image().save_png("res://docs/screenshots/review-airborne.png")
	main.show_lab()
	main.active_lab.player.reset_to(Vector2(500,288))
	main.active_lab.companion.position=Vector2(460,288)
	await settle(8)
	Input.action_press("move_right")
	DirAccess.make_dir_recursive_absolute("res://test-results/walk-frames")
	for index in range(24):
		await settle(2)
		main.viewport.get_texture().get_image().save_png("res://test-results/walk-frames/%03d.png"%index)
	Input.action_release("move_right")
	main.show_ball()
	await world_shot("home-garden")
	main.toast_time=0
	root.size=Vector2i(390,844)
	await settle(12)
	root.get_texture().get_image().save_png("res://docs/screenshots/review-garden-portrait.png")
	main.free()
	await process_frame
	print("PETOPIA ART REVIEW: seven actual game captures")
	quit()
