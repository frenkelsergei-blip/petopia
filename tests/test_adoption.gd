extends SceneTree
var checks=0
var failures: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok: bool, description: String) -> void:
	checks+=1
	if not ok:
		failures.append(description)
		push_error(description)
func frames(n=8) -> void:
	for i in range(n): await physics_frame
func click(button: Button) -> void:
	await click_at(button.get_global_rect().get_center())
func click_at(point: Vector2) -> void:
	for pressed_value in [true,false]:
		var event=InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT
		event.pressed=pressed_value
		event.position=point
		root.push_input(event,true)
	await frames()
func run() -> void:
	root.size=Vector2i(390,844)
	var main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	var folder="user://adoption-tests/"+str(Time.get_ticks_usec())
	main.save_directory=folder
	root.add_child(main)
	await frames()
	await click(main.main_menu.actions[0])
	var screen=main.adoption_screen
	check(main.screen=="adoption" and main.game.state.is_empty() and main.ui.visible and not main.portrait_ui.visible,"Native adoption opens from Start without creating a profile")
	screen.name_input.text="Sunny Fox"
	for dimensions in [Vector2i(360,640),Vector2i(390,844),Vector2i(430,932),Vector2i(768,1024),Vector2i(1280,720)]:
		root.size=dimensions
		await frames()
		var all_safe=true
		var targets=[screen.name_input,screen.adopt_button,screen.practice,screen.settings]
		for target in targets:
			all_safe=all_safe and screen.safe.encloses(target.get_global_rect()) and target.size.y*dimensions.y/root.content_scale_size.y>=48
		check(all_safe,"Adoption entry/actions respect safe bounds and48px physical targets at "+str(dimensions))
		check(not screen.name_input.get_global_rect().intersects(screen.adopt_button.get_global_rect()) and not screen.adopt_button.get_global_rect().intersects(screen.practice.get_global_rect()),"Name and adoption actions remain separate at "+str(dimensions))
		check(screen.name_input.text=="Sunny Fox" and screen==main.adoption_screen,"Resize preserves typed name and screen instance at "+str(dimensions))
	root.size=Vector2i(390,844)
	main.portrait_ui.safe_override=Vector4(16,32,16,28)
	await frames()
	check(screen.safe==Rect2(16,32,358,784) and screen.safe.encloses(screen.adopt_button.get_global_rect()),"Adoption honors injected notch and gesture insets")
	await click(screen.settings)
	check(is_instance_valid(screen.modal),"Adoption Settings opens a native modal")
	var behind=screen.adopt_button.get_global_rect()
	await click_at(Vector2(behind.get_center().x,behind.end.y-4))
	check(main.game.state.is_empty(),"Settings blocks click-through adoption")
	await click(screen.settings_close)
	check(screen.name_input.text=="Sunny Fox" and not is_instance_valid(screen.modal),"Closing Settings preserves the typed name")
	await click(screen.practice)
	check(main.screen=="menu" and main.game.state.is_empty() and not FileAccess.file_exists(folder+"/save.json"),"Back returns to menu without adopting or saving")
	await click(main.main_menu.actions[0])
	screen=main.adoption_screen
	screen.name_input.text="  Sunny Fox  "
	var directory=main.game.store.directory
	main.game.store.directory=folder+"/missing-parent/child"
	await click(screen.adopt_button)
	check(main.screen=="adoption" and main.game.state.is_empty() and screen.status.visible and not screen.status.text.is_empty(),"Failed adoption write stays on screen with visible feedback and no published pet")
	main.game.store.directory=directory
	await click(screen.adopt_button)
	check(main.screen=="adventure" and is_instance_valid(main.active_world) and main.game.pet().name=="Sunny Fox","Successful adoption keeps trimmed name and enters Green Meadows")
	check(SaveStore.new(folder).load_state().pets[0].name=="Sunny Fox","Adoption publishes only after its named pet is durable")
	main.show_home()
	await frames()
	check(main.home.bed_bounds.size.x>=(main.home.room_size.x*0.18 if ArtStyle.paper else 140.0) and not main.home.bed_occupied(),"Home has a prominent separate empty bed before rest")
	# A56 paper room (P20): the bed is to the left of the pair, on the same floor line.
	var bed_side=main.home.bed_bounds.end.x<main.home.pet_center if ArtStyle.paper else main.home.bed_bounds.position.x>main.home.pet_center
	var bed_floor=absf(main.home.bed_bounds.end.y-main.home.floor_y)<=main.home.room_size.y*0.05 if ArtStyle.paper else main.home.bed_bounds.end.y<=main.home.floor_y
	check(main.home.explorer.scale.y*42/main.home.room_size.y>=0.19 and bed_side and bed_floor and main.home.explorer.position.y==main.home.floor_y,"Room actors have reference-scale presence and the bed stays beside them above the action bar")
	main.game.care("sleep")
	await frames()
	check(main.home.bed_occupied() and (not main.home.pet_art.visible or (main.home.tama and main.home.pet_art.mood=="sleep")),"Rest uses curled Foxy inside the bed without a duplicate standing pet")
	check(SaveStore.new(folder).load_state().pets[0].sleeping,"Sleeping state persists through the existing durable care transaction")
	main.free()
	await frames()
	main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory=folder
	root.add_child(main)
	await frames()
	main.show_home()
	await frames()
	check(main.home.bed_occupied() and main.game.pet().name=="Sunny Fox","Named sleeping pet remains in its bed after restart")
	main.game.care("sleep")
	await frames()
	check(not main.home.bed_occupied() and main.home.pet_art.visible,"Wake restores the live pet and empty bed")
	main.free()
	await frames()
	var output=FileAccess.open("res://test-results/adoption.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"checks":checks,"failures":failures,"scope":"Native adoption across five desktop-simulated sizes; name/back/settings, durable failure/restart and authored home sleep state. Physical keyboard/mobile/child and final visual review pending."},"\t"))
	output.close()
	print("PETOPIA ADOPTION TESTS: ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
