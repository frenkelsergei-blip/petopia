extends SceneTree
## Full screen audit: every screen the player can reach, at phone portrait,
## phone landscape and tablet sizes. Output: $AUDIT_DIR (default test-results/audit/).
var main: Control
var out="res://test-results/audit/"
func _initialize() -> void: call_deferred("run")
func settle(n=14) -> void:
	for i in range(n): await physics_frame
	var drawn=[false]
	RenderingServer.frame_post_draw.connect(func(): drawn[0]=true,CONNECT_ONE_SHOT)
	var waited=0.0
	while not drawn[0] and waited<5.0:
		await create_timer(0.05).timeout
		waited+=0.05
func snap(label: String) -> void:
	await settle()
	root.get_texture().get_image().save_png(out+label+".png")
	print("snap ",label)
func close_native() -> void:
	if is_instance_valid(main.native_screen) and main.native_screen!=main.care_ui and main.native_screen.get_parent()==main.ui: main.native_screen.queue_free()
	paused=false
	await process_frame
func run() -> void:
	if OS.get_environment("AUDIT_DIR")!="": out=OS.get_environment("AUDIT_DIR")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var sizes=[Vector2i(390,844),Vector2i(844,390),Vector2i(1180,820)]
	if OS.get_environment("SIZE")!="":
		var p=OS.get_environment("SIZE").split("x")
		sizes=[Vector2i(int(p[0]),int(p[1]))]
	# The Adventures page stops this headed capture from drawing, so it runs
	# alone (MAP_ONLY=1, one size per process).
	var map_only=OS.get_environment("MAP_ONLY")!=""
	for size in sizes:
		root.size=size
		var tag="-%dx%d"%[size.x,size.y]
		main=load("res://scenes/main/main.tscn").instantiate()
		main.automation_mode=true
		main.save_directory="user://audit/"+str(Time.get_ticks_usec())
		root.add_child(main)
		await settle()
		if map_only:
			main.game.adopt("Foxy")
			main.show_map()
			await snap("13-adventures"+tag)
			break
		await snap("01-main-menu"+tag)
		main.show_home()
		await snap("02-adopt"+tag)
		main.game.adopt("Foxy")
		var st=main.game.state.duplicate(true)
		st.coins=128
		for f in ["apple","fish_treat","carrot","berry_bowl","honey_cookie"]: st.inventory[f]=2
		st.inventory["ball_sun"]=1
		main.game.commit(st)
		main.show_home()
		await snap("03-my-pet"+tag)
		main.care_ui.toggle_overlay("care")
		await snap("04-care"+tag)
		main.care_ui.choose_care("feed")
		await snap("05-feed"+tag)
		main.care_ui.close_overlay()
		main.care_ui.toggle_overlay("menu")
		await snap("06-pet-menu"+tag)
		main.care_ui.close_overlay()
		main.show_details()
		await snap("07-details"+tag)
		main.show_shop()
		await snap("08-shop"+tag)
		main.show_decorate()
		await snap("09-decorate"+tag)
		main.home.toy_preview=0
		main.care_ui.signature="";main.care_ui.layout(main.care_ui.logical_size,main.care_ui.safe)
		await snap("10-decorate-pick"+tag)
		main.home.toy_preview=-1
		main.home.decorating=false
		main.show_minigames()
		await snap("11-games"+tag)
		main.show_collection()
		await snap("12-collection"+tag)
		main.show_home()
		main.show_settings()
		await snap("14-settings"+tag)
		await close_native()
		main.show_ball()
		await settle(40)
		await snap("15-ball"+tag)
		var b=main.active_ball
		if is_instance_valid(b):
			b.aim_time=b.aim_time_for_catch()
			b.throw_ball()
			await settle(20)
			await snap("16-ball-throw"+tag)
			b.in_flight=false;b.windup=0;b.waiting=true;b.bringing_back=true
			b.foxy.position.x=b.child.position.x+160
			await settle(10)
			await snap("17-ball-return"+tag)
		main.result("Lovely time together","3 catches in 4 throws",main.show_ball)
		await snap("18-ball-result"+tag)
		await close_native()
		main.game.state.quest_state["last_completion"]={"run_id":"x","level_id":"W01_L01","base_coins":50,"pickup_coins":5,"discovery_coins":2,"total_coins":57,"meals":1,"bond":15,"keepsake":"picnic_sticker","new_keepsake":true,"wallet_after":185}
		main.show_adventure_result("W01_L01")
		await snap("19-adventure-result"+tag)
		await close_native()
		main.show_world()
		await settle(30)
		await snap("20-level-hud"+tag)
		main.toggle_world_map()
		await snap("21-level-map"+tag)
		main.toggle_world_map()
		main.toggle_bag()
		await snap("22-bag"+tag)
		main.toggle_bag()
		main.toggle_pause()
		await snap("23-pause"+tag)
		main.toggle_pause()
		if is_instance_valid(main.adventure_ui):
			main.adventure_ui.show_card("Foxy learned Dig","Dig at soft ground to find treasures.")
			await snap("24-notice"+tag)
			main.adventure_ui.show_complete()
			await snap("25-world-complete"+tag)
		paused=false
		main.free()
		await process_frame
	print("PETOPIA AUDIT CAPTURES done")
	quit()
