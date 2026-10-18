extends SceneTree
## World art audit (A57 pipeline): visits every room and spawn, then lists each
## picture the world drew and the folder it came from. Anything not from the
## current world style folder is printed as OLD and the run exits non-zero.
const STYLE="res://assets/art/meadow-p31/"
func _initialize() -> void: call_deferred("run")
func run() -> void:
	OS.low_processor_usage_mode=false
	Engine.max_fps=0
	print("AUDIT start ",Engine.get_frames_per_second())
	root.size=Vector2i(844,390)
	var main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory="user://audit/"+str(Time.get_ticks_usec())
	root.add_child(main)
	main.game.adopt("Foxy")
	for key in main.game.pet().needs: main.game.pet().needs[key]=100.0
	main.show_world()
	for i in 10: await physics_frame
	var data=GameState.world_data()
	for id in data.rooms:
		for spawn in data.rooms[id].spawns:
			# Walking into an exit can leave the world: come back in.
			if not is_instance_valid(main.active_world):
				main.show_world()
				for i in 4: await physics_frame
			main.active_world.enter(id,spawn)
			for i in 6: await physics_frame
			await process_frame
			await process_frame
			# Walk the whole room so every piece gets drawn.
			var w=float(data.rooms[id].size[0])
			for x in range(0,int(w),600):
				if not is_instance_valid(main.active_world): break
				main.active_world.player.reset_to(Vector2(x,main.active_world.player.position.y))
				main.active_world.camera.snap_to_target()
				await process_frame
			await process_frame
	print("AUDIT rooms done")
	var old=[]
	var names=MeadowWorld.used_art.keys()
	names.sort()
	# Rooms with their own environment kit may only use that kit, plus the
	# shared pieces every place has (coins, pickups, chests, markers, critters).
	var kit={"hidden_cave":"cave/","old_tower":"tower/","windmill_cellar":"cellar/"}
	var shared=["coin","chest","chest_open","crate","twinkle","mark_found","mark_arrow","mark_down","dug_hole","heart_pickup","sky_feather","ball_red","sun_ball","river_water"]
	for n in names:
		var path: String=MeadowWorld.used_art[n]
		var rid: String=n.get_slice("|",0)
		var piece: String=n.get_slice("|",1)
		var bad=not path.begins_with(STYLE)
		if kit.has(rid) and not path.begins_with(STYLE+kit[rid]) and not piece in shared and not piece.begins_with("pickup_") and not piece.ends_with(("_a")) and not piece.ends_with("_b") and not piece.ends_with("_dizzy") and not piece.begins_with("moss_") and not piece.begins_with("__"): bad=true
		if bad: old.append("%s  <-  %s"%[n,path])
	print("WORLD ART: %d pictures, %d not in the current style"%[names.size(),old.size()])
	for line in old: print("OLD ",line)
	main.free()
	await process_frame
	quit(0 if old.is_empty() else 1)
