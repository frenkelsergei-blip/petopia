class_name MovementLab
extends Node2D
## Repeatable, reward-free mechanics course. No adoption or personal save required.

signal status(message: String)
const LAYOUT: LevelDefinition = preload("res://data/levels/movement_lab.tres")
var player: Explorer
var companion: Companion
var meadow: GrayboxMeadow
var camera: FollowCamera
var bridge_body: StaticBody2D
var recovery_block: StaticBody2D
var checkpoint = Vector2(120,288)
var prompt = "Move with A/D or arrows. Space to jump."
var goals = {"move":false,"jump":false,"gap":false,"bridge":false,"sense":false,"finish":false}
var fall_count = 0
var started = false
var art_focus = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	meadow = GrayboxMeadow.new()
	meadow.definition = LAYOUT
	meadow.ground = LAYOUT.ground.duplicate()
	meadow.lab = true
	add_child(meadow)
	for r in LAYOUT.ground: platform(r)
	player = Explorer.new()
	player.position = checkpoint
	add_child(player)
	companion = Companion.new()
	companion.leader = player
	companion.position = Vector2(75,288)
	companion.anchor = checkpoint
	companion.safe_anchors = LAYOUT.safe_anchors
	companion.jump_links = LAYOUT.jump_links
	add_child(companion)
	camera = FollowCamera.new()
	camera.target=player
	camera.scenery=meadow
	camera.course_width=LAYOUT.world_width
	camera.position = Vector2(320,180)
	camera.limit_left = 0
	camera.limit_right = int(LAYOUT.world_width)
	camera.limit_top = 0
	camera.limit_bottom = 360
	add_child(camera)
	status.emit("You lead; Foxy follows. Practice movement and teamwork. This lab does not spend or award coins." if ArtStyle.enabled else "Blue capsule: you. Orange capsule: your companion. This lab does not spend or award coins.")

func platform(rect: Rect2) -> StaticBody2D:
	var body = StaticBody2D.new()
	body.position = rect.get_center()
	body.collision_layer = 1
	body.collision_mask = 0
	var c = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = rect.size
	c.shape = shape
	body.add_child(c)
	add_child(body)
	return body

func _physics_process(_delta: float) -> void:
	player.position.x = clampf(player.position.x,20,LAYOUT.world_width-20)
	meadow.companion_point=companion.position
	meadow.player_point=player.position
	if player.is_on_floor():
		companion.anchor = player.position
		started = true
	goals.move = goals.move or player.position.x>230
	goals.jump = goals.jump or (started and player.velocity.y< -50)
	goals.gap = goals.gap or player.position.x>780
	if player.position.y>390:
		fall_count += 1
		reset_checkpoint()
		status.emit("Safe reset. Keep trying; there is no penalty in the lab.")
	if player.position.x>1930:
		checkpoint = Vector2(1970,288)
		meadow.marker.activate()
	meadow.selected_target=""
	prompt = "Try the low obstacle, then jump the gap. R resets; F recalls the pet."
	if art_focus: prompt="River art test · run and jump across with Foxy. R resets; F recalls the pet."
	if player.position.distance_to(LAYOUT.crank)<70:
		prompt = "E • Close the bridge" if meadow.bridge else "E • Turn the crank to open the bridge"
		meadow.selected_target="crank"
	elif player.position.distance_to(LAYOUT.discovery)<110 and not meadow.secret:
		prompt = "Buried treasure! Q • Ask Foxy to dig here"
		meadow.selected_target="discovery"
		companion.react(Companion.State.INVESTIGATE,0.1)
	elif player.position.distance_to(LAYOUT.discovery)<75 and meadow.secret and not meadow.cache_open:
		prompt="E • Open the practice treasure chest"
		meadow.selected_target="cache"
	elif absf(player.position.x-LAYOUT.basket.x)<65 and not goals.finish:
		prompt = "E • Finish practice at the picnic basket"
		meadow.selected_target="basket"
	for i in range(LAYOUT.coin_positions.size()):
		if i not in meadow.pickups and (player.position-Vector2(0,15)).distance_to(LAYOUT.coin_positions[i])<20: meadow.pickups.append(i)
	if Input.is_action_just_pressed("interact"): interact()
	if Input.is_action_just_pressed("pet_ability"): sense()
	if Input.is_action_just_pressed("reset_checkpoint"): reset_checkpoint()
	if Input.is_action_just_pressed("recall_pet"): companion.recover()
	queue_redraw()

func interact() -> void:
	if player.position.distance_to(LAYOUT.discovery)<75 and meadow.secret and not meadow.cache_open:
		meadow.cache_open=true
		meadow.selected_target=""
		status.emit("Practice chest opened! Adventure chests save rewards for the finish; this lab gives no coins.")
		return
	if player.position.distance_to(LAYOUT.crank)<70:
		if meadow.bridge:
			var occupied=false
			for actor in [player,companion]:
				occupied=occupied or (actor.position.x>LAYOUT.stream.position.x-10 and actor.position.x<LAYOUT.stream.end.x+10)
			if occupied:
				status.emit("Wait until you and Foxy are on the bank before closing the bridge.")
				return
			bridge_body.queue_free()
			bridge_body=null
			meadow.bridge=false
			status.emit("Bridge closed. Use the crank again to open it.")
		else:
			bridge_body=platform(Rect2(LAYOUT.stream.position.x,288,LAYOUT.stream.size.x,8))
			meadow.bridge=true
			goals.bridge=true
			status.emit("Bridge opening. Walk across with your companion.")
		meadow.crank_turn+=TAU
	elif player.position.distance_to(LAYOUT.basket)<70:
		goals.finish=true
		meadow.course_finished=true
		meadow.selected_target=""
		companion.react(Companion.State.CELEBRATE,2)
		status.emit("Course complete! Try the real Lost Picnic next, or replay this lab.")

func sense() -> void:
	if player.position.distance_to(LAYOUT.discovery)>110:
		status.emit("Find treasure: approach the gold-marked ground, then Q asks Foxy to dig.")
		return
	if meadow.secret: return
	meadow.secret=true
	goals.sense=true
	companion.react(Companion.State.ABILITY,1.2)
	status.emit("Foxy dug up the cache! In adventures, this reveals a saved reward or shortcut.")

func reset_checkpoint() -> void:
	player.reset_to(checkpoint)
	camera.snap_to_target()
	companion.anchor=checkpoint
	companion.recover()

func block_companion() -> void:
	if is_instance_valid(recovery_block):
		recovery_block.queue_free()
		recovery_block=null
		status.emit("Recovery blocker removed.")
		return
	# A narrow enclosure traps only the pet. The player stays free to walk onward.
	var point=companion.position
	recovery_block=platform(Rect2(point.x+12,point.y-65,10,66))
	var left=platform(Rect2(point.x-22,point.y-65,10,66))
	recovery_block.collision_layer=8
	left.collision_layer=8
	left.reparent(recovery_block,true)
	status.emit("Pet blocked. Walk onward: it should recover to a safe anchor within two seconds of getting stuck.")

func _draw() -> void:
	if is_instance_valid(recovery_block):
		var p=recovery_block.position
		draw_rect(Rect2(p-Vector2(5,33),Vector2(10,66)),Color("ac8c96"))
		draw_rect(Rect2(p-Vector2(39,33),Vector2(10,66)),Color("ac8c96"))
