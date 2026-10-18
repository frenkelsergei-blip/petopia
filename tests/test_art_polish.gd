extends SceneTree
var checks=0
var failures: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok: bool, description: String) -> void:
	checks+=1
	if not ok:
		failures.append(description)
		push_error(description)
func frames(count=4) -> void:
	for i in range(count): await physics_frame
func run() -> void:
	ArtStyle.enabled=true
	var main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory="user://art-polish-tests/"+str(Time.get_ticks_usec())
	root.add_child(main)
	main.game.adopt("Art Fox")
	main.show_lab()
	await frames()
	var clear_center=true
	for item in main.ui.find_children("*","Panel",true,false):
		clear_center=clear_center and not item.get_global_rect().intersects(Rect2(550,0,180,300))
	check(clear_center,"Desktop gameplay HUD leaves the enlarged hero's upper-route framing unobscured")
	var lab=main.active_lab
	check(ArtStyle.support_y(lab.meadow.ground,690,18)==INF,"No support exists for scenery in the reported 56px gap")
	check(ArtStyle.support_y(lab.meadow.ground,1460,18)==256,"Scenery snaps to a raised bank rather than fixed y288")
	var grounded_props=true
	for x in range(0,2400,200):
		for item in ArtStyle.scenery_placements(lab.meadow.ground,x):
			grounded_props=grounded_props and is_finite(item.point.y) and item.point.y==ArtStyle.support_y(lab.meadow.ground,item.point.x,18 if item.kind=="tree" else item.width/2.0)
	check(grounded_props,"All sampled tree/shrub roots have full-width continuous ground support")
	var geometry: Array[Rect2]=[Rect2(0,288,300,100),Rect2(100,272,64,16)]
	check(ArtStyle.exposed_segments(geometry[0],geometry)==[Vector2(0,100),Vector2(164,300)],"Raised terrain hides buried grass stripes in the lower bank")
	check(ArtStyle.exposed_segments(geometry[1],geometry)==[Vector2(100,164)],"Raised walkable surface remains exposed")
	check(lab.meadow.terrain.contours.size()<lab.meadow.ground.size(),"Connected ground rectangles merge into continuous surface contours")
	check(lab.meadow.terrain.rock.resource_path.ends_with("concept-world-v1/bank.png"),"Every static terrain contour uses the same world-space bank material")
	check(42*lab.camera.zoom.y/360>=0.18 and 42*lab.camera.zoom.y/360<=0.23,"Hero occupies approximately one fifth of gameplay height, matching the concept")
	check(lab.player.art.sprite.physics_interpolation_mode==Node.PHYSICS_INTERPOLATION_MODE_OFF,"Pose pivots/scales cannot interpolate from default oversized transforms")
	var shape=lab.player.get_child(0).shape
	check(shape is CapsuleShape2D and shape.height==30,"Camera/art proportion changes preserve movement collider dimensions")
	lab.player.art.reduced_motion=true
	Input.action_press("move_right")
	var seen={}
	for i in range(30):
		await physics_frame
		if lab.player.art.mood=="run": seen[lab.player.art.walk_frame]=true
	Input.action_release("move_right")
	check(seen.size()>=6,"Continuous physics movement advances a multi-frame distance-driven gait")
	check(lab.player.art.sprite.texture.atlas.resource_path.ends_with("explorer-run-v3.png"),"Running uses color-corrected source poses even with reduced motion enabled")
	Input.action_press("jump")
	await frames(10)
	Input.action_release("jump")
	check(lab.player.art.mood=="jump" and not lab.player.art.grounded,"Airborne child uses the jump pose")
	check(lab.player.art.contact_shadow.visible and lab.player.art.contact_shadow.clearance>10,"Jump shadow is projected down to ground rather than attached under airborne feet")
	for identity in ["explorer","foxy_baby","foxy_child"]:
		var valid=true
		var count=ArtStyle.run_count(identity)
		for index in range(count):
			var texture=ArtStyle.walk_texture(identity,index)
			var frame=ArtStyle.run_frame(identity,index)
			valid=valid and texture.region.has_area() and frame.pivot[1]>0 and texture.region.end.x<=texture.atlas.get_width() and texture.region.end.y<=texture.atlas.get_height()
		check(valid and count==(8 if identity=="explorer" else 6),"Measured full source frames and planted pivots: "+identity)
	check(ArtStyle.COIN_SIZE==20 and lab.meadow.coin_texture.resource_path==PetUI.COIN_PATH,"Larger pickups retain the canonical coin resource")
	main.show_ball()
	await frames()
	check(main.active_ball.background is GardenPlayground,"Fetch uses a dedicated home garden, not an adventure meadow")
	check(main.active_ball.background.texture.resource_path.ends_with("home-garden-scaled.png"),"Garden uses the child-scaled cottage composition")
	check(main.active_ball.child.scale==Vector2(2,2) and main.active_ball.foxy.scale==Vector2(2,2),"Garden actors retain readable concept proportions")
	check(main.ui.find_children("*","ThrowMeter",true,false).size()==1,"Desktop fetch presents the shared contextual throw meter")
	main.active_ball.aim_time=main.active_ball.aim_time_for_catch()
	main.active_ball.throw_ball()
	await frames(112)
	check(not main.active_ball.practice and not main.active_ball.done,"Scaled child throw still completes practice with automatic pet catch")
	var wallet=main.game.state.coins
	main.show_river_art_test()
	await frames(12)
	var river=main.active_lab
	check(main.viewport.size==Vector2i(1280,720) and main.viewport.get_visible_rect().size==Vector2(640,360),"Native render resolution doubles without changing logical camera/physics coordinates")
	check(river.player.art.sprite.material==null and river.player.art.sprite.texture_filter==CanvasItem.TEXTURE_FILTER_LINEAR,"Actor shaded alpha edges survive the runtime rendering path")
	check(river.art_focus and not river.meadow.bridge and river.player.is_on_floor(),"River entry starts on the bank with a usable closed bridge")
	check(river.meadow.focus.visible and river.meadow.focus.target=="crank","Available nearby crank receives shared contour focus and Use cue")
	river.interact()
	await frames(30)
	check(river.meadow.bridge and river.meadow.bridge_progress==1 and river.meadow.crank_angle>6,"Using the crank rotates its gear and reveals the bridge")
	check(not river.meadow.focus.outline.visible,"Finished bridge stops decorative crank emphasis while retaining the lab close action")
	river.interact()
	await frames(30)
	check(not river.meadow.bridge and river.meadow.bridge_progress==0,"Using the crank again safely closes the unoccupied bridge")
	river.interact()
	await frames(30)
	var old_position=river.companion.position
	river.companion.position=Vector2(1800,288)
	river.interact()
	check(river.meadow.bridge,"Crank refuses to remove bridge collision from under Foxy")
	river.companion.position=old_position
	await frames(65)
	check(absf(river.player.position.x-river.companion.position.x)>=24,"A new short trail leaves readable space between stationary child and Foxy")
	Input.action_press("move_right")
	await frames(70)
	Input.action_press("jump")
	await frames(12)
	Input.action_release("jump")
	await frames(115)
	Input.action_release("move_right")
	await frames(30)
	check(river.player.position.x>1930 and river.player.is_on_floor() and river.fall_count==0,"Continuous movement and jump cross the painted bridge onto its destination bank")
	check(river.companion.position.x>1900 and river.companion.is_on_floor(),"Foxy follows across the same physical crossing and rests on the destination bank")
	check(not river.meadow.focus.visible,"Interaction focus disappears when the player leaves the usable object range")
	var reserved: Array[Vector2]=[river.LAYOUT.crank,river.LAYOUT.checkpoint,river.LAYOUT.discovery,river.LAYOUT.basket]
	var clear_props=true
	for origin in range(0,2600,200):
		for item in ArtStyle.scenery_placements(river.meadow.ground,origin,reserved):
			clear_props=clear_props and ArtStyle.scenery_clear(item.point.x,item.width,reserved)
	check(clear_props,"Trees and shrubs leave interaction props and the checkpoint flag unobscured")
	MeadowCrossingKit.prepare()
	check(MeadowCrossingKit._river.resource_path.ends_with("river-cascade.png"),"Original illustrated river, waterfall and rocks are retained")
	var submerged=true
	for pile in MeadowCrossingKit.bridge_piles(river.LAYOUT.stream):
		submerged=submerged and pile.end.y>river.LAYOUT.stream.position.y+32
	check(submerged,"All three structural piles extend into the shared water plane")
	river.player.reset_to(river.LAYOUT.basket)
	await frames(4)
	river.interact()
	await frames(3)
	check(river.goals.finish and river.meadow.selected_target.is_empty() and not river.meadow.focus.visible,"Completed lab destination removes its contextual cue immediately")
	check(main.game.state.coins==wallet,"The focused art test never awards or spends durable currency")
	main.show_adventure("W01_L01")
	await frames(4)
	var adventure=main.active_adventure
	adventure.player.reset_to(adventure.LAYOUT.checkpoint+Vector2(20,0))
	await frames(4)
	check(adventure.meadow.marker.active and adventure.meadow.marker.activation_time>0,"First checkpoint arrival activates the flag reaction")
	await frames(90)
	adventure.player.reset_to(adventure.LAYOUT.checkpoint)
	await frames(4)
	check(adventure.meadow.marker.activation_time==0,"A visited checkpoint does not repeatedly flash when standing on or returning to it")
	main.show_adventure("W01_L01")
	await frames(4)
	adventure=main.active_adventure
	check(adventure.meadow.marker.active and adventure.meadow.marker.activation_time==0,"Saved checkpoint loads active without replaying arrival effects")
	adventure.player.reset_to(adventure.LAYOUT.arrival+Vector2(45,0))
	adventure.interact()
	check(adventure.resident is PicnicResident and adventure.resident.reaction=="wave","Moss has an illustrated sprite and responds when the child talks")
	adventure.player.reset_to(adventure.LAYOUT.discovery)
	adventure.ability()
	await frames(4)
	check(adventure.run.secret and not adventure.meadow.cache_open and adventure.meadow.selected_target=="cache","Foxy reveals a closed chest with a separate Open action")
	var before_chest=main.game.state.coins
	adventure.interact()
	await frames(4)
	check(adventure.run.cache_open and adventure.meadow.cache_open and not adventure.meadow.focus.visible,"Use opens the revealed chest and clears its emphasis")
	adventure.interact()
	check(main.game.state.coins==before_chest,"Opening/reopening cannot duplicate currency; bonus remains part of durable completion")
	check(main.game.save() and SaveStore.new(main.save_directory).load_state().pending_run.cache_open,"Opened chest survives ordered save and reload")
	var invalid=main.game.state.duplicate(true)
	invalid.pending_run.cache_open="yes"
	check(not main.game.store.validate(invalid),"Save validation rejects an invalid optional chest state")
	var legacy=main.game.state.duplicate(true)
	legacy.pending_run.erase("cache_open")
	check(main.game.store.validate(legacy),"Older adventure saves without a chest field remain loadable")
	var blocking: Array[Rect2]=[Rect2(0,288,600,100),Rect2(300,272,35,16)]
	check(ArtStyle.root_support(blocking,300,82)==INF,"A raised step crossing the root footprint prevents planting a tree through it")
	main.free()
	await frames(2)
	var file=FileAccess.open("res://test-results/art_polish.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Continuous contour rendering, reduced-motion run playback, terrain-projected pixel shadow, usable animated crank, bridge opening/closing and full source-frame bounds. Ground support and exposed surfaces, reference-derived terrain regions, hero framing, multi-frame gait, local interpolation, airborne shadow state, canonical larger coins, dedicated garden and scaled automatic fetch. Visual approval, complete animation inventory and device playtests remain open."},"\t"))
	file.close()
	print("PETOPIA ART POLISH TESTS: ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
