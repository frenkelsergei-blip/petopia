extends SceneTree
var checks=0
var failures: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures.append(message);push_error(message)
func frames(n=8) -> void:
	for i in range(n): await physics_frame
func finish_care(home: Node) -> void:
	for i in range(480):
		if not home.busy(): return
		await physics_frame
func button(parent: Node, caption: String) -> Button:
	for b in parent.find_children("*","Button",true,false):
		if b.text==caption: return b
	return null
func click(b: Button) -> void:
	for pressed in [true,false]:
		var event=InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT
		event.position=b.get_global_rect().get_center()
		event.pressed=pressed
		root.push_input(event,true)
	await frames()
func run() -> void:
	root.size=Vector2i(1280,720)
	var main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory="user://care-tests/"+str(Time.get_ticks_usec())
	root.add_child(main)
	await frames()
	main.game.adopt("Foxy")
	var candidate=main.game.state.duplicate(true)
	candidate.coins=200
	candidate.inventory.berry_bowl=2
	for key in candidate.pets[0].needs: candidate.pets[0].needs[key]=30.0
	main.game.commit(candidate)
	main.show_home()
	await frames()
	var home=main.home
	check(main.native_screen==main.care_ui and main.care_ui.meters.is_empty() and main.care_ui.action_buttons.is_empty(),"Quiet home has no permanent care dashboard")
	await click(main.care_ui.care_button)
	check(main.care_ui.home_overlay=="care" and main.care_ui.action_buttons.size()==6,"Care entry opens the six-action drawer")
	var water_tile=main.care_ui.sheet.get_node("Water")
	check(water_tile.tooltip_text=="Drinking water in a bowl" and CareArt.icon("drink")!=CareArt.icon("clean"),"Drinking water has its own bowl, distinct from bathing")
	await click(water_tile)
	check(main.care_ui.home_overlay.is_empty() and home.action=="water" and main.world.transform==Transform2D.IDENTITY,"Water closes the drawer and restores the real room before serving")
	await finish_care(home)
	var before=main.game.pet().needs.fullness
	check(home.request_care("feed") and home.busy() and main.game.pet().needs.fullness==before,"Feeding starts with approach; no instant need award")
	check(not home.request_care("feed") and not home.request_care("clean"),"Busy care rejects overlapping and repeated commands")
	for tick in range(120):
		if home.action_phase=="acting": break
		await physics_frame
	await physics_frame
	check(home.action_phase=="acting" and home.explorer.visible and home.explorer.home_pose!=null and not home.pet_art.visible,"At meals the child kneels beside Foxy while the eating animation plays")
	await finish_care(home)
	check(not home.busy() and main.game.pet().needs.fullness>before+30 and home.action_finished,"Completed serving commits the real free meal")
	check(SaveStore.new(main.save_directory).load_state().pets[0].needs.fullness>before+30,"Care feedback follows a durable saved need change")
	for entry in [["clean","cleanliness"],["water","health"],["pet","happiness"]]:
		before=main.game.pet().needs[entry[1]]
		check(home.request_care(entry[0]),"Accept care command: "+entry[0])
		await finish_care(home)
		check(not home.busy() and main.game.pet().needs[entry[1]]>before+10,"Visible completed action improves its corresponding need: "+entry[0])
	var meals=main.game.state.inventory.berry_bowl
	home.request_care("meal")
	await frames(10)
	main.show_details()
	await frames()
	check(main.game.state.inventory.berry_bowl==meals and main.home==home and not home.busy(),"Opening a modal retains the room instance and cancels unfinished care without consuming inventory")
	check(main.care_ui.room_view is ModalBackdrop and main.care_ui.room_view.horizontal_view.get_child(0).texture==main.viewport.get_texture(),"Modal blur samples the actual game room; no concept-room background")
	check(main.care_ui.find_child("DetailsPanel",true,false)!=null and main.care_ui.find_child("Stage_baby",true,false)!=null,"Details is built from the V06 concept with the growth journey")
	check(main.care_ui.meters.size()==6 and main.care_ui.find_child("CareForPet",true,false)!=null and main.care_ui.find_child("BackToMyPet",true,false)!=null,"V06 keeps six stat rows and both footer actions")
	await click(main.care_ui.find_child("CareForPet",true,false))
	check(main.care_ui.mode=="home" and main.care_ui.room_view.material==null and not main.care_ui.room_view is ModalBackdrop,"Closing details restores the sharp playable room")
	for overlay in ["care","menu"]:
		main.care_ui.toggle_overlay(overlay)
		await frames()
		check(not main.care_ui.room_view is ModalBackdrop,"A48: the "+overlay+" overlay keeps the live room sharp, as in the concept")
		main.care_ui.close_overlay()
		await frames()
	home=main.home
	var directory=main.game.store.directory
	main.game.store.directory=directory+"/missing-parent/child"
	before=main.game.pet().needs.fullness
	home.request_care("meal")
	await finish_care(home)
	check(main.game.state.inventory.berry_bowl==meals and main.game.pet().needs.fullness<=before and not home.action_finished and "Could not save" in home.care_feedback,"Failed serving transaction spends no meal and reports the failure")
	main.game.store.directory=directory
	home.request_care("meal")
	await finish_care(home)
	check(main.game.state.inventory.berry_bowl==meals-1 and home.action_finished,"Retry consumes exactly one owned meal after serving")
	home.request_care("sleep")
	check(not main.game.pet().sleeping,"Rest starts by walking to the bed")
	await finish_care(home)
	check(home.bed_occupied() and not home.pet_art.visible,"Completed rest curls Foxy in the existing bed")
	home.request_care("sleep")
	check(not home.bed_occupied(),"Wake restores the active pet")
	for size in [Vector2i(390,844),Vector2i(844,390),Vector2i(1280,720)]:
		root.size=size
		main.show_home()
		await frames()
		var valid=true
		await click(main.care_ui.care_button)
		for b in main.care_ui.action_buttons:
			valid=valid and b.get_global_rect().size.y>=48 and main.care_ui.safe.encloses(b.get_global_rect())
		check(valid and main.care_ui.action_buttons.size()==6,"All six care actions remain safe and at least48px: "+str(size))
	var same_home=main.home
	root.size=Vector2i(390,844)
	await frames()
	check(main.care_ui.home_overlay=="care" and main.home==same_home,"Open care drawer survives rotation on the same room instance")
	root.size=Vector2i(844,390)
	await frames()
	check(main.care_ui.home_overlay=="care" and main.care_ui.sheet.position.x>300 and main.world.transform!=Transform2D.IDENTITY,"Landscape moves Care to the side and reframes the whole room")
	check(main.care_ui.handle_back() and main.care_ui.home_overlay.is_empty() and main.world.transform==Transform2D.IDENTITY,"Back closes the drawer and restores the camera")
	main.care_ui.toggle_overlay("menu")
	await frames()
	check(main.care_ui.sheet.name=="NavigationMenu" and main.care_ui.nav_buttons.size()==8,"One Menu entry reveals all eight secondary destinations")
	var nav_safe=true
	for b in main.care_ui.nav_buttons:
		nav_safe=nav_safe and b.size.y>=48 and main.care_ui.safe.encloses(b.get_global_rect())
	check(nav_safe,"Secondary destinations keep safe >=48px touch targets")
	await click(button(main.care_ui,"Details"))
	check(main.care_ui.mode=="details" and main.care_ui.meters.size()==6,"Menu Details reaches real needs and growth")
	root.size=Vector2i(844,390)
	main.show_adventure()
	await frames()
	var level=main.active_adventure
	var run_id=level.run.id
	Input.action_press("move_right")
	await frames(10)
	root.size=Vector2i(390,844)
	await frames()
	check(main.orientation_blocked and paused and not Input.is_action_pressed("move_right"),"Portrait adventure pauses and releases movement")
	var position=level.player.position
	await frames(30)
	check(level.player.position==position and main.active_adventure==level and level.run.id==run_id,"Rotate prompt freezes the same existing run")
	root.size=Vector2i(844,390)
	await frames()
	check(not paused and not main.orientation_blocked and main.active_adventure==level,"Rotation resumes the same run without restart")
	var controls=main.adventure_ui.controls
	var event=InputEventScreenTouch.new()
	event.index=0;event.pressed=true;event.position=controls.regions.move_right.get_center()
	root.push_input(event,true)
	await frames(8)
	check(Input.is_action_pressed("move_right"),"Production landscape round stick captures an actual touch")
	main.toggle_bag()
	await frames()
	check(paused and not Input.is_action_pressed("move_right") and main.native_screen==main.bag_panel,"Native Bag pauses and clears held movement")
	check(main.bag_panel.room_view is ModalBackdrop and main.adventure_ui.safe.encloses(button(main.bag_panel,"Back").get_global_rect()),"Bag uses blurred live gameplay and safe responsive controls")
	await click(button(main.bag_panel,"Back"))
	check(not paused and main.native_screen==main.adventure_ui and main.active_adventure==level,"Closing Bag restores the same adventure")
	main.toggle_pause()
	await frames()
	root.size=Vector2i(390,844)
	await frames()
	root.size=Vector2i(844,390)
	await frames()
	check(paused and is_instance_valid(main.pause_panel),"Rotation never dismisses a deliberately opened pause modal")
	main.toggle_pause()
	await frames()
	check(not paused and main.native_screen==main.adventure_ui,"Resume clears only the settings pause")
	# A51 foods: buy, favourites, kibble always free.
	main.game.state.coins=100
	check(main.game.buy_food("fish_treat") and main.game.food_count("fish_treat")==1 and main.game.state.coins==80,"Buying a fish treat costs 20 coins and puts it in the bag")
	check(main.game.food_count("kibble")>=1 and not main.game.buy_food("kibble"),"Kibble is always free and never sold")
	main.game.state.pets[0].needs.happiness=50.0
	main.game.state.pets[0].needs.fullness=40.0
	check(main.game.feed_food("fish_treat") and main.game.pet().needs.happiness>=70.0 and main.game.food_count("fish_treat")==0,"A favourite food makes Foxy extra happy and is used up")
	main.game.buy_food("carrot")
	var h=main.game.pet().needs.happiness
	check(main.game.feed_food("carrot") and main.game.pet().needs.happiness<h,"A food Foxy dislikes still feeds but lowers happiness a little")
	check(not main.game.feed_food("honey_cookie"),"You can't serve food you don't have")
	main.free()
	await frames()
	var report=FileAccess.open("res://test-results/care.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Native care completion/cancel/failure/retry, shared live-room blur/sharp portrait, reference details actions, three care sizes, production landscape stick and same-run rotation/modal guards. Desktop simulation, not phone certification or art approval."},"\t"))
	report.close()
	print("PETOPIA CARE TESTS: ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
