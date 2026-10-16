extends SceneTree
## Boundary tests plus continuous-input runs, rather than teleport-only smoke checks.
var checks=0
var failures: Array[String]=[]
var utc=5000000.0
var monotonic=100.0

func _initialize() -> void: call_deferred("run")
func check(value: bool, note: String) -> void:
	checks+=1
	if not value:
		failures.append(note)
		push_error(note)
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func release_all() -> void:
	for action in ["move_left","move_right","jump","interact","pet_ability"]: Input.action_release(action)

func play_picnic(main: Control) -> bool:
	main.show_adventure()
	await frames(4)
	var level: PicnicAdventure=main.active_adventure
	var jumps: Dictionary={}
	var jump_hold=0
	for tick in range(2400):
		if level.run.basket and level.player.position.x<240: Input.action_release("move_right")
		else: Input.action_press("move_right")
		if jump_hold>0:
			jump_hold-=1
			if jump_hold==0: Input.action_release("jump")
		for trigger in [398,1316,1526,2296,2656]:
			if not jumps.has(trigger) and level.player.is_on_floor() and level.player.position.x>=trigger:
				jumps[trigger]=true
				Input.action_press("jump")
				jump_hold=24
		if tick%10==0:
			if (not level.run.bridge and level.player.position.x>790) or (level.run.secret and not level.run.get("cache_open",false) and absf(level.player.position.x-level.LAYOUT.discovery.x)<65) or level.player.position.x>2995 or (level.run.basket and level.player.position.x<240): Input.action_press("interact")
			if not level.run.secret and level.player.position.x>1845: Input.action_press("pet_ability")
		elif tick%10==2:
			Input.action_release("interact")
			Input.action_release("pet_ability")
		await physics_frame
		if level.done: break
	release_all()
	if not level.done: print("PICNIC ROUTE STOP ",level.player.position," ",level.run)
	return level.done and level.hearts==3

func find_button(parent: Node, caption: String) -> Button:
	for child in parent.get_children():
		if child is Button and child.text==caption: return child
		var found=find_button(child,caption)
		if found!=null: return found
	return null

func run() -> void:
	var main=load("res://scenes/main/main.tscn").instantiate()
	main.save_directory="user://graybox-tests/"+str(Time.get_ticks_usec())
	root.add_child(main)
	main.show_lab()
	await frames(5)
	var lab: MovementLab=main.active_lab
	check(lab.player.get_child(0).shape is CapsuleShape2D,"Player uses a real capsule collider")
	check(lab.companion.get_child(0).shape is CapsuleShape2D,"Companion uses a capsule collider")
	check(lab.player.art is GrayboxActor,"Actor rendering is a graybox capsule")
	# Two independent fingers must move and jump at the same time.
	var x=lab.player.position.x
	for finger in [0,1]:
		var touch=InputEventScreenTouch.new()
		touch.index=finger
		touch.position=Vector2(158,630) if finger==0 else Vector2(1178,630)
		touch.pressed=true
		root.push_input(touch,true)
	await frames(3)
	check(Input.is_action_pressed("move_right") and Input.is_action_pressed("jump"),"Simulated simultaneous touch move+jump held")
	check(lab.player.position.x>x and lab.player.velocity.y<0,"Simulated touch affects physics")
	for finger in [0,1]:
		var touch=InputEventScreenTouch.new()
		touch.index=finger
		touch.position=Vector2(158,630) if finger==0 else Vector2(1178,630)
		touch.pressed=false
		root.push_input(touch,true)
	await frames(2)
	check(not Input.is_action_pressed("move_right") and not Input.is_action_pressed("jump"),"Touch release clears both actions")
	# Coyote time: walk just off a ledge, then jump.
	lab.player.reset_to(Vector2(654,288))
	await frames(3)
	Input.action_press("move_right")
	await frames(9)
	Input.action_press("jump")
	await frames(2)
	check(lab.player.velocity.y<0,"Coyote jump works just after leaving the floor")
	release_all()
	# Buffer a jump a few frames before touching the ground.
	lab.player.reset_to(Vector2(230,273))
	lab.player.velocity.y=150
	await frames(1)
	Input.action_press("jump")
	var jumped=false
	for i in range(9):
		await physics_frame
		jumped=jumped or lab.player.velocity.y< -100
	check(jumped,"Jump buffered before landing fires on contact")
	release_all()
	# Run the entire lab with ordinary continuous physics input.
	main.show_lab()
	await frames(4)
	lab=main.active_lab
	var jumped_at: Dictionary={}
	var jump_hold=0
	var action_hold=0
	for tick in range(2100):
		Input.action_press("move_right")
		if jump_hold>0:
			jump_hold-=1
			if jump_hold==0: Input.action_release("jump")
		if action_hold>0:
			action_hold-=1
			if action_hold==0:
				Input.action_release("interact")
				Input.action_release("pet_ability")
		for trigger in [346,648,1008,1220,1400]:
			if not jumped_at.has(trigger) and lab.player.is_on_floor() and lab.player.position.x>=trigger:
				jumped_at[trigger]=true
				Input.action_press("jump")
				jump_hold=24
		if not lab.meadow.bridge and lab.player.position.x>1635:
			Input.action_press("interact")
			action_hold=2
		if not lab.meadow.secret and lab.player.position.x>2070:
			Input.action_press("pet_ability")
			action_hold=2
		if lab.player.position.x>2435:
			Input.action_press("interact")
			action_hold=2
		await physics_frame
		if lab.goals.finish: break
	release_all()
	check(lab.goals.values().count(true)==6,"Continuous keyboard input completes all six lab mechanics")
	check(lab.fall_count==0,"Authored lab route is traversable without a fall")
	check(lab.companion.authored_jump_count>=2,"Companion takes authored jumps on the real route")
	check(main.game.state.is_empty(),"Movement lab never creates adoption, coins or personal progress")
	# Deliberately block a grounded pet while the player is nearby, not off-camera.
	await frames(100)
	lab.player.reset_to(Vector2(2350,288))
	lab.companion.position=Vector2(2250,288)
	lab.companion.velocity=Vector2.ZERO
	lab.companion.safe_trail.clear()
	await frames(4)
	lab.block_companion()
	var recoveries=lab.companion.recovery_count
	# The player may overlap the pet when the enclosure is created.
	lab.player.reset_to(lab.companion.position)
	var blocked_start=lab.player.position.x
	Input.action_press("move_right")
	await frames(90)
	release_all()
	check(lab.player.position.x>blocked_start+150,"Pet enclosure cannot trap an overlapping player")
	await frames(90)
	check(lab.companion.recovery_count>recoveries,"Blocked companion recovers within the stuck timeout plus detection margin")
	check(lab.companion.valid_anchor(lab.companion.position),"Recovered pet is on validated clear ground")
	# Focus loss/resume uses one offline interval and does not duplicate it.
	main.game.clock_utc=func(): return utc
	main.game.clock_monotonic=func(): return monotonic
	main.game.set_process(false)
	check(main.game.adopt("Clock Test"),"Adopt isolated clock fixture")
	var original_age=main.game.pet().elapsed_age_seconds
	main.game._process(9999)
	check(main.game.pet().elapsed_age_seconds==original_age,"Frame delta cannot bypass real elapsed age")
	monotonic+=2
	utc+=2
	main.game._process(0)
	check(main.game.pet().elapsed_age_seconds==original_age+2,"Session age follows the injected monotonic clock")
	var age=main.game.pet().elapsed_age_seconds
	main.game.suspend()
	main.game._process(10)
	check(main.game.pet().elapsed_age_seconds==age,"Inactive process cannot apply pretend session time")
	utc+=3600
	monotonic+=3600
	main.game.resume_from_background()
	check(main.game.pet().elapsed_age_seconds==age+3600,"Resume reconciles background elapsed time")
	main.game.resume_from_background()
	check(main.game.pet().elapsed_age_seconds==age+3600,"Repeated resume does not duplicate time")
	check(await play_picnic(main),"Complete the entire Lost Picnic using continuous keyboard actions without falls")
	var first_balance=main.game.state.coins
	check(first_balance>=60 and "picnic_secret" in main.game.state.discovered_ids,"Adventure commits completion and discovery rewards")
	check(await play_picnic(main),"Complete a second ordinary outing for the 100-coin toy")
	check(main.game.state.coins-first_balance<=70,"Replay cannot duplicate the unique discovery bonus")
	main.show_shop()
	var buy_buttons: Array[Button]=[]
	for node in main.ui.find_children("*","Button",true,false):
		if node.text=="Buy": buy_buttons.append(node)
	check(buy_buttons.size()==3 and not buy_buttons[1].disabled,"Toy purchase becomes affordable in the real shop")
	if buy_buttons.size()==3: buy_buttons[1].pressed.emit()
	check(main.game.state.inventory.get("ball_sun",0)==1,"Shop button buys the intended item")
	main.show_decorate()
	find_button(main.ui,"Spot 1").pressed.emit()
	check(main.home.toy_preview==0,"Placement slot button previews the toy")
	find_button(main.ui,"Confirm").pressed.emit()
	check(main.game.state.room_layout.size()==1 and main.game.state.room_layout[0].slot==0,"Confirmation persists the placed toy")
	var reloaded=SaveStore.new(main.save_directory).load_state()
	check(reloaded.inventory.get("ball_sun",0)==1 and reloaded.room_layout.size()==1,"Earned item and placement survive a fresh load")
	# The child controls throwing; the pet follows the flight automatically.
	main.show_ball()
	await frames(3)
	var ball: BallGame=main.active_ball
	check(is_instance_valid(ball.child) and ball.child.kind=="child","Ball game has a visible player character")
	await frames(100)
	check(ball.throws==0 and ball.practice and not ball.in_flight,"Waiting for a child throw cannot cause an automatic miss")
	var child_x=ball.child.position.x
	var pet_x=ball.foxy.position.x
	Input.action_press("move_right")
	await frames(20)
	release_all()
	check(ball.child.position.x>child_x and ball.foxy.position.x==pet_x,"Movement controls the child, never the pet")
	ball.aim_time=0
	check(not ball.in_throw_zone(),"Short aim lies outside the pet play area")
	ball.aim_time=PI/(2*1.7)
	check(ball.in_throw_zone(),"Gold band corresponds to a reachable pet catch")
	check(ball.throw_ball() and not ball.throw_ball(),"One child input launches one ball; flight rejects duplicate throws")
	main.toggle_pause()
	var phase=ball.phase
	await frames(10)
	check(ball.phase==phase,"Pause freezes the ball flight")
	main.toggle_pause()
	await frames(112)
	check(not ball.in_flight and not ball.practice and ball.bringing_back,"Pet catches the practice throw automatically and returns it")
	for tick in range(300):
		if not ball.waiting: break
		await physics_frame
	ball.aim_time=0
	ball.throw_ball()
	await frames(112)
	check(ball.throws==1 and ball.catches==0,"Out-of-reach throw is a friendly miss without a pet input")
	main.free()
	await frames(2)
	DirAccess.make_dir_recursive_absolute("res://test-results")
	var f=FileAccess.open("res://test-results/graybox.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"checks":checks,"failures":failures,"scope":"Capsule physics; simulated two-finger input; full lab route with ordinary actions; blocked-pet recovery; clock resume; catch-zone geometry. Physical touch and controller devices still untested."},"\t"))
	f.close()
	print("PETOPIA GRAYBOX TESTS: ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
