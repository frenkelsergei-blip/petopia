extends SceneTree
## V2 connected Green Meadows: data integrity, durable progress, room
## transitions, Foxy Boost and jump reachability of every chest and exit.
var checks=0
var failures: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures.append(message);push_error(message)
func frames(n=4) -> void:
	for i in range(n): await physics_frame

## Same ballistic model as Explorer: can a jump from height 0 land on a ledge
## `rise` higher after travelling `gap` horizontally (optionally boosting)?
func reach(gap: float, rise: float, boost: bool) -> bool:
	var x=0.0
	var y=0.0
	var vy=-Explorer.JUMP
	var used=false
	var dt=1.0/240.0
	for i in range(2400):
		if boost and not used and vy<=0:
			vy=-Explorer.BOOST
			used=true
		var py=y
		y+=vy*dt
		vy-=Explorer.GRAVITY*dt
		x+=Explorer.SPEED*dt
		if vy<0 and py>=rise and rise>y and x>=gap: return true
		if y<-80: return false
	return false

## Surfaces reachable in a room from its spawns.
func reachable(room: Dictionary, boost: bool) -> Array:
	var ground: Array=room.ground
	var seen: Array=[]
	var queue: Array=[]
	for spawn in room.spawns.values():
		for i in range(ground.size()):
			var r=ground[i]
			if spawn[0]>=r[0] and spawn[0]<=r[0]+r[2] and absf(spawn[1]-r[1])<2 and not i in seen:
				seen.append(i)
				queue.append(i)
	while not queue.is_empty():
		var a=ground[queue.pop_front()]
		for j in range(ground.size()):
			if j in seen: continue
			var b=ground[j]
			var gap=maxf(0,maxf(b[0]-(a[0]+a[2]),a[0]-(b[0]+b[2])))
			var rise=a[1]-b[1]
			var ok=false
			if rise<=2: ok=gap<=12 or reach(gap+8,maxf(rise,-200),boost) or rise<0
			else: ok=reach(gap+8,rise,boost)
			if ok:
				seen.append(j)
				queue.append(j)
	return seen

func surface_of(room: Dictionary, point: Array) -> int:
	var ground: Array=room.ground
	for i in range(ground.size()):
		var r=ground[i]
		if point[0]>=r[0]-2 and point[0]<=r[0]+r[2]+2 and absf(point[1]-r[1])<3: return i
	return -1

func run() -> void:
	var data=GameState.world_data()
	check(data.rooms.has(data.start[0]),"World starts in an existing room")
	var exits_ok=true
	for id in data.rooms:
		var room=data.rooms[id]
		for exit in room.exits:
			exits_ok=exits_ok and (exit.to=="home" or (data.rooms.has(exit.to) and data.rooms[exit.to].spawns.has(exit.spawn)))
	check(exits_ok,"Every exit leads to an existing room and spawn (or home)")
	# Reachability: chests need Foxy Boost at most; every exit and the shrine
	# need no boost, so the main route never traps a child without the ability.
	var route_ok=true
	var chest_ok=true
	var boost_needed=0
	for id in data.rooms:
		var room=data.rooms[id]
		var plain=reachable(room,false)
		var boosted=reachable(room,true)
		for exit in room.exits:
			if exit.has("door"): route_ok=route_ok and surface_of(room,exit.door) in plain
		if room.has("shrine"): route_ok=route_ok and surface_of(room,room.shrine.pos) in plain
		for chest in room.get("chests",[]):
			var s=surface_of(room,chest.pos)
			chest_ok=chest_ok and s in boosted
			if not s in plain: boost_needed+=1
	check(route_ok,"Doors, edges and the ability shrine are reachable without Foxy Boost")
	check(chest_ok and boost_needed>=2,"Every toy-part chest is reachable, and at least two need Foxy Boost (revisit loop)")

	var folder="user://world-tests/"+str(Time.get_ticks_usec())
	var main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory=folder
	root.size=Vector2i(844,390)
	root.add_child(main)
	await frames()
	main.game.adopt("Foxy")
	main.game.set_preference("reduced_motion",true)
	main.show_world()
	await frames(10)
	var world: MeadowWorld=main.active_world
	check(is_instance_valid(world) and world.room_id=="meadow_fields" and world.player.is_on_floor(),"Green Meadows opens in Meadow Fields with the child on the ground")
	check(world.content.get_node("Parallax")!=null and world.content.get_node("Foreground").z_index>world.player.z_index,"Background and foreground parallax layers frame the actors")
	check(main.adventure_ui!=null and main.adventure_title()=="Meadow Fields","Adventure HUD shows the current room")
	var coins_before=main.game.state.coins
	var first=data.rooms.meadow_fields.coins[0]
	world.player.reset_to(Vector2(first[0],first[1]+15))
	await frames(3)
	world.player.reset_to(Vector2(first[0],first[1]+15))
	await frames(3)
	check(main.game.state.coins==coins_before+1,"A coin is collected once, not on every frame")
	world.player.reset_to(Vector2(1990,288))
	Input.action_press("move_right")
	await frames(12)
	Input.action_release("move_right")
	await frames(4)
	check(world.room_id=="river_crossing" and world.player.position.x<200,"Walking off the right edge enters River Crossing at its west side")
	world.player.reset_to(Vector2(1100,288))
	await frames(3)
	world.near={"kind":"door","data":data.rooms.river_crossing.exits[2]}
	world.use()
	await frames(4)
	check(world.room_id=="hidden_cave","The cave door leads into the Hidden Cave")
	check(world.player.air_jumps==0 and not main.game.has_ability("foxy_boost"),"No Foxy Boost before the shrine")
	world.player.reset_to(Vector2(1240,288))
	await frames(3)
	check(world.near.get("kind","")=="shrine","Standing at the shrine offers it")
	world.use()
	check(main.game.has_ability("foxy_boost") and world.player.air_jumps==1,"Touching the shrine teaches Foxy Boost")
	check(SaveStore.new(folder).load_state().quest_state.world.abilities==["foxy_boost"],"Foxy Boost is saved durably")
	var parts_before=int(main.game.world().parts.get("robot_wheel",0))
	check(main.game.world_open_chest("cave_chest","robot_wheel"),"Opening a chest grants its toy part")
	check(not main.game.world_open_chest("cave_chest","robot_wheel") and int(main.game.world().parts.robot_wheel)==parts_before+1,"A chest cannot grant its part twice")
	check(SaveStore.new(folder).load_state().quest_state.world.parts.get("robot_wheel",0)==1,"The toy part survives a fresh load")
	var bad=main.game.state.duplicate(true)
	bad.quest_state.world.room="nowhere"
	check(not main.game.store.validate(bad),"Save validation rejects an unknown room")
	bad=main.game.state.duplicate(true)
	bad.quest_state.world.parts["dragon_egg"]=1
	check(not main.game.store.validate(bad),"Save validation rejects an unknown toy part")
	# Boost really adds height in the air.
	world.enter("forest_gate","west")
	await frames(6)
	var p=world.player
	Input.action_press("jump")
	await frames(2)
	Input.action_release("jump")
	await frames(10)
	Input.action_press("jump")
	await frames(2)
	# Measured while held: releasing early correctly shortens the hop.
	check(p.velocity.y<-150,"Pressing Jump again in the air boosts the child upward")
	Input.action_release("jump")
	await frames(60)
	check(p.is_on_floor(),"The child lands again after a boost")
	check(world.content.get_children().any(func(n): return n is StaticBody2D and absf(n.position.x-915)<1),"The thorn gate blocks the way while Vine Climb is missing")
	main.game.save()
	main.free()
	await process_frame
	main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory=folder
	root.add_child(main)
	await frames()
	main.show_world()
	await frames(6)
	check(main.active_world.room_id=="forest_gate" and main.active_world.player.air_jumps==1,"Relaunch resumes in the last room with Foxy Boost kept")
	main.free()
	await process_frame
	print("PETOPIA WORLD TESTS: %d checks; %d failures"%[checks,failures.size()])
	quit(1 if failures.size() else 0)
