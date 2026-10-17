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
	var card=CareArt.frame(content,Rect2(left,top,minf(420,bounds.size.x-320),78))
	goal=CareArt.title(card,"",Rect2(14,6,card.size.x-28,66),17 if dimensions.y<600 else 20)
	var coins=CareArt.frame(content,Rect2(right-294,top,126,56))
	var coin=TextureRect.new()
	coin.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	coin.texture=ArtTexture.load_texture(PetUI.COIN_PATH)
	coin.position=Vector2(12,10)
	coin.size=Vector2(36,36)
	coin.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.mouse_filter=Control.MOUSE_FILTER_IGNORE
	coins.add_child(coin)
	wallet=CareArt.title(coins,"0",Rect2(58,6,54,44),26)
	CareArt.button(content,"Bag",Rect2(right-160,top,96,56),app.toggle_bag)
	CareArt.button(content,"",Rect2(right-56,top,56,56),app.toggle_pause,"gear")
	controls=TouchControls.new()
	controls.button_size=prefs.touch_size
	controls.button_spacing=prefs.touch_spacing
	controls.portrait_bounds=Rect2(left,bounds.end.y-152-prefs.touch_raise,bounds.size.x,152)
	controls.process_mode=Node.PROCESS_MODE_PAUSABLE
	content.add_child(controls)

func _process(_delta: float) -> void:
	if not is_instance_valid(app.active_adventure): return
	if is_instance_valid(goal):
		goal.text=app.active_adventure.LAYOUT.title+"\n"+app.active_adventure.prompt.replace("E •","Use ·").replace("Q •","Find ·")
	if is_instance_valid(wallet): wallet.text=str(app.active_adventure.run.get("pickups",[]).size())
