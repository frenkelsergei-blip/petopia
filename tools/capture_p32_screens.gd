extends SceneTree
## A57: captures every P32 screen next to its concept for the self-audit
## (P40 HUD, P41 menu, P42 pause, P43 room, P44 bag, P45 shop, P46 map,
## P47 details). Output: $P32_DIR (default test-results/p32/).
var main: Control
var out="res://test-results/p32/"
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
func run() -> void:
	if OS.get_environment("P32_DIR")!="": out=OS.get_environment("P32_DIR")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var only=OS.get_environment("P32_ONLY")
	for size in [Vector2i(1280,720),Vector2i(844,390),Vector2i(390,844)]:
		root.size=size
		var tag="-%dx%d"%[size.x,size.y]
		main=load("res://scenes/main/main.tscn").instantiate()
		main.automation_mode=true
		main.save_directory="user://p32/"+str(Time.get_ticks_usec())
		root.add_child(main)
		await settle()
		if only=="" or "menu" in only: await snap("p41-menu"+tag)
		if only=="" or "adopt" in only:
			main.show_home()
			await snap("p48-adopt"+tag)
		main.game.adopt("Foxy")
		var st=main.game.state.duplicate(true)
		st.coins=128
		for f in ["apple","fish_treat","carrot","berry_bowl","honey_cookie"]: st.inventory[f]=2
		main.game.commit(st)
		if only=="" or "home" in only:
			main.show_home()
			await snap("p43-room"+tag)
			main.care_ui.toggle_overlay("care")
			await snap("p43-care"+tag)
			main.care_ui.choose_care("feed")
			await snap("p51-food"+tag)
			main.care_ui.close_overlay()
			main.care_ui.toggle_overlay("menu")
			await snap("p50-menu"+tag)
			main.care_ui.close_overlay()
		if only=="" or "details" in only:
			main.show_details()
			await snap("p47-details"+tag)
		if only=="" or "shop" in only:
			main.show_shop()
			await snap("p45-shop"+tag)
		if only=="" or "result" in only:
			main.game.state.quest_state["last_completion"]={"run_id":"x","level_id":"W01_L01","base_coins":50,"pickup_coins":5,"discovery_coins":2,"total_coins":57,"meals":1,"bond":15,"keepsake":"picnic_sticker","new_keepsake":true,"wallet_after":185}
			main.show_adventure_result("W01_L01")
			await snap("p49-result"+tag)
			paused=false
			main.show_home()
		if only=="" or "games" in only:
			main.show_minigames()
			await snap("p55-games"+tag)
		if only=="" or "collect" in only:
			main.show_collection()
			await snap("p54-collection"+tag)
		if only=="" or "map" in only:
			main.show_map()
			await snap("p46-map"+tag)
		if size.x<size.y and (only=="" or "turn" in only):
			main.show_ball()
			await settle(30)
			await snap("p53-turn"+tag)
			main.show_home()
		if size.x>size.y and (only=="" or "ball" in only):
			main.show_ball()
			await settle(40)
			await snap("p52-ball"+tag)
		if size.x>size.y:
			main.show_world()
			await settle(30)
			if only=="" or "hud" in only: await snap("p40-hud"+tag)
			if only=="" or "areamap" in only:
				main.toggle_world_map()
				await snap("p56-areamap"+tag)
				main.toggle_world_map()
			if only=="" or "bag" in only:
				main.toggle_bag()
				await snap("p44-bag"+tag)
				main.toggle_bag()
			if only=="" or "pause" in only:
				main.toggle_pause()
				await snap("p42-pause"+tag)
				main.toggle_pause()
		paused=false
		main.free()
		await process_frame
	print("PETOPIA P32 CAPTURES done")
	quit()
