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
var level_title: Label
var bag_badge: Panel
var hearts_row: Array[TextureRect]=[]
var minimap: Button
var card: Panel
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
		turn_panel=CareArt.panel(content,Rect2(bounds.get_center()-Vector2(width,height)/2,Vector2(width,height)))
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
	# One line: the room name only, chip sized to its text (never stretched).
	var level=CareArt.frame(content,Rect2(left,top,180,bar))
	level.name="LevelChip"
	PetUI.set_piece(level,"hud_plank")
	PetUI.compose(level,app.adventure_title(),CareArt.icon("map"),"left",18 if bar<50 else 20)
	level_title=level.get_node("Content/Caption")
	fit_chip(level)
	hearts_row.clear()
	if is_instance_valid(app.active_world):
		# Hearts: always visible, right of the room chip.
		for i in range(MeadowWorld.MAX_HEARTS):
			var heart=CareArt.picture(content,"heart",Rect2(level.position.x+level.size.x+8+i*(bar*0.62),top+bar*0.18,bar*0.6,bar*0.6))
			heart.name="Heart%d"%i
			hearts_row.append(heart)
		# Minimap: this room's shape, you, chests and doors. Tap for the area map.
		minimap=Button.new()
		minimap.name="Minimap"
		minimap.tooltip_text="Map"
		minimap.position=Vector2(left,top+bar+8)
		minimap.size=Vector2(minf(150,bounds.size.x*0.2),bar*1.1)
		PetUI.set_piece(minimap,"card","",10.0)
		minimap.pressed.connect(app.toggle_world_map)
		minimap.draw.connect(draw_minimap)
		content.add_child(minimap)
		var map=CareArt.square(content,"world",Rect2(right-bar*3-16,top,bar,bar),app.toggle_world_map)
		map.name="MapButton"
		map.tooltip_text="Map"
	var coins_right=right-bar*(3 if is_instance_valid(app.active_world) else 2)-(24 if is_instance_valid(app.active_world) else 16)
	var coins=CareArt.frame(content,Rect2(coins_right-92,top,92,bar))
	coins.name="RunCoins"
	PetUI.set_piece(coins,"wallet")
	PetUI.compose(coins,"0",ArtTexture.load_texture(PetUI.COIN_PATH),"left",20 if bar<50 else 24)
	wallet=coins.get_node("Content/Caption")
	var bag=CareArt.button(content,"",Rect2(right-bar*2-8,top,bar,bar),app.toggle_bag,"basket")
	bag_badge=CareArt.tag(bag,"0",Rect2(bar*0.55,-6,26,20))
	bag_badge.size=Vector2(26,20)
	(bag_badge.get_meta("compose") as Dictionary).layout="row"
	(bag_badge.get_meta("compose") as Dictionary).points=12
	PetUI.arrange(bag_badge)
	bag_badge.visible=false
	bag.name="Bag"
	bag.tooltip_text="Bag"
	CareArt.button(content,"",Rect2(right-bar,top,bar,bar),app.toggle_pause,"gear")
	var goal_w=minf(360,bounds.size.x*.42)
	var card=CareArt.frame(content,Rect2(right-goal_w,top+bar+6,goal_w,bar*.84))
	card.name="GoalChip"
	PetUI.set_piece(card,"hud_plank")
	PetUI.compose(card," ",CareArt.icon("basket"),"left",14 if bar<50 else 16)
	goal=card.get_node("Content/Caption")
	controls=TouchControls.new()
	controls.button_size=prefs.touch_size
	controls.button_spacing=prefs.touch_spacing
	controls.portrait_bounds=Rect2(left,bounds.end.y-152-prefs.touch_raise,bounds.size.x,152)
	controls.process_mode=Node.PROCESS_MODE_PAUSABLE
	content.add_child(controls)

func _process(_delta: float) -> void:
	if not app.in_adventure(): return
	if is_instance_valid(level_title) and level_title.text!=app.adventure_title():
		level_title.text=app.adventure_title()
		fit_chip(level_title.get_parent().get_parent())
	if is_instance_valid(goal):
		var line=app.adventure_prompt().replace("E •","Use ·").replace("Q •","Find ·")
		if goal.text!=line:
			goal.text=line
			# Long prompts shrink to fit the chip instead of being clipped.
			PetUI.fit_points(goal,goal.size.x,16 if logical_size.y>=450 else 14,11)
	if is_instance_valid(wallet): wallet.text=str(app.adventure_coins())
	if is_instance_valid(app.active_world):
		var world: MeadowWorld=app.active_world
		if is_instance_valid(controls):
			controls.reduced_motion_pref=app.game.preferences().reduced_motion
			for action in world.faces: controls.set_face(action,world.faces[action][0],world.faces[action][1])
		for i in range(hearts_row.size()):
			if is_instance_valid(hearts_row[i]):
				var want=CareArt.icon("heart" if i<world.hearts else "heart_empty")
				if hearts_row[i].texture!=want: hearts_row[i].texture=want
		if is_instance_valid(minimap): minimap.queue_redraw()
		if is_instance_valid(bag_badge):
			var free=app.game.world_crates_free()
			bag_badge.visible=free>0
			var label: Label=bag_badge.get_node("Content/Caption")
			if label.text!=str(free): label.text=str(free)

func draw_minimap() -> void:
	var world: MeadowWorld=app.active_world
	if not is_instance_valid(world) or world.room.is_empty(): return
	var inner=Rect2(8,6,minimap.size.x-16,minimap.size.y-12)
	var size=Vector2(world.room.size[0],world.room.size[1])
	var k=minf(inner.size.x/size.x,inner.size.y/size.y)
	var o=inner.position+(inner.size-size*k)*0.5
	minimap.draw_rect(Rect2(o,size*k),Color(0.55,0.75,0.95,0.45))
	for r in world.rects("ground"):
		minimap.draw_rect(Rect2(o+r.position*k,Vector2(maxf(2,r.size.x*k),3.0)),Color(0.3,0.52,0.22))
	for wat in world.room.get("waters",[]):
		minimap.draw_rect(Rect2(o+Vector2(wat[0],wat[1])*k,Vector2(wat[2],10)*k),Color(0.3,0.6,0.95))
	for exit in world.active_exits():
		var at=Vector2(exit.door[0],exit.door[1]) if exit.has("door") else Vector2(2 if exit.edge=="left" else size.x-2,world.ground_y_at(2 if exit.edge=="left" else size.x-2))
		minimap.draw_circle(o+at*k-Vector2(0,3),2.6,Color(0.25,0.45,0.9))
	for chest in world.room.get("chests",[]):
		if not chest.id in app.game.world().opened: minimap.draw_circle(o+Vector2(chest.pos[0],chest.pos[1])*k-Vector2(0,3),2.6,Color(0.95,0.7,0.15))
	minimap.draw_circle(o+world.player.position*k-Vector2(0,3),3.2,Color(0.9,0.35,0.15))
	minimap.draw_arc(o+world.player.position*k-Vector2(0,3),3.4,0,TAU,12,Color.WHITE,1.0)

## Width = plank ends + icon + text, capped so it never meets the coin pill.
func fit_chip(chip: Control) -> void:
	var label: Label=chip.get_node("Content/Caption")
	var points=label.get_theme_font_size("font_size")
	var spec: Dictionary=chip.get_meta("compose")
	points=int(spec.points) if int(spec.points)>0 else points
	var text_w=label.get_theme_font("font").get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,points).x
	var h=chip.size.y
	var inset=maxf(PetUI.ROW_INSET,roundf(h*.5))
	var icon=2*floorf(clampf(minf(h-22,h*.56),16,48)/2)+8
	chip.size.x=clampf(ceilf(inset*2+icon+text_w+6),120,safe.size.x*0.42)
	PetUI.arrange(chip)

## One-time explanation card, e.g. when a new ability is learned.
func show_card(title: String, text: String, icon="act_jump") -> void:
	if is_instance_valid(card): card.queue_free()
	var w=minf(420,safe.size.x-24)
	card=CareArt.panel(content,Rect2(safe.get_center().x-w*0.5,safe.position.y+70,w,170))
	card.name="AbilityCard"
	CareArt.picture(card,icon,Rect2(22,30,64,64))
	var heading=CareArt.title(card,"New: "+title,Rect2(100,20,w-120,36),24)
	heading.autowrap_mode=TextServer.AUTOWRAP_OFF
	CareArt.title(card,text,Rect2(100,56,w-120,62),16)
	var ok=CareArt.button(card,"Got it",Rect2(w-150,118,128,PetUI.H_HEADER-10),func(): card.queue_free(),"",true)
	ok.name="GotIt"
