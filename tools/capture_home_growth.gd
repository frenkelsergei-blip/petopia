extends SceneTree
var main: Control
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for i in range(12): await physics_frame
	await RenderingServer.frame_post_draw
func run() -> void:
	root.size=Vector2i(1280,720)
	main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory="user://home-growth-capture/"+str(Time.get_ticks_usec())
	root.add_child(main)
	await settle()
	main.game.adopt("Foxy")
	main.game.set_preference("reduced_motion",true)
	main.show_home()
	await settle()
	for index in range(PetRules.STAGES.size()):
		var stage=PetRules.STAGES[index]
		var candidate=main.game.state.duplicate(true)
		var pet=candidate.pets[0]
		PetRules.apply_elapsed(pet,maxf(0,PetRules.THRESHOLDS[index]-pet.elapsed_age_seconds),true)
		# The age fixture keeps healthy needs equal so only presentation varies.
		pet.needs=PetRules.fresh("Foxy",Time.get_unix_time_from_system()).pets[0].needs
		pet.sleeping=false
		main.game.commit(candidate)
		main.show_home()
		await settle()
		for sleeping in [false,true]:
			candidate=main.game.state.duplicate(true)
			candidate.pets[0].sleeping=sleeping
			main.game.commit(candidate)
			for entry in [["desktop",Vector2i(1280,720)],["portrait",Vector2i(390,844)]]:
				root.size=entry[1]
				await settle()
				var label="growth-"+stage+"-"+("sleep" if sleeping else "awake")+"-"+entry[0]
				root.get_texture().get_image().save_png("res://docs/screenshots/"+label+".png")
	main.free()
	await process_frame
	print("PETOPIA GROWTH CAPTURES:16 actual room frames; four ages, awake/sleep, desktop/portrait; isolated fixture")
	quit()
