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
func height(actor: Node) -> float:
	if actor.home_pose!=null: return actor.home_pose_body_height*actor.sprite.scale.y*actor.scale.y
	return (float(ArtStyle.walk_row("explorer" if actor.kind=="child" else ("foxy_child" if actor.child_stage else "foxy_baby")).body_height) if actor.mood=="run" else actor.sprite.texture.get_height())*actor.sprite.scale.y*actor.scale.y
func run() -> void:
	root.size=Vector2i(1280,720)
	var main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	var folder="user://home-growth-tests/"+str(Time.get_ticks_usec())
	main.save_directory=folder
	root.add_child(main)
	await frames()
	main.game.adopt("Growth Fox")
	main.show_home()
	await frames()
	var home=main.home
	var hero_height=height(home.explorer)
	var bed=home.bed_bounds
	var previous=0.0
	var last_sleep_width=0.0
	var ratios=[]
	for index in range(PetRules.STAGES.size()):
		var stage=PetRules.STAGES[index]
		var candidate=main.game.state.duplicate(true)
		PetRules.apply_elapsed(candidate.pets[0],maxf(0,PetRules.THRESHOLDS[index]-candidate.pets[0].elapsed_age_seconds),true)
		main.game.commit(candidate)
		await frames()
		var fox_height=height(home.pet_art)
		var ratio=fox_height/hero_height
		ratios.append(ratio)
		check(main.game.pet().growth_stage==stage and fox_height>previous ,"Real age threshold gives a distinct rendered height: "+stage)
		check(height(home.explorer)==hero_height and home.bed_bounds==bed and ratio<1.0,"Child/bed stay fixed and Foxy stays shorter than the explorer: "+stage)
		previous=fox_height
		main.game.care("sleep")
		await frames()
		var asleep=home.sleep_bounds()
		check(home.bed_occupied() and not home.pet_art.visible and asleep.size.x>last_sleep_width,"Only the independent sleeping Foxy grows inside the bed: "+stage)
		last_sleep_width=asleep.size.x
		check(Rect2(bed.position-Vector2(0,20),bed.size+Vector2(0,20)).encloses(asleep) and absf(asleep.get_center().x-bed.get_center().x)<0.1,"Sleeping contour fits the same mattress at a fixed center: "+stage)
		for dimensions in [Vector2i(390,844),Vector2i(1280,720)]:
			root.size=dimensions
			await frames()
			var reference_hero=42*home.room_scale()
			check(absf(height(home.explorer)-reference_hero)<.01 and home.bed_bounds.size.x>=140 and Rect2(home.bed_bounds.position-Vector2(0,20),home.bed_bounds.size+Vector2(0,20)).encloses(home.sleep_bounds()),"Responsive furniture preserves the hero proportion and mattress fit: "+stage+str(dimensions))
		main.game.care("sleep")
		await frames()
		check(home.pet_art.visible and absf(height(home.pet_art)-fox_height)<0.01,"Wake restores exactly the age-appropriate standing size: "+stage)
	check(ratios[0]<0.65 and ratios[3]>0.85 and ratios[3]<0.95,"Baby stays compact and adult approaches explorer height without overtaking it")
	main.game.care("sleep")
	var adult_width=home.sleep_bounds().size.x
	main.free()
	await frames()
	main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory=folder
	root.add_child(main)
	await frames()
	main.show_home()
	await frames()
	check(main.game.pet().growth_stage=="adult" and main.home.bed_occupied() and absf(main.home.sleep_bounds().size.x-adult_width)<0.01,"Restart retains adult age, sleep and its larger body in the same bed")
	main.free()
	await frames()
	var output=FileAccess.open("res://test-results/home_growth.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"checks":checks,"failures":failures,"ratios":ratios,"scope":"Isolated real age thresholds, actual room sprite heights, fixed explorer/bed, sleeping bounds, wake, desktop/portrait resize and adult sleep restart. Mature identity art, final visual approval and physical devices remain pending."},"\t"))
	output.close()
	print("PETOPIA HOME GROWTH TESTS: ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
