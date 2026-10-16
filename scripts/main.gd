extends Control
## Development harness. Final visual screens await the source-aligned design review.

@export var save_directory = "user://graybox_v1"
@export var automation_mode=false

var game: GameState
var viewport: SubViewport
var world: Node2D
var ui: Control
var toast_label: Label
var toast_time = 0.0
var screen = ""
var active_adventure: PicnicAdventure
var active_ball: BallGame
var throw_button: Button
var active_lab: MovementLab
var lab_meter: ProgressBar
var lab_status: Label
var next_after_adoption: Callable
var toast_panel: Panel
var home: HomeArt
var coin_label: Label
var prompt_label: Label
var bars: Dictionary = {}
var pause_panel: Panel
var bag_panel: Panel
var mode_label: Label
var placement_ui: Control
var portrait_ui: PortraitInterface
var main_menu: Control
var adoption_screen: Control
var pet_stage_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	var services = Node.new()
	services.name = "AppServices"
	add_child(services)
	game = GameState.new(save_directory)
	game.name = "GameState"
	services.add_child(game)
	game.feedback.connect(notify)
	var container = SubViewportContainer.new()
	container.name = "WorldViewport"
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.stretch_shrink = 1
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	viewport = SubViewport.new()
	WorldRender.configure(viewport,Vector2i(640,360))
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.handle_input_locally = false
	container.add_child(viewport)
	show_menu()
	portrait_ui=PortraitInterface.new()
	portrait_ui.app=self
	portrait_ui.name="PortraitInterface"
	add_child(portrait_ui)
	if game.store.recovered: notify("Your backup brought your progress back safely.")
	get_tree().auto_accept_quit = false
	if "--river-art-test" in OS.get_cmdline_user_args(): call_deferred("show_river_art_test")

func _setup_input() -> void:
	var keys = {"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"jump":[KEY_SPACE],"interact":[KEY_E],"pet_ability":[KEY_Q],"companion_menu":[KEY_TAB],"adventure_bag":[KEY_B],"pause":[KEY_ESCAPE],"reset_checkpoint":[KEY_R],"recall_pet":[KEY_F]}
	var pads = {"move_left":JOY_BUTTON_DPAD_LEFT,"move_right":JOY_BUTTON_DPAD_RIGHT,"jump":JOY_BUTTON_A,"interact":JOY_BUTTON_X,"pet_ability":JOY_BUTTON_B,"companion_menu":JOY_BUTTON_Y,"pause":JOY_BUTTON_START}
	for action in keys:
		if not InputMap.has_action(action): InputMap.add_action(action)
		for key in keys[action]:
			var event = InputEventKey.new()
			event.physical_keycode = key
			if not InputMap.action_has_event(action,event): InputMap.action_add_event(action,event)
		if pads.has(action):
			var joy = InputEventJoypadButton.new()
			joy.button_index = pads[action]
			if not InputMap.action_has_event(action,joy): InputMap.action_add_event(action,joy)
	for action in ["move_left","move_right"]:
		var axis = InputEventJoypadMotion.new()
		axis.axis = JOY_AXIS_LEFT_X
		axis.axis_value = -1.0 if action == "move_left" else 1.0
		if not InputMap.action_has_event(action,axis): InputMap.action_add_event(action,axis)

func _clear(mode: String) -> void:
	if is_instance_valid(placement_ui): placement_ui.cancel()
	if is_instance_valid(active_adventure) and not active_adventure.done and not active_adventure.run.is_empty(): game.queue_checkpoint(active_adventure.run)
	get_tree().paused = false
	TouchControls.release_actions()
	get_viewport().gui_release_focus()
	for child in viewport.get_children():
		child.process_mode = Node.PROCESS_MODE_DISABLED
		viewport.remove_child(child)
		child.queue_free()
	if is_instance_valid(ui):
		remove_child(ui)
		ui.queue_free()
	ui = Control.new()
	ui.name = "Interface"
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	world = Node2D.new()
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	viewport.add_child(world)
	screen = mode
	bars.clear()
	active_adventure = null
	active_ball = null
	throw_button = null
	active_lab = null
	lab_meter = null
	lab_status = null
	home = null
	pause_panel = null
	bag_panel = null
	prompt_label = null
	main_menu = null
	adoption_screen = null
	pet_stage_label = null
	mode_label = null
	if mode in ["adventure","lab","ball"]:
		mode_label=PetUI.label(ui,"ART REVISION · REVIEW BUILD" if ArtStyle.enabled else "GRAYBOX",Vector2(32,24),14,PetUI.INK)
		PetUI.button(ui,"Sandbox",Rect2(870,20,128,52),show_hub)
		PetUI.button(ui,"My Pet",Rect2(1010,20,114,52),show_home)
		PetUI.button(ui,"Pause",Rect2(1138,20,114,52),toggle_pause)
	elif mode not in ["menu","adoption"]:
		PetUI.panel(ui,Rect2(24,20,1232,80))
		PetUI.label(ui,"PETOPIA / SANDBOX",Vector2(48,26),28,PetUI.INK)
		mode_label=PetUI.label(ui,"ART REVISION · REVIEW BUILD" if ArtStyle.enabled else "GRAYBOX · MOVEMENT, CARE & COOPERATION",Vector2(49,66),13,PetUI.INK)
		PetUI.button(ui,"Main menu" if mode=="hub" else "Sandbox",Rect2(630,34,150,52),show_menu if mode=="hub" else show_hub)
		PetUI.button(ui,"My Pet",Rect2(790,34,152,52),show_home)
		PetUI.button(ui,"Progress",Rect2(952,34,128,52),show_progress)
		PetUI.button(ui,"Pause",Rect2(1090,34,140,52),toggle_pause)
	toast_panel=PetUI.panel(ui,Rect2(32,680,1216,32),Color("364c5a"))
	toast_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	toast_label=PetUI.label(toast_panel,"",Vector2(12,2),17,Color("f0f3ef"))
	toast_panel.visible=false
	coin_label = null

func show_menu() -> void:
	_clear("menu")
	next_after_adoption=Callable()
	main_menu=preload("res://scripts/ui/main_menu.gd").new()
	main_menu.app=self
	ui.add_child(main_menu)

func continue_game() -> void:
	if game.state.is_empty():
		next_after_adoption=func(): show_adventure("W01_L01")
		show_home()
	elif not game.state.pending_run.is_empty(): show_adventure(game.state.pending_run.level_id)
	else: show_home()

func show_hub() -> void:
	_clear("hub")
	next_after_adoption=Callable()
	var bg=GrayboxMeadow.new()
	bg.definition=LevelDefinition.new()
	bg.show_labels=false
	bg.ground.append(Rect2(0,288,640,100))
	world.add_child(bg)
	PetUI.label(ui,"Play the mechanics",Vector2(56,135),36)
	var visual_button=PetUI.button(ui,"Visuals: Art pilot" if ArtStyle.enabled else "Visuals: Graybox",Rect2(950,135,274,50),func(): ArtStyle.enabled=not ArtStyle.enabled;show_hub())
	visual_button.tooltip_text="Switch appearance while keeping the same mechanics."
	PetUI.label(ui,"You lead; your companion helps. Start with the lab or choose an adventure.",Vector2(56,188),21,PetUI.INK,1140)
	var cards=[
		["Movement lab","Run, jump, cross a gap, build a bridge, sense treasure and test pet recovery.",show_lab],
		["Adventures","The Lost Picnic, then Windmill Walk: hill jumps, moving platforms and pet teamwork.",show_map],
		["Pet home","Adopt and name Foxy. Try free care, needs, rest, the shop and toy placement.",show_home],
		["Catch the Ball","You throw as the child. Foxy chases, catches and brings the ball back.",show_ball]]
	for i in range(cards.size()):
		var xy=Vector2(56+(i%2)*598,260+int(i/2)*170)
		var p=PetUI.panel(ui,Rect2(xy,Vector2(570,150)))
		PetUI.button(p,cards[i][0],Rect2(16,14,538,52),cards[i][2],i==0)
		PetUI.label(p,cards[i][1],Vector2(20,79),18,PetUI.INK,528)
	PetUI.panel(ui,Rect2(40,608,1200,52))
	PetUI.label(ui,"A/D move · Space jump · E interact · Q ask Foxy to find/dig · B bag · R checkpoint · Esc pause",Vector2(56,622),18)
	PetUI.button(ui,"River art test",Rect2(56,668,1168,48),show_river_art_test)
	if game.store.blocked: notify("Saved progress needs recovery. The movement lab is still available.")

func show_river_art_test() -> void:
	show_lab()
	active_lab.player.reset_to(Vector2(1618,288))
	active_lab.companion.position=Vector2(1580,288)
	active_lab.art_focus=true
	active_lab.checkpoint=Vector2(1618,288)
	active_lab.camera.snap_to_target()
	toast_time=0
	toast_panel.visible=false

func show_lab() -> void:
	_clear("lab")
	active_lab=preload("res://scenes/sandbox/movement_lab.tscn").instantiate()
	active_lab.status.connect(notify)
	world.add_child(active_lab)
	active_lab.meadow.reduced_motion=game.preferences().reduced_motion
	active_lab.player.art.reduced_motion=game.preferences().reduced_motion
	active_lab.companion.art.reduced_motion=game.preferences().reduced_motion
	var controls=TouchControls.new()
	controls.process_mode=Node.PROCESS_MODE_PAUSABLE
	ui.add_child(controls)
	PetUI.panel(ui,Rect2(32,78,420,120))
	prompt_label=PetUI.label(ui,"",Vector2(48,88),18,PetUI.INK,388)
	lab_meter=PetUI.meter(ui,"Course progress",0,Vector2(48,164),388,Color("5f9b9b"))
	lab_status=PetUI.label(ui,"",Vector2(48,208),14,PetUI.INK,420)
	coin_label=PetUI.coin_display(ui,Vector2(980,119),"Practice coins")
	PetUI.button(ui,"Block / unblock pet",Rect2(980,210,220,48),func(): active_lab.block_companion())
	PetUI.button(ui,"Restart lab",Rect2(980,268,220,48),func():
		if is_instance_valid(active_lab) and active_lab.art_focus: show_river_art_test()
		else: show_lab())

func show_home() -> void:
	if game.state.is_empty():
		show_adoption()
		return
	_clear("home")
	home = preload("res://scenes/pet_home/pet_home.tscn").instantiate()
	home.state = game
	world.add_child(home)
	if game.state.is_empty():
		show_adoption()
		return
	PetUI.panel(ui,Rect2(32,126,320,432))
	PetUI.label(ui,game.pet().name,Vector2(54,139),30)
	pet_stage_label=PetUI.label(ui,game.pet().growth_stage.capitalize()+" · "+str(int(game.pet().bond_xp))+" bond XP",Vector2(54,181),17)
	var index=0
	for entry in [["fullness","Food"],["happiness","Happy"],["energy","Energy"],["cleanliness","Clean"],["health","Health"]]:
		bars[entry[0]]=PetUI.meter(ui,entry[1],game.pet().needs[entry[0]],Vector2(54,218+index*55),270,PetUI.NEED_COLORS[entry[0]])
		index+=1
	coin_label = PetUI.coin_display(ui,Vector2(980,119))
	var actions = [["Feed (free)",func(): game.care("feed"); home.react_to("feed")],["Clean (free)",func(): game.care("clean"); home.react_to("clean")],["Play",show_ball],["Rest / Wake",func(): game.care("sleep"); home.react_to("sleep")]]
	for i in range(actions.size()): PetUI.button(ui,actions[i][0],Rect2(390+i*207,600,193,65),actions[i][1])
	PetUI.button(ui,"Shop",Rect2(390,122,130,52),show_shop)
	PetUI.button(ui,"Decorate",Rect2(530,122,140,52),show_decorate)
	PetUI.button(ui,"Pet",Rect2(680,122,95,52),func(): game.care("pet");home.react_to("pet"))
	PetUI.button(ui,"Water",Rect2(785,122,110,52),func(): game.care("water");home.react_to("water"))
	PetUI.button(ui,"Adventures",Rect2(390,190,240,52),show_map,true)
	PetUI.button(ui,"Pet details",Rect2(645,190,250,52),show_details)
	if game.pet().sleeping: notify("Rest restores 2 energy per minute. You can browse or play while Foxy rests.")

func show_adoption() -> void:
	_clear("adoption")
	adoption_screen=preload("res://scripts/ui/adoption_screen.gd").new()
	adoption_screen.app=self
	ui.add_child(adoption_screen)

func show_map() -> void:
	if game.state.is_empty():
		next_after_adoption=show_map
		show_home()
		return
	show_home()
	var p = PetUI.modal(ui,Rect2(380,195,720,390))
	PetUI.label(p,"Green Meadows",Vector2(26,20),32)
	PetUI.label(p,"Two test adventures · progress saves separately",Vector2(26,73),19)
	PetUI.button(p,"1 · The Lost Picnic",Rect2(26,118,650,58),show_adventure,true)
	PetUI.label(p,"Gentle introduction · 50 coins + pickups + one meal",Vector2(26,181),17)
	PetUI.button(p,"2 · Windmill Walk",Rect2(26,218,650,58),func(): show_adventure("W01_L02"))
	PetUI.label(p,"Hill jumps, moving platforms, Foxy's shortcut · two meals",Vector2(26,280),17)
	PetUI.button(p,"Back",Rect2(26,325,650,48),show_home)

func show_adventure(level_id: String = "W01_L01") -> void:
	if game.state.is_empty():
		next_after_adoption=func(): show_adventure(level_id)
		show_home()
		return
	_clear("adventure")
	active_adventure = (load("res://scenes/adventures/windmill_walk.tscn") if level_id=="W01_L02" else preload("res://scenes/adventures/lost_picnic.tscn")).instantiate()
	active_adventure.game = game
	active_adventure.status.connect(notify)
	active_adventure.complete.connect(func(_coins): show_adventure_result(level_id))
	world.add_child(active_adventure)
	var controls=TouchControls.new()
	controls.process_mode=Node.PROCESS_MODE_PAUSABLE
	ui.add_child(controls)
	PetUI.panel(ui,Rect2(32,80,420,124))
	prompt_label=PetUI.label(ui,"",Vector2(48,88),18,PetUI.INK,388)
	coin_label=PetUI.coin_display(ui,Vector2(980,80),"Run coins")
	PetUI.button(ui,"Bag · B",Rect2(980,166,220,50),toggle_bag)

func toggle_bag() -> void:
	if is_instance_valid(placement_ui):
		placement_ui.cancel()
		return
	if is_instance_valid(bag_panel):
		bag_panel.queue_free()
		bag_panel=null
		get_tree().paused=false
		TouchControls.release_actions()
		return
	if not is_instance_valid(active_adventure) or is_instance_valid(pause_panel): return
	TouchControls.release_actions()
	get_tree().paused=true
	bag_panel=PetUI.modal(ui,Rect2(380,180,600,440))
	PetUI.label(bag_panel,"Your adventure bag",Vector2(25,18),30)
	PetUI.label(bag_panel,"Reusable crates: %d free / %d owned\nMeals for home: %d\nChoose where to place crates, then jump on them.\nPack them to try another arrangement."%[game.available_crates(),int(game.state.inventory.get("trail_crate",0)),int(game.state.inventory.get("berry_bowl",0))],Vector2(25,77),21,PetUI.INK,550)
	var build=PetUI.button(bag_panel,"Place a crate",Rect2(25,220,550,52),func():
		toggle_bag()
		placement_ui=preload("res://scripts/ui/crate_placement.gd").new()
		placement_ui.app=self
		add_child(placement_ui),true)
	build.disabled=game.available_crates()<=0
	PetUI.button(bag_panel,"Pack all placed crates",Rect2(25,285,550,52),func(): game.pack_trail_crates();toggle_bag())
	PetUI.button(bag_panel,"Back · B",Rect2(25,350,550,52),toggle_bag)

func show_ball() -> void:
	if game.state.is_empty():
		next_after_adoption=show_ball
		show_home()
		return
	_clear("ball")
	active_ball = preload("res://scenes/minigames/catch_the_ball.tscn").instantiate()
	active_ball.game = game
	active_ball.updated.connect(notify)
	active_ball.finished.connect(func(catches,throws): result("Lovely time together","%d catches in %d throws\n+10 happiness and bond earned. Saved."%[catches,throws],show_ball))
	world.add_child(active_ball)
	var overlay=preload("res://scripts/world/ball_overlay.gd").new()
	overlay.activity=active_ball
	world.add_child(overlay)
	PetUI.panel(ui,Rect2(32,80,560,124))
	PetUI.label(ui,"Home garden · Catch the Ball",Vector2(48,88),26)
	PetUI.label(ui,"You throw with Space / E. Aim in the gold band; Foxy catches automatically.",Vector2(48,136),18,PetUI.INK,520)
	var aim=ThrowMeter.new()
	aim.activity=active_ball
	aim.position=Vector2(32,600)
	aim.size=Vector2(500,64)
	ui.add_child(aim)
	throw_button=PetUI.button(ui,"Throw · Space",Rect2(548,600,260,64),func(): active_ball.throw_ball(),true)

func show_adventure_result(level_id: String) -> void:
	# finish_run publishes this receipt only after the reward transaction is durable.
	var reward=game.state.quest_state.last_completion
	TouchControls.release_actions()
	var p=PetUI.modal(ui,Rect2(320,106,640,540))
	p.name="AdventureResult"
	PetUI.label(p,"Adventure complete!",Vector2(28,20),32)
	PetUI.label(p,"Moss has the basket back. Time for a picnic together!" if level_id=="W01_L01" else "The food delivery reached the windmill. Your friends are ready for a feast!",Vector2(28,70),21,PetUI.INK,580)
	var coin=TextureRect.new()
	coin.texture=load(PetUI.COIN_PATH)
	coin.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	coin.position=Vector2(28,138)
	coin.size=Vector2(46,46)
	p.add_child(coin)
	PetUI.label(p,"+%d coins"%reward.total_coins,Vector2(88,144),28)
	PetUI.label(p,"%d mission + %d collected + %d treasure"%[reward.base_coins,reward.pickup_coins,reward.discovery_coins],Vector2(28,198),19)
	var food=ItemVisual.new()
	food.item_id="berry_bowl"
	food.position=Vector2(51,260)
	food.scale=Vector2(1.7,1.7)
	p.add_child(food)
	PetUI.label(p,"+%d Berry bowl%s for %s"%[reward.meals,"s" if reward.meals>1 else "",game.pet().name],Vector2(88,241),22)
	PetUI.label(p,"+15 bond XP · A little closer, together",Vector2(28,298),20)
	PetUI.label(p,("New keepsake: " if reward.new_keepsake else "Keepsake already in your collection: ")+("Picnic sticker" if level_id=="W01_L01" else "Windmill badge"),Vector2(28,336),19,PetUI.INK,580)
	PetUI.label(p,"Saved · Wallet: %d coins · Meals are available at home in Shop."%reward.wallet_after,Vector2(28,380),18,PetUI.INK,580)
	PetUI.button(p,"My Pet",Rect2(28,465,280,56),show_home,true)
	PetUI.button(p,"Play again",Rect2(326,465,286,56),func(): show_adventure(level_id))

func result(title: String, description: String, replay: Callable) -> void:
	var p=PetUI.modal(ui,Rect2(380,180,550,310))
	PetUI.label(p,title,Vector2(25,20),30)
	PetUI.label(p,description,Vector2(25,84),22,PetUI.INK,500)
	PetUI.button(p,"Home",Rect2(25,222,240,60),show_home,true)
	PetUI.button(p,"Play again",Rect2(280,222,240,60),replay)

func show_shop() -> void:
	show_home()
	var p=PetUI.modal(ui,Rect2(377,194,760,360))
	PetUI.label(p,"Little joys for your home",Vector2(25,17),28)
	var items=[]
	for definition in ItemCatalog.ITEMS: items.append([definition.item_id,definition.display_name,definition.price])
	for i in range(items.size()):
		var item=items[i]
		var owned=int(game.state.inventory.get(item[0],0))
		var icon=ItemVisual.new()
		icon.item_id=item[0]
		icon.position=Vector2(47,94+i*70)
		icon.scale=Vector2(1.8,1.8)
		p.add_child(icon)
		PetUI.label(p,"%s · %d coins · owned %d"%[item[1],item[2],owned],Vector2(82,75+i*70),18)
		var b=PetUI.button(p,"Buy",Rect2(515,68+i*70,100,52),func():
			if game.purchase(item[0],GameState.event_id("purchase")):
				show_shop()
				notify("Added to your bag. Choose Place to put the ball in your room." if item[0]=="ball_sun" else "Added to your bag. Choose Use to enjoy it."))
		b.disabled=game.state.coins<item[2] or (item[0]!="berry_bowl" and owned>0)
		if owned>0:
			PetUI.button(p,"Place" if item[0]=="ball_sun" else "Use",Rect2(625,68+i*70,100,52),func():
				if item[0]=="berry_bowl":
					if game.use_berries():
						show_home()
						home.react_to("feed")
				elif item[0]=="blue_collar": game.equip_collar();show_home()
				else: show_decorate())
	PetUI.button(p,"Back",Rect2(25,290,700,48),show_home)

func show_decorate() -> void:
	show_home()
	var p=PetUI.modal(ui,Rect2(377,185,790,208))
	PetUI.label(p,"Place your ball · choose a floor spot, then confirm",Vector2(24,15),24)
	if game.state.inventory.get("ball_sun",0)<1:
		PetUI.label(p,"Find the ball in the shop. Your care areas are always free.",Vector2(24,70),20)
		PetUI.button(p,"Back",Rect2(24,126,730,54),show_home)
		return
	for i in range(3): PetUI.button(p,"Spot %d"%(i+1),Rect2(24+i*142,65,130,52),func(): home.toy_preview=i)
	PetUI.button(p,"Confirm",Rect2(24,131,190,52),func():
		if home.toy_preview>=0 and game.place_toy(home.toy_preview):
			show_home()
			home.react_to("toy")
			notify("Your ball is in the room. Foxy will approach and play with it."),true)
	PetUI.button(p,"Cancel",Rect2(228,131,190,52),show_home)
	PetUI.button(p,"Remove to bag",Rect2(432,131,320,52),func():
		if game.place_toy(-1): show_home())

func show_progress() -> void:
	_clear("progress")
	var p=PetUI.panel(ui,Rect2(70,128,1140,530))
	PetUI.label(p,"Development progress",Vector2(25,16),30)
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://docs/progress.json"))
	for i in range(data.phases.size()):
		var phase=data.phases[i]
		var finished=phase.tasks.filter(func(t): return t.status=="done").size()
		PetUI.meter(p,"%s · %s · %d/%d outcomes"%[phase.name,phase.title,finished,phase.tasks.size()],100.0*finished/phase.tasks.size(),Vector2(25,80+i*73),1090)
	PetUI.label(p,"Now: "+data.current,Vector2(25,387),19,PetUI.INK,1080)
	PetUI.button(p,"Open full tracker",Rect2(25,464,1090,48),func(): OS.shell_open(ProjectSettings.globalize_path("res://docs/progress.html")))

func toggle_pause() -> void:
	if screen=="menu":
		main_menu.toggle_settings()
		return
	if is_instance_valid(placement_ui): placement_ui.cancel()
	if is_instance_valid(bag_panel):
		toggle_bag()
		return
	if is_instance_valid(pause_panel):
		pause_panel.queue_free()
		pause_panel=null
		get_tree().paused=false
		TouchControls.release_actions()
		get_viewport().gui_release_focus()
		return
	TouchControls.release_actions()
	get_tree().paused=true
	if not game.state.is_empty(): game.queue_save()
	pause_panel=PetUI.modal(ui,Rect2(425,140,430,430))
	PetUI.label(pause_panel,"A little pause",Vector2(25,20),30)
	PetUI.button(pause_panel,"Resume",Rect2(25,90,380,56),toggle_pause,true).grab_focus()
	PetUI.button(pause_panel,"Reduced motion: toggle",Rect2(25,160,380,56),func():
		game.set_preference("reduced_motion",not game.preferences().reduced_motion))
	var visual=PetUI.button(pause_panel,"Visuals: Art pilot" if ArtStyle.enabled else "Visuals: Graybox",Rect2(25,230,380,56),func():
		ArtStyle.enabled=not ArtStyle.enabled
		for b in pause_panel.find_children("*","Button",true,false):
			if b.text.begins_with("Visuals:"): b.text="Visuals: Art pilot" if ArtStyle.enabled else "Visuals: Graybox")
	visual.tooltip_text="Only rendering changes; your level and tools stay in place."
	PetUI.button(pause_panel,"Sandbox",Rect2(25,300,380,56),show_hub)
	PetUI.button(pause_panel,"Main menu",Rect2(25,366,380,52),show_menu)

func notify(message: String) -> void:
	if is_instance_valid(toast_label):
		toast_label.text=message
		toast_panel.visible=true
	toast_time=7.0

func _process(delta: float) -> void:
	if is_instance_valid(mode_label): mode_label.text="ART REVISION · REVIEW BUILD" if ArtStyle.enabled else "GRAYBOX · MOVEMENT, CARE & COOPERATION"
	toast_time-=delta
	if toast_time<=0 and is_instance_valid(toast_panel): toast_panel.visible=false
	if game!=null and not game.state.is_empty():
		if is_instance_valid(pet_stage_label): pet_stage_label.text=game.pet().growth_stage.capitalize()+" · "+str(int(game.pet().bond_xp))+" bond XP"
		for key in bars:
			if is_instance_valid(bars[key]): bars[key].value=game.pet().needs[key]
		if is_instance_valid(coin_label):
			coin_label.text=str(active_adventure.run.get("pickups",[]).size()) if is_instance_valid(active_adventure) else (str(active_lab.meadow.pickups.size()) if is_instance_valid(active_lab) else str(game.state.coins))
	if is_instance_valid(active_lab):
		prompt_label.text=active_lab.prompt
		coin_label.text=str(active_lab.meadow.pickups.size())
		lab_meter.value=100.0*active_lab.goals.values().count(true)/active_lab.goals.size()
		lab_meter.visible=not active_lab.art_focus
		lab_status.text="Player %s · Pet %s · Pet jumps %d · Recoveries %d · Falls %d"%["grounded" if active_lab.player.is_on_floor() else "airborne",Companion.State.keys()[active_lab.companion.current_state],active_lab.companion.authored_jump_count,active_lab.companion.recovery_count,active_lab.fall_count]
		if active_lab.art_focus: lab_status.text="Focused visual test · other level art is unfinished"
	if is_instance_valid(active_adventure) and is_instance_valid(prompt_label):
		prompt_label.text="%s · Hearts %d / 3\n%s"%[active_adventure.LAYOUT.title,active_adventure.hearts,active_adventure.prompt]
	if is_instance_valid(active_ball) and is_instance_valid(throw_button):
		throw_button.disabled=active_ball.done or ((active_ball.in_flight or active_ball.waiting) and not active_ball.retry_save)
		throw_button.text="Retry save" if active_ball.retry_save else ("Foxy is fetching…" if active_ball.waiting or active_ball.in_flight else "Throw · Space")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if screen=="adoption":
			if is_instance_valid(adoption_screen.modal): adoption_screen.toggle_settings()
			else: show_menu()
		elif is_instance_valid(bag_panel): toggle_bag()
		else: toggle_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("adventure_bag") and is_instance_valid(active_adventure): toggle_bag()
	elif event.is_action_pressed("companion_menu") and not game.state.is_empty() and screen in ["hub","home"]: show_details()

func _notification(what: int) -> void:
	if game==null: return
	if automation_mode and what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_IN,NOTIFICATION_APPLICATION_RESUMED]: return
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		if not game.state.is_empty() and not game.save(): return
		get_tree().quit()
	elif what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:
		TouchControls.release_actions()
		game.suspend()
		if is_instance_valid(ui) and screen not in ["menu","adoption"] and not get_tree().paused: toggle_pause()
	elif what in [NOTIFICATION_APPLICATION_FOCUS_IN,NOTIFICATION_APPLICATION_RESUMED]:
		game.resume_from_background()

func show_details() -> void:
	if game.state.is_empty(): return
	show_home()
	var p=PetUI.modal(ui,Rect2(370,205,650,365))
	PetUI.label(p,"Your companion",Vector2(25,20),30)
	PetUI.label(p,"%s · %s · %.2f real days\nBond %d XP · Care %d XP\nFood %d · Happy %d · Energy %d\nClean %d · Health %d\nBaby 0d → Child 7d → Teen 30d → Adult 60d"%[game.pet().name,game.pet().growth_stage.capitalize(),float(game.pet().elapsed_age_seconds)/PetRules.DAY,game.pet().bond_xp,game.pet().care_xp,game.pet().needs.fullness,game.pet().needs.happiness,game.pet().needs.energy,game.pet().needs.cleanliness,game.pet().needs.health],Vector2(25,80),22,PetUI.INK,600)
	PetUI.button(p,"Back to My Pet",Rect2(25,275,600,60),show_home,true)
