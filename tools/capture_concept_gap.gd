extends SceneTree
## Captures every player screen at phone portrait, phone landscape, tablet and
## desktop sizes for side-by-side comparison with the concept library.
## Output: docs/feedback/2026-10-18-concept-gap/<screen>-<size>.png (or $GAP_DIR).
var main: Control
var out="res://test-results/concept-gap/"
const SIZES=[[Vector2i(390,844),"phone"],[Vector2i(844,390),"landscape"],[Vector2i(768,1024),"tablet"],[Vector2i(1280,720),"desktop"]]
func _initialize() -> void: call_deferred("run")
var drawn=false
func settle(n=16) -> void:
	for i in range(n): await physics_frame
	# macOS stops redrawing a hidden/covered window; never wait forever for it.
	drawn=false
	RenderingServer.frame_post_draw.connect(func(): drawn=true,CONNECT_ONE_SHOT)
	var waited=0.0
	while not drawn and waited<5.0:
		await create_timer(0.05).timeout
		waited+=0.05
	if not drawn: print("PETOPIA CAPTURE WARNING: window did not redraw within 5 s (hidden or covered?)")
func snap(label: String) -> void:
	print("snap ",label)
	await settle()
	root.get_texture().get_image().save_png(out+label+".png")
func fresh() -> void:
	if is_instance_valid(main):
		paused=false
		main.free()
		await process_frame
	main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory="user://concept-gap/"+str(Time.get_ticks_usec())
	root.add_child(main)
func run() -> void:
	if OS.get_environment("GAP_DIR")!="": out=OS.get_environment("GAP_DIR")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	for entry in SIZES:
		root.size=entry[0]
		var s: String=entry[1]
		await fresh()
		await snap("01-menu-"+s)
		main.show_home()
		await snap("02-adoption-"+s)
		main.game.adopt("Foxy")
		main.show_home()
		await snap("03-home-"+s)
		main.care_ui.toggle_overlay("care")
		await snap("04-care-"+s)
		main.show_map()
		await snap("05-map-"+s)
		main.show_home()
		main.care_ui.open("details")
		await snap("06-details-"+s)
		main.show_adventure("W01_L01")
		await snap("07-adventure-"+s)
		main.toggle_pause()
		await snap("08-pause-"+s)
		main.toggle_pause()
		var run=main.game.state.pending_run.duplicate(true)
		run.basket=true
		run.secret=true
		run.pickups=["c1","c2","c3","c4","c5","c6","c7"]
		main.game.finish_run(run)
		main.show_adventure_result("W01_L01")
		await snap("09-result-"+s)
	paused=false
	main.free()
	await process_frame
	print("PETOPIA CONCEPT GAP CAPTURES: 9 screens x 4 sizes")
	quit()
