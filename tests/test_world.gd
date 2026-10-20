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
## Footing: ground plus crumbling stone and both ends of each log raft.
func footing(room: Dictionary) -> Array:
	var out: Array=room.ground.duplicate()
	for c in room.get("crumbles",[]): out.append(c)
	for m in room.get("movers",[]):
		out.append(m.rect)
		out.append([m.rect[0]+m.to[0],m.rect[1]+m.to[1],m.rect[2],m.rect[3]])
	return out

func reachable(room: Dictionary, boost: bool) -> Array:
	var ground: Array=footing(room)
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
			# A60: a ladder joins the ground at its foot and the ledge at its top
			# (within a short step of either end).
			for l in room.get("ladders",[]):
				var x=float(l[0])
				var step=absf(float(l[4])) if l.size()>4 else 0.0
				var near_a=x>=a[0]-step-12 and x<=a[0]+a[2]+step+12
				var near_b=x>=b[0]-step-12 and x<=b[0]+b[2]+step+12
				var ends=[float(l[1]),float(l[2])]
				if near_a and near_b and absf(a[1]-ends[1])<3 and absf(b[1]-ends[0])<3: ok=true
				if near_a and near_b and absf(a[1]-ends[0])<3 and absf(b[1]-ends[1])<3: ok=true
			if ok:
				seen.append(j)
				queue.append(j)
	return seen

func surface_of(room: Dictionary, point: Array) -> int:
	var ground: Array=footing(room)
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
	var cave_room=data.rooms.hidden_cave
	var key_spot=cave_room.digs.filter(func(d): return d.item=="key")
	check(key_spot.size()==1 and surface_of(cave_room,key_spot[0].pos) in reachable(cave_room,false),"Foxy's golden key spot can be reached without Double Jump")
	var dig_ok=true
	for id in data.rooms:
		for d in data.rooms[id].get("digs",[]): dig_ok=dig_ok and surface_of(data.rooms[id],d.pos) in reachable(data.rooms[id],true)
	check(dig_ok,"Every hidden spot Foxy can find stands on reachable ground")
	var tower=data.rooms.old_tower
	check(surface_of(tower,tower.exits[1].door) in reachable(tower,false),"The tower can be climbed to its top door without Double Jump")
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
	# Context buttons and Foxy's digging.
	world.player.reset_to(Vector2(210,608))
	await frames(4)
	check(world.faces.interact==["Read","act_read"],"Next to a sign the Use button becomes Read")
	world.player.reset_to(Vector2(560,608))
	world.companion.position=Vector2(530,608)
	await frames(4)
	check(world.faces.pet_ability==["Dig","act_dig"],"Where Foxy smells something, Find becomes Dig")
	world.sniff()
	await create_timer(1.2).timeout
	await frames(2)
	check(main.game.world().crates==1 and "fields_crate" in main.game.world().dug,"Foxy digs up a crate into the bag")
	world.sniff()
	await create_timer(1.2).timeout
	check(main.game.world().crates==1,"A spot can only be dug once")
	world.player.art.facing=1
	world.player.reset_to(Vector2(400,608))
	await frames(4)
	check(world.faces.interact[0]!="Place","A crate stays in the bag: Use does not turn into Place by itself")
	world.start_placing()
	await frames(2)
	check(world.faces.interact==["Place","act_place"],"Choosing Place a crate in the bag turns Use into Place")
	world.near={}
	world.use()
	await frames(3)
	var placed: Array=main.game.world().placed.get("meadow_fields",[])
	check(placed.size()==1 and absf(placed[0][0]-426)<1 and absf(placed[0][1]-608)<1 and main.game.world_crates_free()==0,"Place puts the crate on the ground in front of the child")
	world.player.reset_to(Vector2(426,570))
	await frames(30)
	check(world.player.is_on_floor() and absf(world.player.position.y-584)<2,"The child can stand on a placed crate")
	world.player.reset_to(Vector2(400,608))
	await frames(4)
	check(world.faces.interact==["Pick up","act_pick"],"Next to a crate, Use becomes Pick up")
	world.use()
	await frames(2)
	check(main.game.world_crates_free()==1 and main.game.world().placed.is_empty(),"Pick up returns the crate to the bag")
	var bad_crates=main.game.state.duplicate(true)
	bad_crates.quest_state.world.placed={"meadow_fields":[[1,2],[3,4]]}
	check(not main.game.store.validate(bad_crates),"Save validation rejects more placed crates than owned")
	# Challenge: lantern, thorns, hearts, return to the lantern.
	world.player.reset_to(Vector2(460,608))
	await frames(3)
	check("meadow_fields:0" in main.game.world().lit and main.game.world().checkpoint.get("room")=="meadow_fields","Touching a lantern lights it and makes it the return point")
	check(world.hearts==MeadowWorld.MAX_HEARTS,"The child starts with full hearts")
	world.player.reset_to(Vector2(730,590))
	await frames(2)
	check(world.hearts==MeadowWorld.MAX_HEARTS-1,"Thorns cost one heart")
	world.player.reset_to(Vector2(730,590))
	await frames(2)
	check(world.hearts==MeadowWorld.MAX_HEARTS-1,"A short safe moment after a hit: thorns do not drain every frame")
	var crate_count=main.game.world().crates
	world.hurt_until=0.0
	world.hurt("test")
	world.hurt_until=0.0
	world.hurt("test")
	await frames(3)
	check(world.hearts==MeadowWorld.MAX_HEARTS and world.room_id=="meadow_fields" and absf(world.player.position.x-460)<2,"At zero hearts the child returns to the last lantern with hearts refilled")
	check(main.game.world().crates==crate_count and "fields_crate" in main.game.world().dug,"Nothing found is lost when returning to a lantern")
	var hog: Dictionary=world.critters[0]
	hog.x=1200.0
	hog.dir=0.0
	world.player.reset_to(Vector2(1200,588))
	world.player.velocity=Vector2(0,200)
	world.hurt_until=0.0
	await frames(1)
	check(hog.dizzy>0 and world.hearts==MeadowWorld.MAX_HEARTS,"Jumping on the hedgehog makes it curl up instead of hurting the child")
	main.toggle_world_map()
	await frames(3)
	var map_panel=main.native_screen.find_child("WorldMap",true,false)
	check(map_panel!=null and map_panel.find_child("YouAreHere",true,false)!=null and map_panel.find_child("Room_river_crossing",true,false)!=null,"The area map shows the rooms and where you are")
	var jr: Dictionary=main.game.journey()
	check(jr.total==6 and jr.goals.size()==6 and jr.bonus.id=="treasure" and map_panel.find_child("Goal_robot_head",true,false)!=null,"The map lists the six Green Meadows goals and the secret treasure bonus")
	main.toggle_world_map()
	await frames(2)
	check(not get_root().get_tree().paused,"Closing the map resumes play")
	# Pet puzzle: Foxy digs up a lever, the lever opens the secret cellar wall.
	world.player.reset_to(Vector2(1880,470))
	world.companion.position=Vector2(1850,470)
	await frames(3)
	world.sniff()
	await create_timer(1.2).timeout
	await frames(3)
	check("fields_lever_dig" in main.game.world().dug and world.near.get("kind","")=="lever" and world.faces.interact[0]=="Pull","Foxy digs up a hidden lever and Use becomes Pull")
	world.use()
	await frames(2)
	check("fields_wall" in main.game.world().opened and world.active_exits().any(func(e): return e.get("to","")=="windmill_cellar"),"Pulling the lever opens the secret wall to the Windmill Cellar")
	await frames(2)
	world.use()
	await frames(2)
	check(not "fields_wall" in main.game.world().opened,"Pulling the lever again closes the secret wall (switches work both ways)")
	world.use()
	await frames(2)
	check("fields_wall" in main.game.world().opened,"And pulling once more opens it again")
	world.enter("windmill_cellar","door")
	await frames(4)
	var cellar_gate: Dictionary=world.plate_gates.cellar_gate
	check(not cellar_gate.open,"The cellar's stone gate starts closed")
	main.game.world_dig("cellar_crate","crate")
	main.game.world_place_crate("windmill_cellar",Vector2(1095,288))
	world.build_crates()
	world.player.reset_to(Vector2(200,288))
	await frames(3)
	check(cellar_gate.open,"A crate on the pressure plate holds the gate open")
	main.game.world_pick_crate("windmill_cellar",0)
	await frames(3)
	check(not cellar_gate.open,"Taking the crate off closes the gate again")
	# Foxy can sit on the button and hold the gate for you.
	world.player.reset_to(Vector2(1060,288))
	await frames(3)
	# A58: Foxy hops on by itself when you walk up to the button.
	check(world.near.get("kind","")=="plate" and not world.foxy_holding.is_empty() and world.faces.interact[0]=="Come","Next to the button Foxy hops on by itself; Use becomes Come")
	for k in range(120): await physics_frame
	world.player.reset_to(Vector2(1240,288))
	await frames(3)
	check(cellar_gate.open,"Foxy sitting on the button holds the gate open while you walk through")
	world.player.reset_to(Vector2(1060,288))
	await frames(3)
	world.use()
	for k in range(90): await physics_frame
	check(world.foxy_holding.is_empty() and not cellar_gate.open,"Come calls Foxy back and the gate closes")
	world.enter("meadow_fields","home")
	await frames(3)
	# The Lost Picnic quest inside the world.
	world.player.reset_to(Vector2(330,608))
	await frames(3)
	check(world.near.get("kind","")=="npc" and world.faces.interact[0]=="Talk","Next to Moss, Use becomes Talk")
	world.use()
	check("picnic_asked" in main.game.world().opened,"Talking to Moss starts The Lost Picnic")
	check(not main.game.world_finish_picnic(),"The picnic reward needs the basket first")
	main.game.world_flag("picnic_basket")
	var meals=int(main.game.state.inventory.get("berry_bowl",0))
	var wallet=main.game.state.coins
	world.use()
	check("picnic_done" in main.game.world().opened and main.game.state.coins==wallet+25 and int(main.game.state.inventory.berry_bowl)==meals+1,"Bringing the basket back gives the picnic reward once")
	world.use()
	check(main.game.state.coins==wallet+25,"The picnic reward is never given twice")
	# A51: the pet's growth and condition carry into the adventure.
	# A58: upright Foxy; the baby still stands well below the child's 42.
	check(world.companion.art.fox_height()<=20.0,"A baby Foxy is small next to the child")
	main.game.state.pets[0].growth_stage="adult"
	world.enter("meadow_fields","home")
	await frames(3)
	check(world.companion.art.fox_height()>=30.0 and world.smell_range()>200,"An adult Foxy is bigger and smells treasure from farther away")
	main.game.state.pets[0].growth_stage="baby"
	var needs: Dictionary=main.game.state.pets[0].needs
	var food_before=float(needs.fullness)
	main.game.world_tick(120.0)
	check(needs.fullness<food_before and needs.fullness>food_before-3.0,"Exploring slowly makes Foxy hungry")
	needs.energy=5.0
	needs.fullness=60.0
	var saved_abilities=main.game.state.quest_state.world.abilities.duplicate()
	main.game.state.quest_state.world.abilities=["foxy_boost"]
	await frames(2)
	check(world.player.air_jumps==0,"An exhausted Foxy can't share Double Jump")
	var dug_before=main.game.world().dug.size()
	world.player.reset_to(Vector2(2450,608))
	world.companion.position=Vector2(2420,608)
	await frames(2)
	world.sniff()
	await create_timer(1.3).timeout
	check(main.game.world().dug.size()==dug_before,"An exhausted Foxy doesn't dig")
	main.game.world_rest(30.0)
	await frames(2)
	check(world.player.air_jumps==1,"After a rest Foxy helps again")
	needs.fullness=10.0
	needs.energy=80.0
	main.game.state.inventory.berry_bowl=1
	check(main.game.pet_ready_for_adventure()=="hungry","A hungry Foxy is not ready for an adventure")
	check(main.game.use_berries() and main.game.pet_too_weak()=="","A snack from the bag gives Foxy energy for exploring again")
	needs.fullness=80.0
	main.game.state.quest_state.world.abilities=saved_abilities
	# Things to find: food for Foxy, a magic carrot, a key for the tower door.
	var apples=int(main.game.state.inventory.get("apple",0))
	world.player.reset_to(Vector2(1660,312))
	await frames(4)
	check("fields_apple" in main.game.world().opened and int(main.game.state.inventory.get("apple",0))==apples+1,"A found apple goes into the bag as a snack")
	var carrots=int(main.game.world().carrots)
	world.player.reset_to(Vector2(1310,608))
	await frames(3)
	check(main.game.world().carrots==carrots+1 and not world.super_jump,"A jump carrot goes into the bag for later")
	world.use_carrot()
	check(world.super_jump and main.game.world().carrots==carrots,"Eating a carrot from the bag gives one big jump")
	world.super_jump=false
	# Crates you placed come back into the bag when you leave the room.
	main.game.state.quest_state.world.crates=2
	world.player.reset_to(Vector2(600,608))
	await frames(3)
	check(main.game.world_place_crate("meadow_fields",Vector2(600,608)) and main.game.world_crates_free()==1,"A placed crate leaves the bag")
	world.enter("river_crossing","west")
	await frames(3)
	check(main.game.world_crates_free()==2 and not main.game.world().placed.has("meadow_fields"),"Leaving the room brings placed crates back into the bag")
	world.enter("meadow_fields","home")
	await frames(3)
	world.enter("old_tower","door")
	await frames(3)
	var top_exit: Dictionary=data.rooms.old_tower.exits[1]
	check(world.door_locked(top_exit),"The tower's top door starts locked")
	main.game.world_flag("tower_key")
	world.player.reset_to(Vector2(820,216))
	await frames(4)
	check(world.faces.interact[0]=="Open","With the key, the locked door's button says Open")
	world.use()
	await frames(2)
	check(not world.door_locked(top_exit),"The golden key unlocks the tower door for good")
	# Falling in the river: one smooth return to solid ground, away from the edge.
	world.enter("river_crossing","west")
	await frames(3)
	world.player.reset_to(Vector2(470,288))
	await frames(10)
	world.player.reset_to(Vector2(560,250))
	var jumps=0
	var last_pos=world.player.position
	for k in range(90):
		await physics_frame
		if world.player.position.distance_to(last_pos)>40: jumps+=1
		last_pos=world.player.position
	check(jumps==1 and not world.in_water() and world.solid_at(world.player.position.x+18,world.player.position.y),"A fall into the river returns once to firm ground (no back-and-forth)")
	world.enter("old_tower","door")
	await frames(3)
	# Foxy finds things on its own and the guide arrow knows the way.
	world.enter("hidden_cave","door")
	await frames(3)
	world.player.reset_to(Vector2(900,288))
	await frames(4)
	check(not world.found.is_empty() and world.companion.point_target!=Vector2.INF,"Near a hidden spot, Foxy runs to it and points it out")
	var before_key="tower_key" in main.game.world().opened
	main.game.world_dig("tower_key_dig","key")
	check("tower_key" in main.game.world().opened or before_key,"Digging Foxy's key spot gives the golden key")
	world.enter("meadow_fields","home")
	await frames(3)
	var arrow_target: Vector2=world.goal_target()
	check(arrow_target!=Vector2.INF,"The guide arrow always has a target (goal here, or the way out toward it)")
	world.enter("old_tower","door")
	await frames(3)
	# Every place has its own friendly critter.
	var kinds={}
	for id in data.rooms:
		for c in data.rooms[id].get("critters",[]): kinds[c.get("kind","hedgehog")]=id
	check(kinds.has("bat") and kinds.bat=="old_tower" and kinds.has("crab") and kinds.has("frog") and kinds.has("bee"),"Bats in the tower, crabs in the cave, frogs at the river, bees at the forest gate")
	check(String(main.game.world_goal().text)!="" ,"The map always knows the next goal")
	# Fallen to the right of the thorns: safe steps lead back onto the climb.
	var steps=0
	for g in data.rooms.old_tower.ground:
		if g[0]>=650 and int(g[1]) in [612,576,540]: steps+=1
	check(steps>=3,"The tower has safe steps back up on the far side of the thorns")
	# Foxy left far below catches up.
	world.companion.position=Vector2(200,648)
	world.player.reset_to(Vector2(700,216))
	await frames(90)
	check(world.companion.position.distance_to(world.player.position)<80,"Foxy hops up to the child instead of staying behind")
	world.enter("meadow_fields","home")
	await frames(3)
	var coins_before=main.game.state.coins
	var first=data.rooms.meadow_fields.coins[0]
	world.player.reset_to(Vector2(first[0],first[1]+15))
	await frames(3)
	world.player.reset_to(Vector2(first[0],first[1]+15))
	await frames(3)
	check(main.game.state.coins==coins_before+1,"A coin is collected once, not on every frame")
	# A60 (P71a): the ladder up the ivy cliff: climb, step onto the shelf.
	var lad: Array=data.rooms.meadow_fields.ladders[0]
	world.player.reset_to(Vector2(float(lad[0]),float(lad[2])))
	await frames(3)
	Input.action_press("move_up")
	for i in 150:
		await physics_frame
		if not world.player.is_climbing() and world.player.position.y<float(lad[2])-20: break
	Input.action_release("move_up")
	check(world.player.art.puppet==null or world.player.art.puppet.frames_data.sets.has("climb"),"The boy has his climbing frames")
	for i in 40: await physics_frame
	check(world.player.is_on_floor() and absf(world.player.position.y-float(lad[1]))<2,"Climbing the ladder brings the child up onto the cliff shelf")
	world.player.reset_to(Vector2(2790,608))
	Input.action_press("move_right")
	await frames(12)
	Input.action_release("move_right")
	await frames(4)
	check(world.room_id=="river_crossing" and world.player.position.x<200,"Walking off the right edge enters River Crossing at its west side")
	check(world.bridge_locked() and not world.content.get_children().any(func(n): return n is StaticBody2D and absf(n.position.x-710)<1 and absf(n.position.y-292)<1),"River Crossing's bridge is raised until the wheel is turned")
	world.player.reset_to(Vector2(470,288))
	await frames(3)
	check(world.near.get("kind","")=="crank" and world.faces.interact[0]=="Lower","At the wheel, Use becomes Lower")
	world.use()
	await frames(3)
	check(not world.bridge_locked() and "river_bridge" in main.game.world().opened,"Turning the wheel lowers the bridge for good")
	world.player.reset_to(Vector2(1100,288))
	await frames(3)
	world.near={"kind":"door","data":data.rooms.river_crossing.exits[1]}
	world.use()
	await frames(4)
	check(world.room_id=="hidden_cave","The cave door leads into the Hidden Cave")
	check(world.player.air_jumps==0 and not main.game.has_ability("foxy_boost"),"No Foxy Boost before the shrine")
	var crumble: Dictionary=world.crumbles[0]
	world.player.reset_to(Vector2(560,284))
	await frames(100)
	check(crumble.gone>0 or crumble.timer>=0,"Crumbling stone breaks after the child stands on it")
	world.player.reset_to(Vector2(1340,288))
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
	check(world.content.get_children().any(func(n): return n is StaticBody2D and absf(n.position.x-1185)<1),"The thorn gate blocks the way while Vine Climb is missing")
	main.game.save()
	main.free()
	await process_frame
	# A hungry Foxy stays home and the game says why.
	var hungry=load("res://scenes/main/main.tscn").instantiate()
	hungry.automation_mode=true
	hungry.save_directory=folder
	root.add_child(hungry)
	await frames()
	hungry.game.state.pets[0].needs.fullness=5.0
	hungry.show_world()
	await frames(3)
	check(not is_instance_valid(hungry.active_world) and hungry.care_ui.find_child("Notice",true,false)!=null,"A very hungry Foxy stays home with a clear explanation")
	hungry.game.state.pets[0].needs.fullness=80.0
	hungry.game.save()
	hungry.free()
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
