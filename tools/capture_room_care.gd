extends SceneTree
## A56 paper room: captures each care step at a few moments (landscape and
## portrait). Output: ROOM_DIR (default res://test-results/room/).
var main: Control
func _initialize() -> void: call_deferred("run")
func wait(seconds: float) -> void:
	await create_timer(seconds).timeout
	await RenderingServer.frame_post_draw
func shot(name: String) -> void:
	root.get_texture().get_image().save_png(OS.get_environment("ROOM_DIR")+name+".png")
func run() -> void:
	if OS.get_environment("ROOM_DIR")=="": OS.set_environment("ROOM_DIR","res://test-results/room/")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OS.get_environment("ROOM_DIR")))
	root.size=Vector2i(1280,720)
	main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory="user://room-capture/"+str(Time.get_ticks_usec())
	root.add_child(main)
	main.game.adopt("Foxy")
	main.game.pet().needs.fullness=20.0
	main.show_home()
	await wait(1.5)
	shot("idle")
	var art: HomeArt=main.home
	for step in [["feed",[1.6,0.9,3.0]],["water",[1.6,0.9,2.6]],["clean",[1.6,0.8,1.6,3.6]],["pet",[1.6,1.2]],["sleep",[1.6,1.0]]]:
		art.request_care(step[0])
		var k=0
		for d in step[1]:
			await wait(d)
			shot("%s-%d"%[step[0],k])
			k+=1
		await wait(3.0)
	root.size=Vector2i(390,844)
	await wait(1.0)
	shot("portrait-sleep")
	main.free()
	await process_frame
	quit()
