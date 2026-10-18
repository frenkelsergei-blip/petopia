extends SceneTree
var checks=0
var failures: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok: bool, description: String) -> void:
	checks+=1
	if not ok:
		failures.append(description)
		push_error(description)
func frames(n=5) -> void:
	for i in range(n): await physics_frame
func click(button: Button) -> void:
	for pressed_value in [true,false]:
		var event=InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT
		event.pressed=pressed_value
		event.position=button.get_global_rect().get_center()
		root.push_input(event,true)
	await frames()
func find_button(parent: Node, text: String) -> Button:
	for button in parent.find_children("*","Button",true,false):
		if button.text==text: return button
	return null
func run() -> void:
	root.size=Vector2i(1280,720)
	var main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	var folder="user://menu-tests/"+str(Time.get_ticks_usec())
	main.save_directory=folder
	root.add_child(main)
	await frames()
	check(main.screen=="menu" and main.game.state.is_empty() and not FileAccess.file_exists(folder+"/save.json"),"Fresh boot shows menu without creating a pet or profile")
	check(main.main_menu.actions[0].text=="Start" and main.main_menu.actions[0].has_focus(),"Fresh profile has a focused and explicit start action")
	check(not main.main_menu.actions[3].disabled,"Collection opens the actual owned pets and memories")
	check(main.main_menu.wallet.get_node("CoinIcon").texture.resource_path==PetUI.COIN_PATH and main.main_menu.wallet.get_child(2).text=="0","Menu uses canonical coin and actual empty wallet")
	var actor_rect=main.main_menu.friends.get_global_rect()
	var shadow_rect=main.main_menu.contact_shadow.get_global_rect()
	var poses=[]
	for i in range(200):
		await frames(1)
		var pose=main.main_menu.friends.frame_index
		if not pose in poses: poses.append(pose)
	check(poses.size()==4,"Petting loop actually visits four distinct authored poses")
	check(main.main_menu.friends.get_global_rect()==actor_rect and main.main_menu.contact_shadow.get_global_rect()==shadow_rect,"Menu animation keeps its canvas and ground contact fixed")
	for dimensions in [Vector2i(360,640),Vector2i(390,844),Vector2i(430,932),Vector2i(768,1024),Vector2i(1280,720)]:
		root.size=dimensions
		await frames()
		var menu=main.main_menu
		var all_safe=true
		var all_separate=true
		var content_fits=true
		var buttons=menu.actions+[menu.practice,menu.settings]
		for b in buttons:
			var rect=b.get_global_rect()
			content_fits=content_fits and b.get_minimum_size().y<=b.size.y and b.size.x<=b.get_meta("layout_size").x+0.01
			var symbol=b.get_node_or_null("Content/Symbol") as Control
			if symbol: content_fits=content_fits and rect.encloses(symbol.get_global_rect())
			all_safe=all_safe and menu.safe.encloses(rect) and rect.size.y*dimensions.y/root.content_scale_size.y>=48
			for other in buttons:
				if other!=b: all_separate=all_separate and not rect.intersects(other.get_global_rect())
		check(all_safe and all_separate,"Safe, separate >=48px menu actions at "+str(dimensions))
		check(content_fits,"Native text minima and icons fit the intended button frames at "+str(dimensions))
		var uniform_actions=true
		for b in menu.actions:
			var symbol=b.get_node("Content/Symbol") as Control
			uniform_actions=uniform_actions and b.size==menu.actions[0].size and b.get_theme_font_size("font_size")==menu.actions[0].get_theme_font_size("font_size") and absf(symbol.position.y+symbol.size.y/2-b.size.y/2)<0.1
		check(uniform_actions,"Equal action sizes and fonts with vertically centered icons after resize/focus at "+str(dimensions))
		var heading=menu.collection_title.get_global_rect()
		var caption=menu.collection_subtitle.get_global_rect()
		var gear=menu.settings_icon.get_global_rect()
		var settings_text=menu.settings_title.get_global_rect()
		check(heading.end.y+2<=caption.position.y and menu.actions[3].get_global_rect().encloses(caption) and absf(gear.get_center().y-settings_text.get_center().y)<0.5 and not gear.intersects(settings_text),"Collection lines are separate and Settings icon/text share one center at "+str(dimensions))
		check(not menu.friends.get_global_rect().intersects(menu.actions[3].get_global_rect()),"Foreground friends do not cover controls at "+str(dimensions))
	root.size=Vector2i(390,844)
	main.portrait_ui.safe_override=Vector4(16,32,16,28)
	await frames()
	check(main.main_menu.safe==Rect2(16,32,358,784),"Main menu respects notch and gesture insets")
	await click(main.main_menu.settings)
	check(is_instance_valid(main.main_menu.modal) and find_button(main.main_menu,"Reduced motion: Off").has_focus(),"Actual Settings click opens focused native controls")
	await click(find_button(main.main_menu,"Reduced motion: Off"))
	await click(find_button(main.main_menu,"Large"))
	var stopped=main.main_menu.friends.elapsed
	await frames(40)
	check(main.main_menu.friends.frame_index==0 and main.main_menu.friends.elapsed==stopped,"Reduced motion freezes decorative petting on its calm first pose")
	check(main.game.preferences().reduced_motion and main.game.preferences().touch_size==68 and main.game.state.is_empty(),"Settings work before adoption without creating a pet")
	check(SaveStore.new(folder).load_preferences().touch_size==68,"Pre-adoption preference survives fresh disk read")
	check(not main.game.set_preference("touch_size",1),"Unsafe button size is rejected")
	var saved_directory=main.game.store.directory
	main.game.store.directory=folder+"/missing-parent/child"
	check(not main.game.set_preference("touch_size",52) and main.game.preferences().touch_size==68,"Failed preference write does not publish unsaved selection")
	check(not main.main_menu.settings_feedback.text.is_empty(),"Failed setting transaction has visible modal feedback")
	main.game.store.directory=saved_directory
	var modal=main.main_menu.modal
	await click(main.main_menu.practice)
	check(main.screen=="menu" and main.main_menu.modal==modal,"Settings overlay blocks click-through to Practice")
	root.size=Vector2i(1280,720)
	await frames()
	check(main.main_menu.modal==modal and main.game.preferences().touch_size==68,"Resize preserves open settings and preferences")
	await click(main.main_menu.settings_close)
	check(not is_instance_valid(main.main_menu.modal) and main.main_menu.settings.has_focus(),"Done closes settings and restores keyboard focus")
	await click(main.main_menu.practice)
	check(main.screen=="adoption" and main.game.state.is_empty(),"Mini games requests adoption when there is no companion")
	main.show_lab()
	await frames()
	check(main.active_lab.meadow.reduced_motion and main.active_lab.player.art.reduced_motion,"Practice respects pre-adoption reduced-motion preference")
	main.show_hub()
	await frames()
	await click(find_button(main.ui,"Main menu"))
	check(main.screen=="menu","Practice can return to main menu")
	main.main_menu.actions[0].grab_focus()
	for pressed_value in [true,false]:
		var key=InputEventKey.new()
		key.keycode=KEY_ENTER
		key.pressed=pressed_value
		root.push_input(key,true)
	await frames()
	check(main.screen=="adoption" and main.game.state.is_empty(),"Start opens adoption before gameplay")
	await click(find_button(main.ui,"Adopt Foxy"))
	check(main.screen=="adventure" and main.active_adventure.run.level_id=="W01_L01","Adoption continues directly into first adventure")
	check(main.game.state.settings.touch_size==68 and main.game.state.settings.reduced_motion,"Adopted profile inherits saved pre-adoption preferences")
	check(main.game.set_preference("touch_spacing",24) and SaveStore.new(folder).load_state().settings.touch_spacing==24,"Existing profile preferences commit durably through profile writer")
	main.show_adventure("W01_L02")
	await frames()
	main.active_adventure.run.checkpoint=1
	main.active_adventure.run.pickups=[0,1]
	main.show_menu()
	main.game.save()
	var before=main.game.state.coins
	var run_id=main.game.state.pending_run.id
	main.free()
	await frames()
	main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory=folder
	root.add_child(main)
	await frames()
	check(main.main_menu.actions[0].text=="Continue","Returning profile boots to Continue")
	check(main.main_menu.wallet.get_child(2).text==str(before),"Returning menu shows saved wallet rather than concept example")
	await click(main.main_menu.actions[0])
	check(main.active_adventure.run.id==run_id and main.active_adventure.run.level_id=="W01_L02" and main.active_adventure.run.checkpoint==1,"Continue reloads exact level/run/checkpoint after restart")
	check(main.active_adventure.run.pickups==[0,1] and main.game.state.coins==before,"Continue preserves collected items without granting duplicate rewards")
	main.toggle_pause()
	await frames()
	await click(find_button(main.ui,"Main menu"))
	check(main.screen=="menu" and not paused,"Pause returns to menu and clears pause state")
	main.free()
	await frames()
	var output=FileAccess.open("res://test-results/main_menu.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"checks":checks,"failures":failures,"scope":"Native menu clicks, layout/safe areas, adoption/resume across restart, durable preference boundaries. Desktop simulated mobile sizes; no physical-device or final art approval."},"\t"))
	output.close()
	print("PETOPIA MENU TESTS: ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
