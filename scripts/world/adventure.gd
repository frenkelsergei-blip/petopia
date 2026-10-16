class_name PicnicAdventure
extends Node2D

signal status(message: String)
signal complete(coins: int)

var game: GameState
var run: Dictionary
@export var LAYOUT: LevelDefinition = preload("res://data/levels/lost_picnic.tres")
var meadow: GrayboxMeadow
var player: Explorer
var companion: Companion
var camera: FollowCamera
var hearts = 3
var cooldown = 0.0
var checkpoint_pos = Vector2(240,288)
var last_safe = Vector2(240,288)
var bridge_body: StaticBody2D
var done = false
var prompt = ""
var resident: PicnicResident
var crates: TrailCrates
var secret_platforms: Array[StaticBody2D] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	run = game.start_run(LAYOUT.level_id)
	if run.is_empty():
		status.emit("The adventure couldn't save its starting point. Return home and try again.")
		set_physics_process(false)
		return
	meadow = GrayboxMeadow.new()
	meadow.definition = LAYOUT
	meadow.reduced_motion = game.state.settings.reduced_motion
	meadow.ground = LAYOUT.ground.duplicate()
	meadow.bridge = run.bridge
	meadow.bridge_progress=1.0 if run.bridge else 0.0
	meadow.secret = run.secret
	meadow.cache_open=run.get("cache_open",false)
	meadow.cache_reward_available=not ("windmill_secret" if LAYOUT.level_id=="W01_L02" else "picnic_secret") in game.state.discovered_ids
	meadow.checkpoint_active=run.checkpoint>=1
	meadow.basket = run.basket
	meadow.pickups = run.pickups
	add_child(meadow)
	for rect in meadow.ground: platform(rect)
	crates=TrailCrates.new()
	crates.game=game
	crates.level_id=LAYOUT.level_id
	add_child(crates)
	if run.bridge: add_bridge()
	if run.secret: reveal_cache_path()
	player = Explorer.new()
	player.position = LAYOUT.checkpoint if run.checkpoint >= 1 else Vector2(240,288)
	add_child(player)
	player.art.reduced_motion = game.state.settings.reduced_motion
	if run.checkpoint >= 1: checkpoint_pos = LAYOUT.checkpoint
	last_safe = checkpoint_pos
	companion = Companion.new()
	companion.leader = player
	companion.position = player.position-Vector2(45,0)
	companion.anchor = checkpoint_pos
	companion.safe_anchors = LAYOUT.safe_anchors
	companion.jump_links = LAYOUT.jump_links
	add_child(companion)
	crates.actors=[player,companion]
	companion.art.child_stage = game.pet().growth_stage != "baby"
	companion.art.collar = game.pet().equipped_items.has("collar")
	companion.art.reduced_motion = game.state.settings.reduced_motion
	if LAYOUT.level_id=="W01_L01":
		resident = PicnicResident.new()
		resident.reduced_motion=game.state.settings.reduced_motion
		resident.position = LAYOUT.arrival-Vector2(40,0)
		add_child(resident)
	camera = FollowCamera.new()
	camera.target=player
	camera.scenery=meadow
	camera.course_width=LAYOUT.world_width
	camera.position = Vector2(320,180)
	camera.limit_left = 0
	camera.limit_right = int(LAYOUT.world_width)
	camera.limit_top = 0
	camera.limit_bottom = 360
	camera.position_smoothing_enabled = false
	add_child(camera)
	status.emit("Moss lost the picnic basket. Follow the flower trail to the right.")

func platform(rect: Rect2) -> StaticBody2D:
	var body = StaticBody2D.new()
	body.position = rect.get_center()
	body.collision_layer = 1
	body.collision_mask = 0
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	return body

func add_bridge() -> void:
	if is_instance_valid(bridge_body): return
	bridge_body = platform(Rect2(LAYOUT.stream.position.x,288,LAYOUT.stream.size.x,8))
	meadow.bridge = true
	meadow.crank_turn+=TAU

func _physics_process(delta: float) -> void:
	if done or not is_instance_valid(player) or crates.placing: return
	cooldown = maxf(0,cooldown-delta)
	player.position.x = clampf(player.position.x,20,LAYOUT.world_width-30)
	meadow.companion_point=companion.position
	meadow.player_point=player.position
	if player.is_on_floor():
		last_safe = player.position
		companion.anchor = last_safe
	if player.position.y>380: recover_player()
	if player.position.x>LAYOUT.checkpoint.x-35 and run.checkpoint==0:
		run.checkpoint = 1
		meadow.marker.activate()
		checkpoint_pos = LAYOUT.checkpoint
		game.queue_checkpoint(run)
		status.emit("Checkpoint! A soft landing if you need it.")
	for i in range(LAYOUT.coin_positions.size()):
		if i in run.pickups: continue
		if (player.position-Vector2(0,15)).distance_to(LAYOUT.coin_positions[i])<20:
			run.pickups.append(i)
			meadow.pickups = run.pickups
			game.queue_checkpoint(run)
	prompt = "Return the basket to Moss on the left." if run.basket else "Find the picnic basket to the right."
	meadow.selected_target = ""
	if absf(player.position.x-LAYOUT.crank.x)<70 and not run.bridge: prompt = "E • Turn the crank to build the bridge"
	elif absf(player.position.x-LAYOUT.discovery.x)<110 and not run.secret:
		prompt = "Buried treasure! Q • Ask Foxy to dig here"
		if cooldown<=0: companion.react(Companion.State.INVESTIGATE,0.2)
	elif absf(player.position.x-LAYOUT.discovery.x)<75 and run.secret and not meadow.cache_open: prompt="E • Open the treasure chest"
	elif absf(player.position.x-LAYOUT.basket.x)<65 and not run.basket: prompt = "E • Pick up the picnic basket"
	elif player.position.x>LAYOUT.return_gate.x-120 and run.basket: prompt = "E • Open the return gate to the picnic"
	elif player.position.x<240 and run.basket: prompt = "E • Share the picnic with Moss"
	elif player.position.distance_to(LAYOUT.arrival)<70 and not run.basket: prompt="E • Talk to Moss about the missing basket"
	if prompt.begins_with("E • Turn"): meadow.selected_target="crank"
	elif prompt.contains("Q •"): meadow.selected_target="discovery"
	elif prompt.contains("Open the treasure"): meadow.selected_target="cache"
	elif prompt.contains("Pick up"): meadow.selected_target="basket"
	elif prompt.contains("return gate"): meadow.selected_target="gate"
	elif prompt.contains("Share the picnic") or prompt.contains("Talk to Moss"): meadow.selected_target="picnic"
	if Input.is_action_just_pressed("interact"): interact()
	if Input.is_action_just_pressed("pet_ability"): ability()
	if Input.is_action_just_pressed("reset_checkpoint"): reset_checkpoint()
	if Input.is_action_just_pressed("recall_pet"): companion.recover()
	queue_redraw()

func recover_player() -> void:
	hearts -= 1
	if hearts<=0:
		hearts = 3
		status.emit("A fresh try! Your adventure progress is safe.")
	else: status.emit("A little splash. Let's try from the checkpoint.")
	player.reset_to(checkpoint_pos)
	camera.snap_to_target()
	companion.anchor = checkpoint_pos-Vector2(35,0)
	companion.recover()

func reset_checkpoint() -> void:
	player.reset_to(checkpoint_pos)
	camera.snap_to_target()
	companion.anchor = checkpoint_pos
	companion.recover()
	status.emit("Back at the checkpoint. Collected items are safe.")

func interact() -> void:
	if done: return
	if open_cache():return
	if player.position.distance_to(LAYOUT.arrival)<70 and not run.basket and resident!=null:
		resident.react("wave")
		status.emit("Moss: Could you find my picnic basket? Follow the trail to the right, then bring it back here.")
		return
	if absf(player.position.x-LAYOUT.crank.x)<70 and not run.bridge:
		run.bridge = true
		add_bridge()
		meadow.selected_target=""
		game.queue_checkpoint(run)
		status.emit("Stepping planks ready. Across we go!")
	elif absf(player.position.x-LAYOUT.basket.x)<65 and not run.basket:
		run.basket = true
		meadow.basket = true
		meadow.selected_target=""
		game.queue_checkpoint(run)
		status.emit("The basket is safe! Open the nearby return gate.")
	elif player.position.x>LAYOUT.return_gate.x-120 and run.basket:
		player.reset_to(Vector2(220,288))
		camera.snap_to_target()
		companion.anchor = Vector2(250,288)
		companion.recover()
	elif player.position.x<240 and run.basket:
		var coins = game.finish_run(run)
		if coins>=0:
			meadow.picnic_delivered=true
			done = true
			meadow.selected_target=""
			player.enabled = false
			if resident!=null:resident.react("celebrate",30)
			companion.react(Companion.State.CELEBRATE,30)
			complete.emit(coins)

func open_cache() -> bool:
	if absf(player.position.x-LAYOUT.discovery.x)>=75 or not run.secret or meadow.cache_open:return false
	run.cache_open=true
	meadow.cache_open=true
	meadow.selected_target=""
	game.queue_checkpoint(run)
	status.emit("Treasure opened! +10 coins at the finish." if meadow.cache_reward_available else "This treasure was collected before. No duplicate bonus.")
	return true

func ability() -> void:
	if cooldown>0:
		status.emit("Foxy is getting ready. Just a moment.")
		return
	if absf(player.position.x-LAYOUT.discovery.x)>110:
		status.emit("Find treasure: approach the gold-marked ground, then Q asks Foxy to dig.")
		return
	if run.secret:
		status.emit("You already found this little treasure.")
		return
	companion.react(Companion.State.ABILITY,1.5)
	run.secret = true
	meadow.secret = true
	reveal_cache_path()
	cooldown = 4
	game.queue_checkpoint(run)
	status.emit("Foxy uncovered a treasure chest! Press Use nearby to open it. The upper trail is also ready.")

func reveal_cache_path() -> void:
	if not secret_platforms.is_empty(): return
	# Optional raised overlook. The uninterrupted lower route always reaches the basket.
	for rect in [Rect2(1950,248,72,8),Rect2(2050,228,72,8),Rect2(2140,228,96,8)]:
		meadow.ground.append(rect)
		secret_platforms.append(platform(rect))

func _draw() -> void:
	if LAYOUT.level_id=="W01_L01" and is_instance_valid(player) and run.get("basket",false):
		var p=player.position-Vector2(9,49)
		draw_rect(Rect2(p,Vector2(18,12)),Color("be9b70"))
		draw_arc(p+Vector2(9,0),5,PI,TAU,12,Color("695949"),1)
