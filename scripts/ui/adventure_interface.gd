class_name AdventureInterface
extends Control
## Full-window landscape play. Portrait guards the same live run, not a reload.
var app: Control
var logical_size=Vector2(1280,720)
var safe=Rect2()
var signature=""
var content: Control
var controls: TouchControls
var goal: Label
var wallet: Label
var turn_panel: Panel
var landscape_ready=false

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func layout(dimensions: Vector2, bounds: Rect2) -> void:
	logical_size=dimensions
	safe=bounds
	var prefs=app.game.preferences()
	var next=str([dimensions,bounds,prefs])
	if next==signature: return
	# Rebuilding controls drops their fingers; the first build has none, and
	# leaving the previous screen already released held input.
	if not signature.is_empty(): TouchControls.release_actions()
	signature=next
	if is_instance_valid(content):
		remove_child(content)
		content.queue_free()
	controls=null
	goal=null
	wallet=null
	content=Control.new()
	content.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(content)
	var image=TextureRect.new()
	image.texture=app.viewport.get_texture()
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.size=dimensions
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	content.add_child(image)
	app.viewport.get_parent().stretch=false
	var world_size=Vector2(360*dimensions.x/dimensions.y,360)
	WorldRender.configure(app.viewport,Vector2i(world_size))
	landscape_ready=dimensions.x>=dimensions.y
	if not landscape_ready:
		var dim=ColorRect.new()
		dim.color=Color(.03,.08,.17,.78)
		dim.size=dimensions
		content.add_child(dim)
		var width=minf(360,bounds.size.x)
		var height=minf(510,bounds.size.y)
		turn_panel=CareArt.frame(content,Rect2(bounds.get_center()-Vector2(width,height)/2,Vector2(width,height)))
		var heading=CareArt.title(turn_panel,"Turn your phone sideways",Rect2(24,24,width-48,86),32)
		heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var message=CareArt.title(turn_panel,"Your adventure is paused.\nRotate to landscape to play with a full view of the trail.",Rect2(24,115,width-48,100),20)
		message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var friends=preload("res://scripts/ui/menu_friends.gd").new()
		friends.reduced_motion=prefs.reduced_motion
		friends.position=Vector2((width-180)/2,220)
		friends.size=Vector2(180,160)
		turn_panel.add_child(friends)
		CareArt.button(turn_panel,"My Pet",Rect2(24,height-126,width-48,56),app.show_home,"paw")
		CareArt.button(turn_panel,"Main menu",Rect2(24,height-64,width-48,56),app.show_menu,"back")
		return
	var left=bounds.position.x
	var top=bounds.position.y
	var right=bounds.end.x
	# V02 HUD: level chip left; coins, bag, settings and the live goal right.
	# Short phone screens get a slimmer bar so the trail stays visible.
	var bar=46.0 if dimensions.y<450 else 56.0
	var level=CareArt.frame(content,Rect2(left,top,minf(240,bounds.size.x*.3),bar))
	level.name="LevelChip"
	CareArt.picture(level,"map",Rect2(8,(bar-30)/2,30,30))
	CareArt.title(level,"Green Meadows",Rect2(46,bar*.08,level.size.x-54,bar*.38),12 if bar<50 else 14)
	CareArt.title(level,app.active_adventure.LAYOUT.title,Rect2(46,bar*.42,level.size.x-54,bar*.5),16 if bar<50 else 19)
	var coins=CareArt.frame(content,Rect2(right-bar*2-142-16,top,142,bar))
	coins.name="RunCoins"
	var coin=TextureRect.new()
	coin.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	coin.texture=ArtTexture.load_texture(PetUI.COIN_PATH)
	coin.position=Vector2(8,(bar-34)/2)
	coin.size=Vector2(34,34)
	coin.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.mouse_filter=Control.MOUSE_FILTER_IGNORE
	coins.add_child(coin)
	wallet=CareArt.title(coins,"0",Rect2(50,0,80,bar*.62),22 if bar<50 else 26)
	var caption=CareArt.title(coins,"Run coins",Rect2(50,bar*.56,84,bar*.38),11 if bar<50 else 12)
	caption.autowrap_mode=TextServer.AUTOWRAP_OFF
	var bag=CareArt.button(content,"",Rect2(right-bar*2-8,top,bar,bar),app.toggle_bag,"")
	bag.name="Bag"
	bag.tooltip_text="Bag"
	CareArt.picture(bag,"basket",Rect2(bar*.14,bar*.1,bar*.72,bar*.72))
	CareArt.button(content,"",Rect2(right-bar,top,bar,bar),app.toggle_pause,"gear")
	var goal_w=minf(360,bounds.size.x*.42)
	var card=CareArt.frame(content,Rect2(right-goal_w,top+bar+6,goal_w,bar*.8))
	card.name="GoalChip"
	CareArt.picture(card,"basket",Rect2(6,(bar*.8-28)/2,28,28))
	goal=CareArt.title(card,"",Rect2(40,0,goal_w-48,bar*.8),13 if bar<50 else 16)
	controls=TouchControls.new()
	controls.button_size=prefs.touch_size
	controls.button_spacing=prefs.touch_spacing
	controls.portrait_bounds=Rect2(left,bounds.end.y-152-prefs.touch_raise,bounds.size.x,152)
	controls.process_mode=Node.PROCESS_MODE_PAUSABLE
	content.add_child(controls)

func _process(_delta: float) -> void:
	if not is_instance_valid(app.active_adventure): return
	if is_instance_valid(goal):
		goal.text=app.active_adventure.prompt.replace("E •","Use ·").replace("Q •","Find ·")
	if is_instance_valid(wallet): wallet.text=str(app.active_adventure.run.get("pickups",[]).size())
