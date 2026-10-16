extends SceneTree
var checks=0
var failures: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok: bool,note: String) -> void:
	checks+=1
	if not ok:
		failures.append(note)
		push_error(note)
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func find_button(parent: Node, caption: String) -> Button:
	for b in parent.find_children("*","Button",true,false):
		if b.text==caption: return b
	return null
func hop(direction: String, travel_frames: int) -> void:
	Input.action_press("jump")
	if not direction.is_empty(): Input.action_press(direction)
	await frames(travel_frames)
	TouchControls.release_actions()
	await frames(45)
func run() -> void:
	var main=load("res://scenes/main/main.tscn").instantiate()
	main.save_directory="user://tool-tests/"+str(Time.get_ticks_usec())
	root.add_child(main)
	main.game.adopt("Tool Fox")
	main.show_adventure("W01_L02")
	await frames(5)
	var level: WindmillAdventure=main.active_adventure
	level.player.reset_to(Vector2(1420,272))
	await frames(3)
	await hop("",28)
	check(absf(level.player.position.y-272)<1,"High ledge cannot be reached by a direct jump from the lower floor")
	# Collect the actual visible bundle with ordinary input.
	level.player.reset_to(Vector2(1180,288))
	Input.action_press("move_right")
	await frames(20)
	Input.action_release("move_right")
	Input.action_press("interact")
	await frames(2)
	Input.action_release("interact")
	check(main.game.available_crates()==3 and "windmill_crates" in main.game.state.discovered_ids,"Visible bundle grants three reusable bag crates")
	level.interact()
	check(main.game.available_crates()==3,"Repeated pickup cannot duplicate the bundle")
	# The player chooses three world positions through the real placement UI.
	level.player.reset_to(Vector2(1578,288))
	main.toggle_bag()
	check(paused and is_instance_valid(main.bag_panel),"Bag opens as a paused inventory panel")
	for point in [Vector2(1544,272),Vector2(1512,272),Vector2(1512,248)]:
		find_button(main.bag_panel,"Place a crate").pressed.emit()
		await frames(2)
		check(not paused and level.crates.placing and not level.player.enabled,"Placement opens a world preview with the child safely stationary")
		level.crates.choose_at(point,level.player.position)
		check(level.crates.can_place(level.player.position),"Chosen ground/stack position is safe")
		find_button(main.placement_ui,"Place").pressed.emit()
		await frames(3)
		if main.game.available_crates()>0:main.toggle_bag()
	check(main.game.available_crates()==0 and level.crates.bodies.size()==3,"Three chosen crates have real collisions and bounded ownership")
	check(not main.game.place_trail_crate_at("W01_L02",Vector2(1512,212)),"Empty bag cannot create extra crates")
	await hop("move_left",17)
	check(absf(level.player.position.y-248)<1,"First ordinary jump lands on the single crate")
	await hop("move_left",16)
	check(absf(level.player.position.y-224)<1,"Second ordinary jump reaches the stacked crates")
	await hop("move_left",30)
	check(absf(level.player.position.y-184)<1 and level.player.position.x<1480,"Crate steps make the previously unreachable high ledge accessible")
	check(main.game.save(),"Tool layout flushes to a durable save")
	var reloaded=SaveStore.new(main.save_directory).load_state()
	check(reloaded.inventory.trail_crate==3 and reloaded.quest_state.free_crates.W01_L02.size()==3,"Bag ownership and stacked layout survive reopening")
	# Pack from anywhere to avoid a lost-tool dead end, then reuse in a different level.
	main.toggle_bag()
	find_button(main.bag_panel,"Pack all placed crates").pressed.emit()
	await frames(2)
	check(main.game.available_crates()==3 and level.crates.bodies.is_empty(),"Packing returns all tools without charging or destroying them")
	main.show_adventure()
	await frames(4)
	var picnic: PicnicAdventure=main.active_adventure
	picnic.player.reset_to(Vector2(1885,288))
	picnic.crates.choose_at(Vector2(1927.5,288),picnic.player.position)
	check(picnic.crates.confirm(picnic.player.position),"Arbitrary unsnapped coordinates work in another adventure")
	await frames(3)
	check(picnic.crates.bodies.size()==1 and main.game.available_crates()==2,"Cross-level use consumes only the free bag count")
	picnic.crates.candidate=Vector2(300,276)
	check(not picnic.crates.confirm(picnic.player.position),"Placement rejects a target out of the child's reach")
	picnic.crates.candidate=picnic.player.position-Vector2(0,12)
	check(not picnic.crates.confirm(picnic.player.position),"Placement cannot spawn a box inside the child")
	picnic.crates.candidate=picnic.companion.position-Vector2(0,12)
	check(not picnic.crates.confirm(picnic.player.position),"Placement cannot spawn a box inside Foxy")
	var invalid=main.game.state.duplicate(true)
	invalid.quest_state.free_crates.W01_L01=[{"x":500,"y":276},{"x":524,"y":276},{"x":548,"y":276},{"x":572,"y":276}]
	check(not main.game.store.validate(invalid),"Save validation rejects more crates than owned")
	for positions in [[{"x":1927.5,"y":276},{"x":1927.5,"y":276}],[{"x":950,"y":276}],[{"x":500,"y":270}],[{"x":500,"y":300}],[{"x":"bad","y":276}]]:
		invalid=main.game.state.duplicate(true)
		invalid.quest_state.free_crates.W01_L01=positions
		check(not main.game.store.validate(invalid),"Save rejects overlapping, unsupported, buried or malformed crates")
	check(main.game.save(),"Free-position layout flushes through the existing ordered writer")
	var roundtrip=SaveStore.new(main.save_directory).load_state()
	check(roundtrip.quest_state.free_crates.W01_L01[0].x==1927.5,"Non-grid position survives JSON save and reload exactly")
	main.game.pack_trail_crates()
	var legacy=main.game.state.duplicate(true)
	legacy.quest_state.crate_layouts={"W01_L02":{"0":1,"1":2}}
	check(main.game.commit(legacy),"Older numbered-layout saves still validate and load")
	check(main.game.crate_positions("W01_L02").size()==3 and main.game.available_crates()==0,"Legacy boxes preserve their original positions and ownership")
	main.game.pack_trail_crates()
	check(main.game.available_crates()==3 and main.game.crate_positions("W01_L02").is_empty(),"Legacy boxes can be recovered into the same free-placement bag")
	main.toggle_bag()
	find_button(main.bag_panel,"Place a crate").pressed.emit()
	await frames(2)
	find_button(main.placement_ui,"Cancel").pressed.emit()
	await frames(2)
	check(main.game.available_crates()==3 and picnic.player.enabled and not picnic.crates.placing,"Cancel leaves inventory unchanged and restores movement")
	# Portrait uses the same world-coordinate picker and native touch-sized controls.
	root.size=Vector2i(390,844)
	picnic.player.reset_to(Vector2(500,288))
	picnic.companion.position=Vector2(455,288)
	picnic.camera.snap_to_target()
	await frames(12)
	main.toggle_bag()
	find_button(main.bag_panel,"Place a crate").pressed.emit()
	await frames(5)
	var picker=main.placement_ui
	var stage=main.portrait_ui.stage_rect
	var world_point=Vector2(546.5,288)
	var canvas_point=main.viewport.canvas_transform*world_point
	var screen_point=stage.position+canvas_point/main.viewport.get_visible_rect().size*stage.size
	var touch=InputEventScreenTouch.new()
	touch.index=0
	touch.position=screen_point
	touch.pressed=true
	Input.parse_input_event(touch)
	await frames(2)
	check(absf(picnic.crates.candidate.x-world_point.x)<.1,"Touch in the portrait playfield selects the intended continuous world position")
	touch.pressed=false
	Input.parse_input_event(touch)
	check(picker.panel.get_global_rect().end.y<=main.portrait_ui.safe_bounds.end.y and picker.panel.position.x>=main.portrait_ui.safe_bounds.position.x,"Placement controls fit portrait safe bounds")
	check(find_button(picker,"Place").size.y>=48 and find_button(picker,"Cancel").size.y>=48,"Placement confirm/cancel retain minimum touch target size")
	root.size=Vector2i(360,640)
	await frames(8)
	check(main.placement_ui==picker and picnic.crates.placing,"Live resize preserves the active placement and chosen location")
	find_button(picker,"Place").pressed.emit()
	await frames(3)
	check(main.game.available_crates()==2 and picnic.player.enabled,"Portrait confirmation creates one crate and resumes normal movement")
	main.game.pack_trail_crates()
	await frames(3)
	# Appearance changes never replace mechanics or the world instance.
	var collider=picnic.player.get_child(0).shape
	ArtStyle.enabled=false
	await frames(2)
	check(not picnic.player.art.sprite.visible,"Graybox comparison hides art sprites")
	ArtStyle.enabled=true
	await frames(2)
	check(picnic.player.art.sprite.visible and picnic.player.get_child(0).shape==collider,"Art pilot reuses the exact same player collision shape")
	check(ArtStyle.texture("explorer_throw").atlas==ArtStyle.texture("foxy_child_dig").atlas,"Player and pet poses use the shared runtime atlas")
	var source=ArtStyle.texture("foxy_baby_idle").atlas.get_image()
	check(source.get_format()==Image.FORMAT_RGBA8 and source.get_pixel(0,0).a<0.5,"Runtime atlas preserves real transparency")
	main.free()
	await frames(2)
	var f=FileAccess.open("res://test-results/trail_tools.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Free-position preview/confirm/cancel, physical staircase, non-grid coordinates, actor/support/overlap/reach checks, saved layouts, legacy recovery, bounded inventory and shared art/graybox colliders."},"\t"))
	f.close()
	print("PETOPIA TRAIL TOOLS TESTS: ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
