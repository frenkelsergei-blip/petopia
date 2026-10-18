extends SceneTree

var checks=0
var failures: Array[String]=[]

func _initialize() -> void: call_deferred("run")

func check(value: bool, text: String) -> void:
	checks+=1
	if not value:
		failures.append(text)
		push_error(text)

func frames(count: int) -> void:
	for i in range(count): await physics_frame

func run() -> void:
	var main=load("res://scenes/main/main.tscn").instantiate()
	main.save_directory="user://scene-tests/"+str(Time.get_ticks_usec())
	root.add_child(main)
	await frames(2)
	check(main.screen=="menu" and main.game.state.is_empty(),"Boot into main menu without forcing adoption")
	main.show_lab()
	await frames(3)
	check(main.screen=="lab" and is_instance_valid(main.active_lab.player),"Reward-free movement lab starts without a save")
	main.show_hub()
	check(main.game.adopt("Test Fox"),"Adopt in isolated scene profile")
	main.show_home()
	await frames(2)
	check(main.care_ui.meters.is_empty() and main.care_ui.care_button!=null,"Quiet home moves detailed needs into the menu")
	var home_coin=main.coin_label.get_parent().get_node("CoinIcon").texture
	check(home_coin.resource_path==PetUI.COIN_PATH,"Home uses the canonical coin asset")
	var coin_icon: Control=main.coin_label.get_parent().get_node("CoinIcon")
	check(coin_icon.size.x<=48 and coin_icon.get_parent().get_parent().get_global_rect().encloses(coin_icon.get_global_rect()),"Coin icon stays within its badge instead of expanding to source resolution")
	main.show_details()
	await frames(2)
	check(main.care_ui.meters.size()==6 and main.care_ui.meters.fullness.size.y<=28,"Details retains five live need meters without crowding the room")
	main.show_map()
	main.show_adventure()
	await frames(3)
	var adventure=main.active_adventure
	check(main.coin_label.get_parent().get_node("CoinIcon").texture==home_coin and adventure.meadow.coin_texture==home_coin,"Adventure HUD and world pickups reuse the same coin resource as home")
	var start=adventure.player.position.x
	Input.action_press("move_right")
	await frames(30)
	Input.action_release("move_right")
	check(adventure.player.position.x>start+30,"Player moves under physics input")
	Input.action_press("jump")
	await frames(4)
	check(adventure.player.position.y<280,"Buffered jump leaves ground")
	Input.action_release("jump")
	await frames(35)
	adventure.player.position=Vector2(845,288)
	adventure.interact()
	await frames(2)
	check(adventure.run.bridge and is_instance_valid(adventure.bridge_body),"Crank creates traversable bridge")
	adventure.player.position=Vector2(1145,288)
	await frames(3)
	check(adventure.run.checkpoint==1,"Checkpoint recorded")
	adventure.player.position=Vector2(950,450)
	await frames(3)
	check(adventure.hearts==2 and adventure.player.position.y<320,"Fall recovers at checkpoint")
	adventure.companion.position=Vector2(-600,500)
	await frames(3)
	check(adventure.companion.recovery_count>0 and adventure.companion.position.y<320,"Companion recovers to a safe anchor")
	adventure.player.position=Vector2(1915,288)
	adventure.ability()
	check(adventure.run.secret and adventure.meadow.secret,"Foxy reveals real secret state")
	adventure.player.position=Vector2(3043,288)
	adventure.interact()
	check(adventure.run.basket,"Basket pickup recorded")
	adventure.interact()
	check(adventure.player.position.x<240,"Return gate shortcut works")
	adventure.interact()
	check(adventure.done and "W01_L01" in main.game.state.completed_levels,"Picnic completes and persists")
	var result_panel=main.ui.get_node("AdventureResult")
	var result_labels=result_panel.find_children("*","Label",true,false)
	check(result_labels.any(func(label):return label.text=="A picnic, together!"),"A successful mission presents an explicit completion screen")
	check(result_labels.any(func(label):return "Basket returned" in label.text) and result_labels.any(func(label):return "Berry bowl" in label.text),"Result explains story resolution and the food reward")
	check(result_panel.find_children("CoinIcon","TextureRect",true,false)[0].texture.resource_path==PetUI.COIN_PATH,"Result uses the same canonical coin as the world and wallet")
	check(result_panel.find_children("CoinIcon","TextureRect",true,false).all(func(coin): return coin.size.x<=48 and coin.size.y<=48),"Result coin obeys its UI size instead of expanding to source image dimensions")
	main.show_home()
	main.show_shop()
	main.show_decorate()
	main.show_progress()
	check(main.screen=="progress","Progress screen loads")
	main.show_ball()
	await frames(3)
	var activity=main.active_ball
	var phase=activity.phase
	main.toggle_pause()
	await frames(5)
	check(activity.phase==phase,"Pause freezes minigame timing")
	main.toggle_pause()
	activity.aim_time=activity.aim_time_for_catch()
	activity.throw_ball()
	await frames(112)
	check(not activity.practice and activity.throws==0,"Practice is distinct from scored throws")
	for i in range(10):
		for tick in range(300):
			if not activity.waiting: break
			await physics_frame
		activity.aim_time=activity.aim_time_for_catch()
		activity.throw_ball()
		await frames(112)
	check(activity.done and activity.catches==10,"Ten child throws complete with automatic pet catches")
	check(activity.session in main.game.state.claimed_event_ids,"Activity result persisted once")
	main.show_home()
	main.free()
	await frames(2)
	var f=FileAccess.open("res://test-results/scenes.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"checks":checks,"failures":failures,"scope":"Automated scene/input smoke tests; not a manual full playthrough or actual touch-device test."},"\t"))
	f.close()
	print("PETOPIA SCENE TESTS: ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
