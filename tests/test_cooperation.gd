extends SceneTree
var checks=0
var failures: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func check(ok: bool, note: String) -> void:
	checks+=1
	if not ok:
		failures.append(note)
		push_error(note)
func release_all() -> void: TouchControls.release_actions()
func button(parent: Node, caption: String) -> Button:
	for node in parent.find_children("*","Button",true,false):
		if node.text==caption: return node
	return null

func walk(main: Control, with_pet_help: bool) -> WindmillAdventure:
	main.show_adventure("W01_L02")
	await frames(5)
	var level: WindmillAdventure=main.active_adventure
	var jumps={}
	var hold=0
	var requested=false
	for tick in range(3200):
		if with_pet_help and level.player.position.x>2120 and not level.run.secret:
			Input.action_release("move_right")
			if not requested:
				Input.action_press("pet_ability")
				requested=true
			else: Input.action_release("pet_ability")
		else: Input.action_press("move_right")
		if hold>0:
			hold-=1
			if hold==0: Input.action_release("jump")
		for trigger in [398,702,1354,2522,2798,3098]:
			if not jumps.has(trigger) and level.player.is_on_floor() and level.player.position.x>=trigger:
				jumps[trigger]=true
				Input.action_press("jump")
				hold=28
		if tick%10==0:
			if (not level.run.bridge and absf(level.player.position.x-950)<60) or (level.run.secret and not level.run.get("cache_open",false) and absf(level.player.position.x-level.LAYOUT.discovery.x)<65) or level.player.position.x>3350: Input.action_press("interact")
		elif tick%10==2: Input.action_release("interact")
		await physics_frame
		if level.done: break
	release_all()
	if not level.done: print("WINDMILL STOP: ",level.player.position," ",level.run," help=",level.help_pending)
	return level

func run() -> void:
	var main=load("res://scenes/main/main.tscn").instantiate()
	main.save_directory="user://cooperation-tests/"+str(Time.get_ticks_usec())
	root.add_child(main)
	check(main.game.adopt("Team Fox"),"Adopt isolated cooperation fixture")
	# Existing level progress survives switching and reload, including legacy runs without a level ID.
	main.show_adventure()
	await frames(3)
	main.active_adventure.run.pickups=[1,2]
	main.game.checkpoint(main.active_adventure.run)
	var picnic_id=main.active_adventure.run.id
	main.show_adventure("W01_L02")
	await frames(4)
	check(main.active_adventure.run.level_id=="W01_L02","Second level uses a distinct persistent content ID")
	var state=SaveStore.new(main.save_directory).load_state()
	check(state.quest_state.level_runs.W01_L01.id==picnic_id,"Switching levels archives the unfinished picnic durably")
	main.show_adventure()
	await frames(3)
	check(main.active_adventure.run.id==picnic_id and main.active_adventure.run.pickups==[1,2],"Returning to the picnic restores its original pickups and run ID")
	main.show_adventure("W01_L02")
	await frames(4)
	var level: WindmillAdventure=main.active_adventure
	# A real physics rider must move with the powered platform.
	level.player.reset_to(Vector2(950,240))
	level.interact()
	check(level.run.bridge,"Child-operated crank powers the slow platforms")
	var platform=level.moving_platforms[0]
	level.player.reset_to(platform.position-Vector2(0,6))
	await frames(5)
	var before=level.player.position.x
	await frames(65)
	check(level.player.position.x>before+15 and level.player.is_on_floor(),"Moving platform carries an idle capsule with actual physics")
	level.run.bridge=false
	main.game.checkpoint(level.run)
	var meals_before=int(main.game.state.inventory.get("berry_bowl",0))
	level=await walk(main,true)
	check(level.done and level.hearts==3,"Ordinary input completes Windmill Walk without falls")
	if not level.done:
		main.free()
		quit(1)
		return
	check(level.run.gathered.size()==3,"All three food bags are collected before delivery")
	check(level.help_count==1 and level.run.secret and not level.help_pending,"Requested pet approaches and digs before resolving the mechanism")
	check(is_instance_valid(level.bridge_body) and level.moving_platforms.size()==3,"Pet help creates a real gap bridge and bonus lift")
	check("W01_L02" in main.game.state.completed_levels,"Windmill completion is separate from the picnic")
	check(main.game.state.inventory.berry_bowl==meals_before+3,"First cooperative delivery grants two meals plus one new-cache meal")
	var finished_run=level.run.duplicate(true)
	var saved_meals=main.game.state.inventory.berry_bowl
	check(main.game.finish_run(finished_run)==-1 and main.game.state.inventory.berry_bowl==saved_meals,"Reopening completion cannot duplicate supplies")
	level=await walk(main,false)
	check(level.done and level.hearts==3 and not level.run.secret,"Longer main route works without the species ability")
	check(main.game.state.inventory.berry_bowl==saved_meals+2,"Replay gives ordinary supplies without the one-time cache meal")
	var fullness=main.game.pet().needs.fullness
	var meals=main.game.state.inventory.berry_bowl
	main.show_home()
	main.care_ui.choose_care("feed")
	(main.care_ui.find_child("Food_berry_bowl",true,false) as Button).pressed.emit()
	for tick in range(420):
		if not main.home.busy(): break
		await physics_frame
	check(main.game.state.inventory.berry_bowl==meals-1 and main.game.pet().needs.fullness>fullness,"Adventure food can be served from the food picker to feed the pet")
	# Preview/cancel is separate from the saved room, and the pet interacts with the placed object.
	check(main.game.purchase("ball_sun",GameState.event_id("test-buy")),"Adventure coins buy the placeable toy")
	main.show_decorate()
	button(main.ui,"By the bed").pressed.emit()
	check(main.home.toy_preview==1 and main.game.state.room_layout.is_empty(),"Ghost preview never changes the saved room")
	button(main.ui,"Cancel").pressed.emit()
	check(main.game.state.room_layout.is_empty() and main.home.placed_toy_slot()==-1,"Cancel leaves the purchased ball in the bag")
	main.show_decorate()
	button(main.ui,"By the bed").pressed.emit()
	button(main.ui,"Confirm").pressed.emit()
	var saw_play=false
	for tick in range(240):
		await physics_frame
		saw_play=saw_play or main.home.toy_play_time>0
	check(main.home.placed_toy_slot()==1 and saw_play,"Placed ball appears at its room slot and pet automatically plays with it")
	var reloaded=SaveStore.new(main.save_directory).load_state()
	check(reloaded.room_layout[0].slot==1 and reloaded.inventory.berry_bowl==meals-1,"Food use and room customization survive reopening")
	main.free()
	await frames(2)
	var f=FileAccess.open("res://test-results/cooperation.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Native scene mechanics via continuous input: two Windmill routes, real moving-platform rider, pet-directed dig, usable food, archived runs and room preview/commit/reload."},"\t"))
	f.close()
	print("PETOPIA COOPERATION TESTS: ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
