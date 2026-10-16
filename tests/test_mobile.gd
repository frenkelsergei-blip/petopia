extends SceneTree
var checks=0
var failures: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok: bool, description: String) -> void:
	checks+=1
	if not ok:
		failures.append(description)
		push_error(description)
func frames(count=5) -> void:
	for i in range(count): await physics_frame
func mobile_button(main: Node, text: String) -> Button:
	for b in (main.native_screen if is_instance_valid(main.native_screen) else main.portrait_ui).find_children("*","Button",true,false):
		if b.text==text: return b
	return null
func finger(index: int, action: String, pressed: bool, controls: TouchControls) -> void:
	var event=InputEventScreenTouch.new()
	event.index=index
	event.position=controls.regions[action].get_center()
	event.pressed=pressed
	root.push_input(event,true)
func run() -> void:
	root.size=Vector2i(390,844)
	var main=load("res://scenes/main/main.tscn").instantiate()
	main.require_landscape=false # Retain diagnostic portrait physics/two-finger coverage; test_care covers the production rotation gate.
	main.save_directory="user://mobile-tests/"+str(Time.get_ticks_usec())
	root.add_child(main)
	await frames()
	check(main.ui.visible and not main.portrait_ui.visible and main.screen=="menu","Native responsive main menu owns portrait boot")
	main.show_hub()
	await frames()
	var lab_button=mobile_button(main,"Movement lab")
	for pressed_value in [true,false]:
		var click=InputEventMouseButton.new()
		click.button_index=MOUSE_BUTTON_LEFT
		click.pressed=pressed_value
		click.position=lab_button.get_global_rect().get_center()
		root.push_input(click,true)
	await frames()
	check(main.screen=="lab","Portrait menu launches shared movement lab without adoption")
	check(main.game.adopt("Touch Fox"),"Adopt in isolated mobile profile")
	main.show_adventure("W01_L02")
	await frames()
	var level=main.active_adventure
	var mobile=main.portrait_ui
	for dimensions in [Vector2i(360,640),Vector2i(390,844),Vector2i(430,932),Vector2i(768,1024)]:
		root.size=dimensions
		await frames()
		check(main.active_adventure==level,"Resize preserves adventure instance at "+str(dimensions))
		var hitboxes=mobile.controls.regions
		var valid=true
		for key in hitboxes:
			var rect: Rect2=hitboxes[key]
			valid=valid and rect.size.x*dimensions.x/390.0>=48 and mobile.safe_bounds.encloses(rect) and not mobile.stage_rect.intersects(rect)
			for other in hitboxes:
				if key!=other: valid=valid and not rect.intersects(hitboxes[other])
		check(valid,"Touch targets remain >=48px, safe and separated at "+str(dimensions))
		var half=main.viewport.get_visible_rect().size.x*0.5/level.camera.zoom.x
		check(is_equal_approx(level.camera.position.x,clampf(level.player.position.x,half,level.camera.course_width-half)),"Camera centers within current portrait width at "+str(dimensions))
	root.size=Vector2i(390,844)
	mobile.safe_override=Vector4(16,32,16,28)
	await frames()
	check(mobile.safe_bounds==Rect2(16,32,358,784),"Safe-area override reserves top notch and bottom gesture space")
	var controls=mobile.controls
	var x=level.player.position.x
	finger(0,"move_right",true,controls)
	await frames(10)
	finger(1,"jump",true,controls)
	await frames(4)
	check(level.player.position.x>x+15 and level.player.velocity.y<0,"Two real touch events move and jump the child simultaneously")
	finger(1,"jump",false,controls)
	check(Input.is_action_pressed("move_right") and not Input.is_action_pressed("jump"),"Releasing jump keeps the other movement finger held")
	var drag=InputEventScreenDrag.new()
	drag.index=0
	drag.position=controls.joystick_center-Vector2(controls.joystick_radius*1.4,0)
	root.push_input(drag,true)
	check(Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"),"Captured round stick reverses direction beyond its outer ring")
	drag=InputEventScreenDrag.new()
	drag.index=0
	drag.position=controls.joystick_center
	root.push_input(drag,true)
	check(not Input.is_action_pressed("move_left") and controls.joystick_pointer==0,"Stick dead zone stops motion while retaining finger capture")
	drag=InputEventScreenDrag.new()
	drag.index=0
	drag.position=controls.joystick_center+Vector2(controls.joystick_radius*1.4,0)
	root.push_input(drag,true)
	check(Input.is_action_pressed("move_right"),"Captured stick resumes after crossing its neutral center")
	finger(2,"move_left",true,controls)
	check(controls.joystick_pointer==0 and Input.is_action_pressed("move_right"),"A second finger cannot steal an occupied movement stick")
	finger(2,"move_left",false,controls)
	finger(0,"move_right",false,controls)
	check(controls.thumb_offset==Vector2.ZERO and not Input.is_action_pressed("move_right"),"Releasing stick returns cap to center and releases movement")
	finger(0,"move_right",true,controls)
	mobile_button(main,"Bag").pressed.emit()
	await frames()
	check(is_instance_valid(main.bag_panel) and paused and not Input.is_action_pressed("move_right"),"Touch bag pauses and clears held actions")
	check(main.bag_panel.get_global_rect().encloses(mobile_button(main,"Place a crate").get_global_rect()),"Native bag places build controls within its responsive modal")
	mobile_button(main,"Back").pressed.emit()
	await frames()
	check(not paused and main.active_adventure==level,"Closing portrait bag resumes same adventure")
	main.toggle_pause()
	await frames()

	mobile.set_touch("touch_size",68)
	mobile.set_touch("touch_spacing",24)
	mobile.set_touch("touch_raise",32)
	await frames()
	check(main.game.state.settings.touch_size==68 and main.game.state.settings.touch_spacing==24 and main.game.state.settings.touch_raise==32,"Control size and spacing commit through durable game settings")
	var store=SaveStore.new(main.save_directory)
	check(store.load_state().settings.touch_size==68,"Touch preference survives fresh save load")
	var invalid=main.game.state.duplicate(true)
	invalid.settings.touch_size=1
	check(not store.validate(invalid),"Save validation rejects an unsafe touch-target size")
	mobile.settings_open=false
	main.toggle_pause()
	await frames()
	var safe=true
	for rect in mobile.controls.regions.values(): safe=safe and mobile.safe_bounds.encloses(rect)
	check(safe,"Largest raised controls and widest spacing remain within notch-safe bounds")
	for method in ["show_home","show_map","show_shop","show_decorate","show_details","show_progress","show_ball"]:
		main.call(method)
		await frames()
		var surface=main.native_screen if is_instance_valid(main.native_screen) else mobile
		var columns=surface.find_children("*","VBoxContainer",true,false)
		var fitted=true
		for column in columns:
			fitted=fitted and column.size.x<=mobile.safe_bounds.size.x
		check(fitted,"Portrait content fits scroll width: "+method)
	main.show_ball()
	await frames()
	check(main.viewport.size_2d_override.x==440 and main.viewport.size.x==880 and 42*main.active_ball.child.scale.y*(main.play_ui.content.get_node("GardenStage").size.y)/360>=60,"Portrait playground preserves actor framing while rendering at double native resolution")
	mobile_button(main,"Throw").pressed.emit()
	await frames(4)
	check(main.active_ball.in_flight,"Portrait throw invokes child throw; pet fetch remains automatic")
	main.show_adventure()
	await frames()
	level=main.active_adventure
	root.size=Vector2i(1280,720)
	await frames()
	check(not mobile.visible and main.ui.visible and main.active_adventure==level and main.viewport.size_2d_override==Vector2i(640,360) and main.viewport.size==Vector2i(1280,720),"Landscape restores a high-resolution desktop view without restarting or reframing the level")
	main.show_adventure("W01_L01")
	await frames()
	main.active_adventure.run.basket=true
	main.active_adventure.player.reset_to(Vector2(220,288))
	main.active_adventure.interact()
	await frames()
	for window_size in [Vector2i(360,640),Vector2i(390,844),Vector2i(430,932),Vector2i(768,1024)]:
		root.size=window_size
		await frames(8)
		var labels=main.native_screen.find_children("*","Label",true,false)
		check(labels.any(func(label):return label.text=="Adventure complete!") and labels.any(func(label):return "Berry bowl" in label.text),"Portrait result retains story/rewards with scrolling: "+str(window_size))
	main.free()
	await frames(2)
	var file=FileAccess.open("res://test-results/mobile.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Simulated 360×640,390×844,430×932 and768×1024 layouts, notch insets, two-finger physics, modal actions, saved controls and live resize. Physical Android/iOS devices and exports remain untested."},"\t"))
	file.close()
	print("PETOPIA MOBILE TESTS: ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
