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
var portrait: TextureRect
var portrait_frames: Array[AtlasTexture]=[]
## Held so the meter art is not freed between drawing and rendering.
var meter_fills: Array[Texture2D]=[]
var pet_chip: Control
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
		turn_panel=turn_card(content,app,dimensions,bounds,prefs.reduced_motion,"Your adventure is paused. Turn the phone to play.")
		return
	var left=bounds.position.x
	var top=bounds.position.y
	var right=bounds.end.x
	# V02 HUD: level chip left; coins, bag, settings and the live goal right.
	# Short phone screens get a slimmer bar so the trail stays visible.
	var bar=46.0 if dimensions.y<450 else 56.0
	# The room name only shows as the ribbon when you arrive (kept hidden here
	# so a room change still triggers it).
	var level=CareArt.frame(content,Rect2(left,top,180,bar))
	level.name="LevelChip"
	PetUI.set_piece(level,"hud_plank")
	PetUI.compose(level,app.adventure_title(),CareArt.icon("map"),"left",18 if bar<50 else 20)
	level_title=level.get_node("Content/Caption")
	level.visible=false
	hearts_row.clear()
	if is_instance_valid(app.active_world):
		# Status panel (hud-v2): Foxy's portrait in the gold medallion, hearts in
		# their sockets, food and energy meters in their carved grooves.
		# A55: the paper status card from P10 (assets/ui/paper-v1, slots measured on it).
		var kit="res://assets/ui/paper-v1/" if ArtStyle.paper else "res://assets/ui/hud-v2/"
		# A57 (P40): the torn-paper HUD kit when present.
		if ArtStyle.paper and P32: kit=P32_HUD
		var slots: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(kit+"slots.json"))
		var panel_tex: Texture2D=null if kit==P32_HUD else ArtTexture.load_texture(kit+("status_card.png" if ArtStyle.paper else "panel.png"))
		var card_h=bar*(1.25 if ArtStyle.paper else 1.45)*(1.75 if ArtStyle.paper and P32 else 1.0)
		var card_w=card_h*(float(slots.aspect) if panel_tex==null else panel_tex.get_width()/float(panel_tex.get_height()))
		var card=Control.new()
		card.name="StatusCard"
		card.mouse_filter=Control.MOUSE_FILTER_IGNORE
		card.position=Vector2(left,top)
		card.size=Vector2(card_w,card_h)
		content.add_child(card)
		var w=slots.window
		# Portrait: a small pixel Foxy sitting in a round sky window, animated
		# (leans in, wags, little heart) - the same Foxy as everywhere else.
		var fr=float(w[2])*card_h*1.04
		var face=TextureRect.new()
		face.name="Portrait"
		face.texture=null if ArtStyle.paper else ArtTexture.load_texture("res://assets/ui/hud-v2/portrait_sky.png")
		face.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		face.position=Vector2(float(w[0])*card_w-fr,float(w[1])*card_h-fr)
		face.size=Vector2.ONE*fr*2
		face.mouse_filter=Control.MOUSE_FILTER_IGNORE
		face.clip_children=CanvasItem.CLIP_CHILDREN_AND_DRAW
		card.add_child(face)
		portrait=TextureRect.new()
		portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.size=Vector2.ONE*fr*2.3
		portrait.position=Vector2(fr-portrait.size.x*0.5,fr*1.78-portrait.size.y*0.96)
		portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
		face.add_child(portrait)
		var frame=TextureRect.new()
		frame.texture=panel_tex
		frame.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		frame.size=card.size
		frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
		card.add_child(frame)
		if kit==P32_HUD:
			# P40: the torn-paper circle already holds Foxy's face.
			face.texture=ArtTexture.load_texture(P32_HUD+"portrait.png")
			face.clip_children=CanvasItem.CLIP_CHILDREN_DISABLED
			portrait.visible=false
		elif ArtStyle.paper:
			# The paper window is solid: the portrait sits on top of it.
			card.move_child(frame,0)
			face.clip_children=CanvasItem.CLIP_CHILDREN_DISABLED
			portrait.texture=ArtTexture.load_texture("res://assets/art/paper-v1/fx_head.png")
			portrait.size=Vector2.ONE*fr*1.7
			portrait.position=Vector2(fr-portrait.size.x*0.5,fr-portrait.size.y*0.52)
			portrait.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var hr=float(slots.heart_r)*card_h*1.05
		for i in range(MeadowWorld.MAX_HEARTS):
			var spot: Array=slots.hearts[i]
			var heart=TextureRect.new()
			heart.name="Heart%d"%i
			heart.texture=ArtTexture.load_texture(kit+"heart_full.png")
			heart.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			heart.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			heart.position=Vector2(float(spot[0])*card_w-hr,float(spot[1])*card_h-hr)
			heart.size=Vector2.ONE*hr*2
			heart.mouse_filter=Control.MOUSE_FILTER_IGNORE
			card.add_child(heart)
			hearts_row.append(heart)
		var sr=float(slots.socket_r)*card_h*1.25
		for i in range(2):
			var s: Array=slots.meters[i].socket
			var icon=TextureRect.new()
			icon.texture=ArtTexture.load_texture(("res://assets/art/meadow-p31/%s.png"%["pickup_apple","twinkle"][i]) if kit==P32_HUD else ("res://assets/art/paper-v1/%s.png"%["pickup_apple","twinkle"][i]) if ArtStyle.paper else ("res://assets/ui/hud-v2/%s.png"%["icon_food","icon_energy"][i]))
			icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.position=Vector2(float(s[0])*card_w-sr,float(s[1])*card_h-sr)
			icon.size=Vector2.ONE*sr*2
			icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
			card.add_child(icon)
		pet_chip=Control.new()
		pet_chip.name="FoxyChip"
		pet_chip.size=card.size
		pet_chip.mouse_filter=Control.MOUSE_FILTER_IGNORE
		pet_chip.set_meta("slots",slots)
		pet_chip.draw.connect(draw_pet_chip)
		card.add_child(pet_chip)
		var card_h_out=card_h
		# Minimap (off by default, Settings): this room, you, chests and doors.
		minimap=Button.new()
		minimap.name="Minimap"
		minimap.tooltip_text="Map"
		minimap.position=Vector2(left,top+card_h_out+8)
		minimap.size=Vector2(minf(176,bounds.size.x*0.24),bar*1.25)
		PetUI.set_piece(minimap,"card","",10.0)
		minimap.pressed.connect(app.toggle_world_map)
		minimap.clip_contents=true
		minimap.draw.connect(draw_minimap)
		content.add_child(minimap)
		var map=CareArt.square(content,"world",Rect2(right-bar*3-16,top,bar,bar),app.toggle_world_map)
		map.name="MapButton"
		map.tooltip_text="Map"
		paper_round(map,"ic_map")
	var coins_right=right-bar*(3 if is_instance_valid(app.active_world) else 2)-(24 if is_instance_valid(app.active_world) else 16)
	# Wide enough for four digits; the number shrinks a little if ever needed.
	var coins=CareArt.frame(content,Rect2(coins_right-124,top,124,bar))
	coins.name="RunCoins"
	PetUI.set_piece(coins,"wallet")
	PetUI.compose(coins,"0",ArtTexture.load_texture(PetUI.COIN_PATH),"left",20 if bar<50 else 24)
	wallet=coins.get_node("Content/Caption")
	if ArtStyle.paper and P32:
		# P40 coin counter: the pill has its coin; the number sits on the green part.
		var box=StyleBoxTexture.new()
		box.texture=ArtTexture.load_texture(P32_HUD+"coins.png")
		coins.add_theme_stylebox_override("panel",box)
		coins.size.x=bar*1.75
		coins.size.y=bar*0.82
		coins.position.y=top+bar*0.09
		coins.position.x=coins_right-coins.size.x
		PetUI.compose(coins,"0",null,"row",20 if bar<50 else 24,Color("fff8e6"))
		var cap: Control=coins.get_node("Content/Caption")
		coins.resized.connect(func(): cap.position.x=coins.size.x*0.38;cap.size.x=coins.size.x*0.55)
		cap.position.x=coins.size.x*0.38;cap.size.x=coins.size.x*0.55
		wallet=cap
	elif ArtStyle.paper:
		paper_skin(coins,"coin_pill",Vector4.ZERO)
		PetUI.compose(coins,"0",ArtTexture.load_texture("res://assets/ui/paper-v1/coin.png"),"left",20 if bar<50 else 24)
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
	paper_round(bag,"ic_bag")
	paper_round(CareArt.button(content,"",Rect2(right-bar,top,bar,bar),app.toggle_pause,"gear"),"ic_gear")
	var goal_w=minf(360,bounds.size.x*.42)
	var card=CareArt.frame(content,Rect2(right-goal_w,top+bar+6,goal_w,bar*.84))
	card.name="GoalChip"
	PetUI.set_piece(card,"hud_plank")
	PetUI.compose(card," ",CareArt.icon("basket"),"left",14 if bar<50 else 16)
	goal=card.get_node("Content/Caption")
	# Settings: the hint bar and the minimap can be hidden.
	card.visible=prefs.show_hints
	if is_instance_valid(minimap): minimap.visible=prefs.show_minimap
	controls=TouchControls.new()
	controls.button_size=prefs.touch_size
	controls.button_spacing=prefs.touch_spacing
	controls.stick_scale=float(prefs.stick_size)/100.0
	controls.left_handed=prefs.left_handed
	controls.modulate.a=float(prefs.control_opacity)/100.0
	controls.portrait_bounds=Rect2(left,bounds.end.y-152-prefs.touch_raise,bounds.size.x,152)
	controls.process_mode=Node.PROCESS_MODE_PAUSABLE
	content.add_child(controls)
	# P40: the place name always shows at the top (also after a re-layout).
	if is_instance_valid(app.active_world) and P32: show_place_banner(app.adventure_title())

func _process(_delta: float) -> void:
	if not app.in_adventure(): return
	if is_instance_valid(portrait) and ArtStyle.paper:
		# Paper Foxy in the window: a small breathing tilt (a puppet head).
		portrait.pivot_offset=portrait.size*Vector2(0.4,0.8)
		portrait.rotation=0.0 if app.game.preferences().reduced_motion else sin(Time.get_ticks_msec()/600.0)*0.06
	elif is_instance_valid(portrait):
		if portrait_frames.is_empty():
			var meta=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/pet-v2/frames.json"))
			var sheet: Texture2D=ArtTexture.load_texture("res://assets/art/pet-v2/pet.png")
			for f in meta.sets.pet:
				var a=AtlasTexture.new()
				a.atlas=sheet
				a.region=Rect2(f.region[0],f.region[1],f.region[2],f.region[3])
				portrait_frames.append(a)
		var order=[0,1,0,3,0,1]
		var k=0 if app.game.preferences().reduced_motion else order[int(Time.get_ticks_msec()/700.0)%order.size()]
		if portrait.texture!=portrait_frames[k]: portrait.texture=portrait_frames[k]
	if is_instance_valid(level_title) and level_title.text!=app.adventure_title():
		level_title.text=app.adventure_title()
		var chip: Control=level_title.get_parent().get_parent()
		fit_chip(chip)
		show_place_banner(app.adventure_title())
	if is_instance_valid(goal):
		var line=app.adventure_prompt().replace("E •","Use ·").replace("Q •","Find ·")
		if goal.text!=line:
			goal.text=line
			# Long prompts shrink to fit the chip instead of being clipped.
			PetUI.fit_points(goal,goal.size.x,16 if logical_size.y>=450 else 14,11)
	if is_instance_valid(wallet) and wallet.text!=str(app.adventure_coins()):
		wallet.text=str(app.adventure_coins())
		PetUI.fit_points(wallet,wallet.size.x,20 if logical_size.y<450 else 24,12)
	if is_instance_valid(app.active_world):
		var world: MeadowWorld=app.active_world
		if is_instance_valid(controls):
			controls.reduced_motion_pref=app.game.preferences().reduced_motion
			for action in world.faces: controls.set_face(action,world.faces[action][0],world.faces[action][1])
		for i in range(hearts_row.size()):
			if is_instance_valid(hearts_row[i]):
				var want=ArtTexture.load_texture(((P32_HUD+"%s.png") if P32 else "res://assets/ui/paper-v1/%s.png" if ArtStyle.paper else "res://assets/ui/hud-v2/%s.png")%("heart_full" if i<world.hearts else "heart_empty"))
				if hearts_row[i].texture!=want: hearts_row[i].texture=want
		if is_instance_valid(minimap): minimap.queue_redraw()
		if is_instance_valid(pet_chip): pet_chip.queue_redraw()
		if is_instance_valid(bag_badge):
			var free=app.game.world_crates_free()
			bag_badge.visible=free>0
			var label: Label=bag_badge.get_node("Content/Caption")
			if label.text!=str(free): label.text=str(free)

## Minimap: a little picture of this room, not a diagram. Sky and ground in
## the room's colours, the part you can see framed, and real icons (Foxy for
## you, a chest for hidden treasure, a door for ways out).
func draw_minimap() -> void:
	var world: MeadowWorld=app.active_world
	if not is_instance_valid(world) or world.room.is_empty(): return
	var inner=Rect2(9,7,minimap.size.x-18,minimap.size.y-14)
	var size=Vector2(world.room.size[0],world.room.size[1])
	# Zoomed window around the child: about three screens wide, so ledges,
	# doors and treasure nearby are readable even in long or tall rooms.
	var view=world.view_rect()
	var span=Vector2(view.size.x*3.0,view.size.x*3.0*inner.size.y/inner.size.x)
	var k=inner.size.x/span.x
	var fx=size.x*0.5 if size.x<=span.x else clampf(world.player.position.x,span.x*0.5,size.x-span.x*0.5)
	var fy=size.y*0.5 if size.y<=span.y else clampf(world.player.position.y-30,span.y*0.5,size.y-span.y*0.5)
	var focus=Vector2(fx,fy)
	var o=inner.get_center()-focus*k
	var scenery: String=world.room.get("scenery","meadow")
	var sky=Color("9fd3f5") if scenery=="meadow" else (Color("2b3354") if scenery=="cave" else Color("b9c2cf"))
	var land=Color("5aa847") if scenery=="meadow" else (Color("6b78a8") if scenery=="cave" else Color("8c8f98"))
	var soil=Color("8a5a32") if scenery=="meadow" else (Color("394266") if scenery=="cave" else Color("5f626b"))
	var room_rect=Rect2(o,size*k).intersection(inner)
	minimap.draw_style_box(_round(sky,4),room_rect)
	for r in world.rects("ground"):
		var full=Rect2(o+r.position*k,Vector2(maxf(3,r.size.x*k),maxf(3,minf(r.size.y,60)*k)))
		var g=full.intersection(inner)
		if not g.has_area(): continue
		if r.size.y>20: minimap.draw_style_box(_round(soil,2),g)
		if full.position.y>=inner.position.y: minimap.draw_rect(Rect2(g.position,Vector2(g.size.x,2.5)),land)
	for wat in world.room.get("waters",[]):
		var wr=Rect2(o+Vector2(wat[0],wat[1])*k,Vector2(wat[2]*k,3)).intersection(inner)
		if wr.has_area(): minimap.draw_rect(wr,Color("3a8fe0"))
	# What the screen shows right now.
	var seen=Rect2(o+view.position*k,view.size*k).intersection(room_rect)
	minimap.draw_rect(seen,Color(1,1,1,0.85),false,1.5)
	var icon=func(name: String, at: Vector2, s: float):
		if not inner.grow(-4).has_point(at): return
		var t=CareArt.icon(name)
		minimap.draw_texture_rect(t,Rect2(at-Vector2(s,s)*0.5,Vector2(s,s)),false)
	for exit in world.active_exits():
		var at=Vector2(exit.door[0],exit.door[1]) if exit.has("door") else Vector2(2 if exit.edge=="left" else size.x-2,world.ground_y_at(2 if exit.edge=="left" else size.x-2))
		icon.call("act_enter",o+at*k-Vector2(0,6),12.0)
	for chest in world.room.get("chests",[]):
		if not chest.id in app.game.world().opened: icon.call("act_open",o+Vector2(chest.pos[0],chest.pos[1])*k-Vector2(0,6),12.0)
	var me=o+world.player.position*k-Vector2(0,7)
	minimap.draw_circle(me,6.0,Color("3a2416"))
	minimap.draw_circle(me,4.6,Color("f08a24"))
	minimap.draw_circle(me+Vector2(-1.4,-1.6),1.4,Color(1,0.9,0.7))

## A57 torn-paper HUD (concept P40, assets/ui/hud-p32).
const P32_HUD="res://assets/ui/hud-p32/"
var P32: bool:
	get: return ArtStyle.paper and ResourceLoader.exists(P32_HUD+"portrait.png")
func draw_pet_chip() -> void:
	var needs: Dictionary=app.game.pet().needs
	var slots: Dictionary=pet_chip.get_meta("slots")
	var size=pet_chip.size
	var values=[needs.fullness,needs.energy]
	for i in range(2):
		var b: Array=slots.meters[i].bar
		var r=Rect2(float(b[0])*size.x,float(b[1])*size.y,(float(b[2])-float(b[0]))*size.x,(float(b[3])-float(b[1]))*size.y)
		var v=clampf(float(values[i])/100.0,0,1)
		if meter_fills.is_empty():
			if ArtStyle.paper and P32:
				for n in ["fill_green","fill_blue","track"]: meter_fills.append(ArtTexture.load_texture(P32_HUD+"%s.png"%n))
			elif ArtStyle.paper:
				for n in ["bar_orange","bar_blue","bar_track"]: meter_fills.append(ArtTexture.load_texture("res://assets/ui/paper-v1/%s.png"%n))
			else:
				for n in ["fill_orange","fill_blue"]: meter_fills.append(ArtTexture.load_texture("res://assets/ui/hud-v2/%s.png"%n))
		if ArtStyle.paper:
			# Paper track behind the fill (the paper card has no carved groove).
			var track: Texture2D=meter_fills[2]
			pet_chip.draw_texture_rect(track,r.grow(1.5),false)
			if P32:
				# P40: "Food" / "Energy" on the track, readable with a cream outline.
				var f: Font=load(PetUI.MENU_FONT_PATH)
				var pts=int(maxf(9.0,r.size.y*0.95))
				var lab=["Food","Energy"][i]
				var base=Vector2(r.position.x+4,r.position.y+r.size.y*0.5+pts*0.36)
				pet_chip.draw_string_outline(f,base,lab,HORIZONTAL_ALIGNMENT_LEFT,-1,pts,4,Color("fff8e6"))
				pet_chip.draw_string(f,base,lab,HORIZONTAL_ALIGNMENT_LEFT,-1,pts,PetUI.INK)
				r=Rect2(r.position.x+r.size.x*0.42,r.position.y,r.size.x*0.58,r.size.y)
		if v<=0.01: continue
		var tex: Texture2D=meter_fills[i]
		# Three-slice: round caps keep their shape, the middle stretches.
		var cap_src=tex.get_height()*0.5
		var cap=r.size.y*0.5
		var w=maxf(cap*2,r.size.x*v)
		var tint=Color(1,0.55,0.5) if v<0.18 else Color.WHITE
		pet_chip.draw_texture_rect_region(tex,Rect2(r.position,Vector2(cap,r.size.y)),Rect2(0,0,cap_src,tex.get_height()),tint)
		pet_chip.draw_texture_rect_region(tex,Rect2(r.position+Vector2(cap,0),Vector2(w-cap*2,r.size.y)),Rect2(cap_src,0,tex.get_width()-cap_src*2,tex.get_height()),tint)
		pet_chip.draw_texture_rect_region(tex,Rect2(r.position+Vector2(w-cap,0),Vector2(cap,r.size.y)),Rect2(tex.get_width()-cap_src,0,cap_src,tex.get_height()),tint)

## A55 paper skin for a HUD control: the P10 cardboard piece as its box.
func paper_skin(control: Control, piece: String, margins: Vector4) -> void:
	var box=StyleBoxTexture.new()
	box.texture=ArtTexture.load_texture("res://assets/ui/paper-v1/%s.png"%piece)
	box.texture_margin_left=margins.x
	box.texture_margin_top=margins.y
	box.texture_margin_right=margins.z
	box.texture_margin_bottom=margins.w
	for state in ["panel","normal","hover","pressed","focus","disabled"]: control.add_theme_stylebox_override(state,box)

## A55 round paper button (cardboard ring) with a paper icon.
func paper_round(button: Control, icon: String) -> void:
	if not ArtStyle.paper or not is_instance_valid(button): return
	if P32:
		# P40: the round torn-paper button already carries its picture.
		var full=StyleBoxTexture.new()
		full.texture=ArtTexture.load_texture(P32_HUD+{"ic_map":"btn_map","ic_bag":"btn_bag","ic_gear":"btn_gear"}[icon]+".png")
		for state in ["normal","hover","focus","disabled","pressed"]: button.add_theme_stylebox_override(state,full)
		PetUI.compose(button,"",null,"icon")
		# P40: small caption under each round button.
		var cap=Label.new()
		cap.text={"ic_map":"Map","ic_bag":"Bag","ic_gear":"Settings"}[icon]
		cap.add_theme_font_override("font",load(PetUI.MENU_FONT_PATH))
		cap.add_theme_font_size_override("font_size",int(maxf(10.0,button.size.y*0.24)))
		cap.add_theme_color_override("font_color",PetUI.INK)
		cap.add_theme_color_override("font_outline_color",Color("fffaf0"))
		cap.add_theme_constant_override("outline_size",5)
		cap.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		cap.position=Vector2(-12,button.size.y-2)
		cap.size=Vector2(button.size.x+24,button.size.y*0.34)
		cap.mouse_filter=Control.MOUSE_FILTER_IGNORE
		button.add_child(cap)
		return
	var box=StyleBoxTexture.new()
	box.texture=ArtTexture.load_texture("res://assets/ui/paper-v1/icon_button.png")
	for state in ["normal","hover","focus","disabled"]: button.add_theme_stylebox_override(state,box)
	var down=box.duplicate()
	down.modulate_color=Color(0.85,0.82,0.78)
	button.add_theme_stylebox_override("pressed",down)
	PetUI.compose(button,"",ArtTexture.load_texture("res://assets/ui/paper-v1/%s.png"%icon),"icon")

func _round(color: Color, radius: int) -> StyleBoxFlat:
	var b=StyleBoxFlat.new()
	b.bg_color=color
	b.set_corner_radius_all(radius)
	return b

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

## Entering a new place: a big name ribbon fades in and out mid-screen.
var place_banner: Control
func show_place_banner(title: String) -> void:
	if is_instance_valid(place_banner): place_banner.queue_free()
	if not app.game.preferences().place_names: return
	Sound.play("banner",0.0,-3.0)
	var w=minf(380,safe.size.x-40)
	if ArtStyle.paper and P32:
		# P40: the place name stays at the top centre, between the card and coins.
		var plaque=PaperPlaque.new()
		plaque.title=title
		var art: Texture2D=plaque.art()
		var bw=minf(250.0,safe.size.x*0.3)
		plaque.size=Vector2(bw,bw*art.get_height()/art.get_width())
		plaque.position=Vector2(safe.get_center().x-bw*0.5,safe.position.y+2)
		plaque.name="PlaceBanner"
		plaque.mouse_filter=Control.MOUSE_FILTER_IGNORE
		place_banner=plaque
		content.add_child(plaque)
		plaque.modulate.a=0.0
		plaque.create_tween().tween_property(plaque,"modulate:a",1.0,0.35)
		return
	if ArtStyle.paper:
		# A55 (P10): a paper plaque; the name is centred on the plaque's own
		# cream card by the font's real cap height, not the line box.
		var plaque=PaperPlaque.new()
		plaque.title=title
		var art: Texture2D=plaque.art()
		plaque.size=Vector2(w,w*art.get_height()/art.get_width())
		plaque.position=Vector2(safe.get_center().x-w/2,safe.position.y+safe.size.y*0.2)
		place_banner=plaque
	else:
		place_banner=Panel.new()
		PetUI.set_piece(place_banner,"ribbon_region")
		place_banner.size=Vector2(w,64)
		place_banner.position=Vector2(safe.get_center().x-w/2,safe.position.y+safe.size.y*0.22)
	place_banner.name="PlaceBanner"
	place_banner.mouse_filter=Control.MOUSE_FILTER_IGNORE
	content.add_child(place_banner)
	if not ArtStyle.paper: PetUI.compose(place_banner,title,null,"row",28)
	place_banner.modulate.a=0.0
	var t=place_banner.create_tween()
	t.tween_property(place_banner,"modulate:a",1.0,0.25)
	t.tween_interval(1.6)
	t.tween_property(place_banner,"modulate:a",0.0,0.5)
	t.tween_callback(place_banner.queue_free)

## One-time explanation card, e.g. when a new ability is learned.
func show_card(title: String, text: String, icon="act_jump") -> void:
	Sound.play("ui_open")
	if is_instance_valid(card): card.queue_free()
	var w=minf(460,safe.size.x-24)
	# The card grows to fit its text; the button sits below the text.
	var body_w=w-120
	var font: Font=load(PetUI.MENU_FONT_PATH)
	var text_h=font.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,body_w,16).y+8
	var h=56+text_h+PetUI.H_HEADER+10
	card=CareArt.panel(content,Rect2(safe.get_center().x-w*0.5,safe.position.y+60,w,h))
	card.name="AbilityCard"
	CareArt.picture(card,icon,Rect2(22,30,64,64))
	var heading=CareArt.title(card,"New: "+title,Rect2(100,18,body_w,36),24)
	heading.autowrap_mode=TextServer.AUTOWRAP_OFF
	CareArt.title(card,text,Rect2(100,54,body_w,text_h),16)
	var ok=CareArt.button(card,"Got it",Rect2(w-150,h-PetUI.H_HEADER-6,128,PetUI.H_HEADER-10),func(): card.queue_free(),"",true)
	ok.name="GotIt"

## Shared "turn your phone sideways" card (adventure and Catch the Ball are
## landscape only). Returns the card panel.
static func turn_card(content: Control, app: Control, dimensions: Vector2, bounds: Rect2, reduced_motion: bool, message_text: String) -> Panel:
	var dim=ColorRect.new()
	dim.color=Color(.03,.08,.17,.78)
	dim.size=dimensions
	content.add_child(dim)
	# Big card: most of the phone screen, generous padding, a large phone.
	var width=minf(400,bounds.size.x-16)
	var height=minf(680,bounds.size.y-16)
	var pad=28.0
	var card=CareArt.panel(content,Rect2(bounds.get_center()-Vector2(width,height)/2,Vector2(width,height)))
	var heading=CareArt.title(card,"Turn your phone sideways",Rect2(pad,pad,width-pad*2,80),32)
	heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var message=CareArt.title(card,message_text,Rect2(pad,pad+80,width-pad*2,56),19)
	message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var buttons_top=height-pad-PetUI.H_BUTTON*2-12
	var stage_top=pad+150
	var stage_h=maxf(140,buttons_top-stage_top-16)
	# A pixel phone that tilts sideways, so the request is clear without reading.
	var stage=Control.new()
	stage.position=Vector2(pad,stage_top)
	stage.size=Vector2(width-pad*2,stage_h)
	stage.mouse_filter=Control.MOUSE_FILTER_IGNORE
	card.add_child(stage)
	var phone_h=minf(stage_h*0.82,260.0)
	var phone_w=phone_h*0.56
	var phone=TextureRect.new()
	phone.name="RotatePhone"
	phone.texture=ArtTexture.load_texture("res://assets/ui/concept-v1/rotate-phone.png")
	phone.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	phone.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	phone.size=Vector2(phone_w,phone_h)
	phone.position=Vector2((stage.size.x-phone_w)*0.5,(stage_h-phone_h)*0.5)
	phone.pivot_offset=phone.size*0.5
	stage.add_child(phone)
	var arrow=TextureRect.new()
	arrow.texture=ArtTexture.load_texture("res://assets/ui/concept-v1/rotate-arrow.png")
	arrow.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	arrow.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	arrow.size=Vector2.ONE*phone_h*0.42
	arrow.position=Vector2(stage.size.x*0.5+phone_w*0.35,phone.position.y-arrow.size.y*0.25)
	stage.add_child(arrow)
	# The screen inside the phone: upright portrait picture first; once the
	# phone lies sideways the screen turns too, so Foxy stays upright.
	var k=phone_h/256.0
	var screen=Control.new()
	screen.name="PhoneScreen"
	screen.clip_contents=true
	screen.mouse_filter=Control.MOUSE_FILTER_IGNORE
	screen.position=Vector2((phone_w-139*k)*0.5+16*k,35*k)
	screen.size=Vector2(107,177)*k
	phone.add_child(screen)
	var upright=TextureRect.new()
	upright.texture=ArtTexture.load_texture("res://assets/ui/concept-v1/rotate-screen-portrait.png")
	upright.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	upright.size=screen.size
	upright.mouse_filter=Control.MOUSE_FILTER_IGNORE
	screen.add_child(upright)
	var wide=TextureRect.new()
	wide.name="WideScreen"
	wide.texture=ArtTexture.load_texture("res://assets/ui/concept-v1/rotate-screen-landscape.png")
	wide.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	wide.size=Vector2(screen.size.y,screen.size.x)
	wide.position=(screen.size-wide.size)*0.5
	wide.pivot_offset=wide.size*0.5
	wide.rotation=-PI*0.5
	wide.mouse_filter=Control.MOUSE_FILTER_IGNORE
	wide.modulate.a=0.0
	screen.add_child(wide)
	if not reduced_motion:
		var spin=phone.create_tween().set_loops()
		spin.tween_interval(0.5)
		spin.tween_property(phone,"rotation",PI*0.5,0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		spin.tween_property(wide,"modulate:a",1.0,0.25)
		spin.parallel().tween_property(upright,"modulate:a",0.0,0.25)
		spin.tween_interval(1.4)
		spin.tween_property(wide,"modulate:a",0.0,0.15)
		spin.parallel().tween_property(upright,"modulate:a",1.0,0.15)
		spin.tween_property(phone,"rotation",0.0,0.35)
	else:
		phone.rotation=PI*0.5
		wide.modulate.a=1.0
		upright.modulate.a=0.0
	var pet=CareArt.button(card,"My Pet",Rect2(pad,buttons_top,width-pad*2,PetUI.H_BUTTON),app.show_home,"paw")
	var menu=CareArt.button(card,"Main menu",Rect2(pad,buttons_top+PetUI.H_BUTTON+12,width-pad*2,PetUI.H_BUTTON),app.show_menu,"back")
	PetUI.unify([pet,menu])
	return card
