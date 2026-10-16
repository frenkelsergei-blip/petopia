class_name WindmillAdventure
extends PicnicAdventure
## Level-two exploration prototype. Main path never requires a species ability.

const CRATE_BUNDLE=Vector2(1225,288)
const FOOD_SPOTS=[Vector2(1150,269),Vector2(1900,269),Vector2(3230,269)]
var moving_platforms: Array[AnimatableBody2D]=[]
var platform_time=0.0
var help_pending=false
var help_elapsed=0.0
var dig_elapsed=0.0
var help_count=0
var details: Node2D

func _ready() -> void:
	LAYOUT=preload("res://data/levels/windmill_walk.tres")
	super._ready()
	if run.is_empty(): return
	if run.checkpoint==2:
		checkpoint_pos=Vector2(2350,288)
		player.reset_to(checkpoint_pos)
		camera.snap_to_target()
		companion.position=Vector2(2310,288)
		companion.reset_physics_interpolation()
	if not run.has("gathered"): run.gathered=[]
	meadow.basket=true # This level has food bags and a delivery goal, not a picnic basket.
	meadow.bridge=run.secret
	meadow.bridge_progress=1.0 if run.secret else 0.0
	make_mover(Vector2(1040,252),Vector2(80,12))
	make_mover(Vector2(1265,220),Vector2(72,12))
	if run.secret: add_help_shortcut()
	details=Node2D.new()
	details.draw.connect(draw_details)
	add_child(details)
	status.emit("Windmill Walk: gather three food bags. Try hill jumps and slow platforms, or take the lower trail.")

func make_mover(at: Vector2, size_value: Vector2) -> AnimatableBody2D:
	var body=AnimatableBody2D.new()
	body.position=at
	body.collision_layer=1
	body.collision_mask=0
	var shape=CollisionShape2D.new()
	var rect=RectangleShape2D.new()
	rect.size=size_value
	shape.shape=rect
	body.add_child(shape)
	add_child(body)
	body.draw.connect(func():
		if ArtStyle.enabled:
			body.draw_texture_rect(ArtStyle.prop_texture("platform"),Rect2(-size_value/2,size_value+Vector2(0,3)),false)
		else:
			body.draw_rect(Rect2(-size_value/2,size_value),Color("85b2ae"))
			body.draw_line(-size_value/2,Vector2(size_value.x/2,-size_value.y/2),Color("e4ede6"),2))
	moving_platforms.append(body)
	return body

func add_bridge() -> void:
	# The child crank powers the hill platforms. The lower route remains open.
	meadow.bridge=run.secret

func reveal_cache_path() -> void:
	# Called by the base loader before the moving-platform list exists in the tree.
	pass

func add_help_shortcut() -> void:
	if not is_instance_valid(bridge_body):
		bridge_body=platform(Rect2(2540,288,56,8))
	if moving_platforms.size()<3: make_mover(Vector2(2225,252),Vector2(90,12))
	meadow.secret=true

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if done or run.is_empty() or crates.placing: return
	platform_time+=delta if run.bridge else 0.0
	if moving_platforms.size()>=2:
		moving_platforms[0].position=Vector2(1040+sin(platform_time*0.8)*48,252)
		moving_platforms[1].position=Vector2(1265+sin(platform_time*0.65)*25,220)
	if moving_platforms.size()>=3:
		moving_platforms[2].position=Vector2(2225,232+cos(platform_time*0.8)*24)
	if player.position.x>2315 and run.checkpoint<2:
		run.checkpoint=2
		meadow.marker.position=Vector2(2378,288)
		meadow.marker.active=false
		meadow.marker.activate()
		checkpoint_pos=Vector2(2350,288)
		game.queue_checkpoint(run)
		status.emit("Second checkpoint. The last gap is just ahead.")
	for i in range(FOOD_SPOTS.size()):
		if i not in run.gathered and (player.position-Vector2(0,15)).distance_to(FOOD_SPOTS[i])<28:
			run.gathered.append(i)
			game.queue_checkpoint(run)
			status.emit("Food bag %d / 3. Finish the walk to bring supplies home."%run.gathered.size())
	if help_pending:
		help_elapsed+=delta
		if companion.position.distance_to(LAYOUT.discovery)<23: dig_elapsed+=delta
		if dig_elapsed>=1.0: finish_pet_help()
		elif help_elapsed>8:
			help_pending=false
			companion.finish_help()
			status.emit("Bring Foxy near the buried mechanism and ask again with Q.")
	prompt="Food bags %d / 3 · Explore the flower hill →"%run.gathered.size()
	meadow.selected_target=""
	if help_pending:
		prompt="Foxy is digging up the buried lift switch…"
		meadow.selected_target="discovery"
	elif absf(player.position.x-LAYOUT.discovery.x)<125 and not run.secret:
		prompt="Q • Ask Foxy to dig up the shortcut switch"
		meadow.selected_target="discovery"
	elif absf(player.position.x-LAYOUT.discovery.x)<75 and run.secret and not meadow.cache_open:
		prompt="E • Open the treasure chest"
		meadow.selected_target="cache"
	elif player.position.distance_to(LAYOUT.crank)<75 and not run.bridge:
		prompt="E • Wind the crank to move the hill platforms"
		meadow.selected_target="crank"
	elif player.position.x>3330:
		prompt="E • Deliver the food bags at the windmill" if run.gathered.size()==3 else "Find all three food bags before delivery ←"
		meadow.selected_target="basket"
	if absf(player.position.x-CRATE_BUNDLE.x)<65 and not "windmill_crates" in game.state.discovered_ids:
		prompt="E • Pick up three reusable crates for your adventure bag"
		meadow.selected_target="crate_bundle"
		meadow.contextual_point=CRATE_BUNDLE

	details.queue_redraw()

func interact() -> void:
	if done: return
	if open_cache():return
	if absf(player.position.x-CRATE_BUNDLE.x)<65 and not "windmill_crates" in game.state.discovered_ids:
		game.collect_trail_crates()
		return
	if player.position.distance_to(LAYOUT.crank)<75 and not run.bridge:
		run.bridge=true
		meadow.crank_turn+=TAU
		game.queue_checkpoint(run)
		status.emit("Platforms moving! Ride them for the upper coin trail. The lower trail is also open.")
	elif player.position.x>3330:
		if run.gathered.size()<3:
			status.emit("You have %d / 3 food bags. Check the lower trail for the rest."%run.gathered.size())
			return
		run.basket=true
		if not game.queue_checkpoint(run): return
		var coins=game.finish_run(run)
		if coins>=0:
			done=true
			meadow.selected_target=""
			player.enabled=false
			companion.react(Companion.State.CELEBRATE,30)
			complete.emit(coins)

func ability() -> void:
	if run.secret:
		status.emit("Foxy already uncovered this shortcut. The lift and gap bridge stay open.")
		return
	if help_pending: return
	if absf(player.position.x-LAYOUT.discovery.x)>125:
		status.emit("Q asks Foxy for help. Look for the buried switch and Foxy's dotted clue.")
		return
	help_pending=true
	help_elapsed=0
	dig_elapsed=0
	companion.request_help(LAYOUT.discovery)
	status.emit("Foxy heard you! Watch your companion approach, sniff and dig up the switch.")

func finish_pet_help() -> void:
	help_pending=false
	help_count+=1
	run.secret=true
	run.bridge=true
	companion.finish_help()
	add_help_shortcut()
	game.queue_checkpoint(run)
	status.emit("Foxy uncovered the switch! Bonus lift and gap bridge open; a new cache adds one meal at delivery.")

func draw_details() -> void:
	var font=ThemeDB.fallback_font
	for i in range(FOOD_SPOTS.size()):
		if i in run.gathered: continue
		var p=FOOD_SPOTS[i]
		if ArtStyle.enabled: ArtStyle.draw_prop(details,"food",p+Vector2(0,19),Vector2(24,27))
		else:
			details.draw_rect(Rect2(p-Vector2(9,10),Vector2(18,20)),Color("b8a17a"))
			details.draw_line(p-Vector2(8,5),p+Vector2(8,-5),Color("eee3c4"),2)
			details.draw_string(font,p+Vector2(-8,-18),"FOOD",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("435361"))
	for label in [["HILL TRAIL · JUMP OR TAKE THE LOWER PATH",Vector2(850,175)],["ASK FOXY TO DIG [Q]",Vector2(2110,228)],["DELIVER FOOD [E]",Vector2(3350,220)]]:
		if not ArtStyle.enabled: details.draw_string(font,label[1],label[0],HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("435361"))
	if not "windmill_crates" in game.state.discovered_ids:
		var p=CRATE_BUNDLE
		for i in range(3):
			if ArtStyle.enabled: ArtStyle.draw_prop(details,"crate",p+Vector2(i*12-12,-i%2*10),Vector2(22,22))
			else: details.draw_rect(Rect2(p+Vector2(i*10-15,-22-i%2*8),Vector2(20,20)),Color("c29963"))
		details.draw_rect(Rect2(p+Vector2(-27,-47),Vector2(64,15)),Color("fff3d9"))
		details.draw_string(font,p+Vector2(-23,-36),"Crates [E]",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("324c55"))
	# A readable windmill landmark beyond the last jump.
	var center=Vector2(3440,174)
	details.draw_rect(Rect2(3421,174,38,114),Color("dbbe89") if ArtStyle.enabled else Color("a7b4bd"))
	if ArtStyle.enabled:
		details.draw_rect(Rect2(3421,174,5,114),Color("ad895e"))
		details.draw_rect(Rect2(3436,263,12,25),Color("684b35"))
		details.draw_colored_polygon(PackedVector2Array([Vector2(3415,174),Vector2(3440,147),Vector2(3465,174)]),Color("b86d4a"))
	for i in range(4):
		var direction=Vector2.from_angle(platform_time*0.3+i*PI/2)
		details.draw_line(center,center+direction*46,Color("a67a45") if ArtStyle.enabled else Color("7c929d"),6)
	details.draw_circle(center,6,Color("dfc17b"))
