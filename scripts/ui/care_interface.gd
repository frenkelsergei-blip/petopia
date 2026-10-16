class_name CareInterface
extends Panel
## Native V03/V06/V07/V08/V09 screens over the same live room, rules and save.
var app: Control
var mode="home"
var logical_size=Vector2(1280,720)
var safe=Rect2(12,12,1256,696)
var signature=""
var content: Control
var room_view: TextureRect
var room_input: Control
var live_portrait: AtlasTexture
var details_canvas: Control
var meters: Dictionary={}
var numbers: Dictionary={}
var wallet_value: Label
var identity: Label
var stage_caption: Label
var feedback: Label
var action_buttons: Array[Button]=[]
var nav_buttons: Array[Button]=[]
var home_overlay=""
var care_button: Button
var menu_button: Button
var sheet: Panel
var rest_button: Button
var pet_badge: Control
var selected_level=0
var draft_name=""
var name_input: LineEdit
var decorate_buttons: Array[Button]=[]
const NEEDS=[["fullness","Food","feed"],["happiness","Happy","happy"],["energy","Energy","energy"],["cleanliness","Clean","water"],["health","Health","health"],["bond","Bond","bond"]]
const TITLES={"games":"Mini games","home":"My Pet","details":"Your companion","map":"Adventures","shop":"Shop & Bag","decorate":"Decorate","collection":"Collection","pause":"Pause & Settings","result":"Adventure complete!","minigame_result":"Lovely time together"}

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	if not app.game.state.is_empty(): draft_name=app.game.pet().name
	app.game.changed.connect(refresh)
	layout(Vector2(get_window().content_scale_size),Rect2(12,12,1256,696))

func open(value: String) -> void:
	if value!="home" and is_instance_valid(app.home): app.home.cancel_care()
	mode=value
	home_overlay=""
	signature=""
	layout(logical_size,safe)

func _process(_delta: float) -> void:
	refresh()

func layout(dimensions: Vector2, bounds: Rect2) -> void:
	logical_size=dimensions
	safe=bounds
	var next=str([dimensions,bounds,mode,home_overlay])
	if next==signature: return
	signature=next
	if is_instance_valid(content):
		remove_child(content)
		content.queue_free()
	meters.clear()
	numbers.clear()
	action_buttons.clear()
	nav_buttons.clear()
	decorate_buttons.clear()
	identity=null
	stage_caption=null
	name_input=null
	care_button=null
	menu_button=null
	rest_button=null
	pet_badge=null
	feedback=null
	live_portrait=null
	details_canvas=null
	content=Control.new()
	content.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(content)
	content.size=dimensions
	if mode in ["details","map","shop","collection","games","pause","bag"] or not home_overlay.is_empty():
		var backdrop=ModalBackdrop.new()
		content.add_child(backdrop)
		backdrop.configure(app.viewport.get_texture(),dimensions)
		room_view=backdrop
	else:
		room_view=TextureRect.new()
		room_view.texture=app.viewport.get_texture()
		room_view.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		room_view.mouse_filter=Control.MOUSE_FILTER_IGNORE
		room_view.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		room_view.size=dimensions
		content.add_child(room_view)
	if is_instance_valid(app.home) and mode not in ["result","minigame_result"]:
		var room_size=Vector2(390,390*dimensions.y/dimensions.x) if dimensions.x<dimensions.y else Vector2(360*dimensions.x/dimensions.y,360)
		app.viewport.get_parent().stretch=false
		WorldRender.configure(app.viewport,Vector2i(room_size))
		app.home.layout_room(room_size)
		if mode!="pause": app.world.transform=Transform2D.IDENTITY
	room_input=Control.new()
	room_input.size=dimensions
	room_input.mouse_filter=Control.MOUSE_FILTER_STOP
	room_input.gui_input.connect(room_event)
	content.add_child(room_input)
	if mode=="pause":
		build_pause()
	elif mode=="bag":
		build_bag()
	elif mode in ["result","minigame_result"]:
		build_result()
	else:
		if mode!="details": build_header()
		match mode:
			"home": build_home()
			"details": build_details()
			"map": build_map()
			"shop": build_shop()
			"decorate": build_decorate()
			"collection": build_collection()
			"games": build_games()
	if mode not in ["pause","bag","result","minigame_result"] and home_overlay=="menu": build_navigation()
	refresh()

func portrait() -> bool: return logical_size.x<logical_size.y
func compact() -> bool: return logical_size.y<600 and not portrait()
func text(parent: Node, caption: String, rect: Rect2, points=22) -> Label:
	return CareArt.title(parent,caption,rect,points)
func button(parent: Node, caption: String, rect: Rect2, callback: Callable, icon="", primary=false) -> Button:
	return CareArt.button(parent,caption,rect,callback,icon,primary)
func frame(parent: Node, rect: Rect2) -> Panel: return CareArt.frame(parent,rect)
func picture(parent: Node, path: String, rect: Rect2, cover=false) -> TextureRect:
	var image=TextureRect.new()
	image.texture=load(path)
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED if cover else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	image.position=rect.position
	image.size=rect.size
	parent.add_child(image)
	return image
func fox_portrait(parent: Node, rect: Rect2) -> TextureRect:
	var image=picture(parent,"res://assets/ui/adoption-v1/foxy.png",rect)
	var atlas=AtlasTexture.new()
	atlas.atlas=image.texture
	atlas.region=Rect2(220,180,860,900)
	atlas.filter_clip=true
	image.texture=atlas
	return image

func build_wallet(rect: Rect2) -> void:
	var panel=frame(content,rect)
	var icon=TextureRect.new()
	icon.name="CoinIcon"
	icon.texture=load(PetUI.COIN_PATH)
	icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position=Vector2(12,(rect.size.y-40)/2)
	icon.size=Vector2(40,40)
	icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.add_child(icon)
	wallet_value=text(panel,"0",Rect2(60,3,rect.size.x-70,rect.size.y-6),28)
	if mode=="home": app.coin_label=wallet_value

func tab(caption: String, icon: String, rect: Rect2, callback: Callable, selected=false) -> void:
	var b=button(content,"",rect,callback,"",selected)
	b.tooltip_text=caption
	if portrait():
		CareArt.picture(b,icon,Rect2((rect.size.x-24)/2,7,24,24))
		var label=text(b,caption,Rect2(3,31,rect.size.x-6,18),14)
		label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	else:
		b.text=caption
		b.add_theme_font_size_override("font_size",17 if compact() else 20)
		for key in ["normal","hover","pressed","disabled"]: b.get_theme_stylebox(key).content_margin_left=45
		CareArt.picture(b,icon,Rect2(12,(rect.size.y-28)/2,28,28))
	nav_buttons.append(b)

func build_header() -> void:
	if mode=="home":
		build_wallet(Rect2(safe.position,Vector2(130,56)))
	else:
		var title=TITLES.get(mode,"My Pet")
		var back=button(content,title,Rect2(safe.position,Vector2(minf(200,safe.size.x-202),56)),app.show_home,"back")
		back.tooltip_text="Back to My Pet"
		build_wallet(Rect2(safe.end.x-194,safe.position.y,130,56))
	menu_button=button(content,"Menu",Rect2(safe.end.x-64,safe.position.y,64,64),func(): toggle_overlay("menu"))
	menu_button.name="HomeMenu"
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color"]: menu_button.add_theme_color_override(key,Color(0,0,0,0))
	CareArt.picture(menu_button,"menu",Rect2(20,9,24,21))
	centered(menu_button,"Menu",Rect2(4,35,56,20),14)

func toggle_overlay(value: String) -> void:
	if value=="care" and is_instance_valid(app.home) and app.home.busy(): return
	if value=="menu" and is_instance_valid(app.home): app.home.cancel_care()
	home_overlay="" if home_overlay==value else value
	signature=""
	layout(logical_size,safe)

func close_overlay() -> void:
	home_overlay=""
	signature=""
	layout(logical_size,safe)

func handle_back() -> bool:
	if home_overlay.is_empty(): return false
	close_overlay()
	return true

func sheet_frame(rect: Rect2, caption: String) -> Panel:
	var panel=frame(content,rect)
	panel.name="CareDrawer" if home_overlay=="care" else "NavigationMenu"
	var style=PetUI.wallet_style()
	style.corner=26
	panel.add_theme_stylebox_override("panel",style)
	text(panel,caption,Rect2(22,12,rect.size.x-94,44),25)
	var close=button(panel,"",Rect2(rect.size.x-64,12,48,48),close_overlay,"close")
	close.name="CloseSheet"
	close.tooltip_text="Close"
	return panel

func care_bounds() -> Rect2:
	var width=minf(430,safe.size.x)
	var height=304.0
	if portrait(): return Rect2(safe.get_center().x-width/2,safe.end.y-height,width,height)
	width=minf(430,safe.size.x*.51)
	height=minf(304,safe.size.y-78)
	return Rect2(safe.end.x-width,safe.end.y-height,width,height)

func build_navigation() -> void:
	var width=minf(460,safe.size.x)
	var height=minf(354,safe.size.y)
	sheet=sheet_frame(Rect2(safe.get_center()-Vector2(width,height)/2,Vector2(width,height)),"Menu")
	var rows=[["Details","paw",app.show_details],["Adventures","map",app.show_map],["Shop","shop",app.show_shop],["Decorate","decorate",app.show_decorate],["Collection","bond",app.show_collection],["Mini games","ball",app.show_minigames],["Settings","gear",app.toggle_pause],["Main menu","back",app.show_menu]]
	var column_width=(width-48)/2
	var top=72.0
	var row_height=maxf(48,minf(56,(height-top-18-24)/4))
	for i in range(rows.size()):
		var entry=rows[i]
		var b=button(sheet,entry[0],Rect2(18+(i%2)*(column_width+12),top+int(i/2)*(row_height+8),column_width,row_height),func(): close_overlay();entry[2].call(),entry[1])
		b.name=entry[0].to_pascal_case()
		nav_buttons.append(b)

func needs_panel(parent: Node, rect: Rect2, two_columns=false, numeric=false) -> void:
	var panel=frame(parent,rect)
	two_columns=two_columns or (rect.size.y<260 and not numeric)
	var cols=2 if two_columns else 1
	var rows=3 if two_columns else 6
	var heading=0.0 if two_columns else 40.0
	if not two_columns: text(panel,app.game.pet().name+"’s Care",Rect2(18,10,rect.size.x-36,30),23)
	var row_h=(rect.size.y-heading-24)/rows
	for i in range(NEEDS.size()):
		var entry=NEEDS[i]
		var width=(rect.size.x-28-(8 if cols==2 else 0))/cols
		var pos=Vector2(14+(i%cols)*(width+8),12+heading+int(i/cols)*row_h)
		var small=row_h<45 or cols==2
		CareArt.picture(panel,entry[2],Rect2(pos,Vector2.ONE*(22 if small else 32)))
		text(panel,entry[1],Rect2(pos+Vector2(30 if small else 42,0),Vector2(width-32 if small else width-48,22 if small else 30)),14 if small else 18)
		var meter=CareArt.meter(panel,pos+Vector2(30 if small else 42,24 if small else 30),width-(36 if small else 50),entry[0],12 if small else 18)
		meters[entry[0]]=meter
		if entry[0]!="bond": app.bars[entry[0]]=meter
		if numeric:
			numbers[entry[0]]=text(panel,"",Rect2(pos+Vector2(width-50,0),Vector2(50,24)),18)

func build_home() -> void:
	# Selected A44: quiet room is one state; its Care button opens the drawer.
	var width=minf(248,safe.size.x)
	var y=minf(logical_size.y*.80,safe.end.y-72)
	if not portrait(): y=safe.end.y-80
	care_button=button(content,"Care for "+app.game.pet().name,Rect2(safe.get_center().x-width/2,y,width,72),func(): toggle_overlay("care"),"paw",true)
	care_button.name="CareForPet"
	care_button.add_theme_constant_override("icon_max_width",30)
	care_button.tooltip_text="Feed, drinking water, wash, pet, play and rest"
	pet_badge=Control.new()
	pet_badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
	pet_badge.size=Vector2(112,26)
	content.add_child(pet_badge)
	var badge=frame(pet_badge,Rect2(0,0,112,26))
	badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
	CareArt.picture(badge,"paw",Rect2(6,4,16,16))
	identity=text(badge,app.game.pet().name,Rect2(28,1,78,24),14)
	identity.autowrap_mode=TextServer.AUTOWRAP_OFF
	identity.clip_text=true
	identity.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	feedback=centered(content,"",Rect2(safe.get_center().x-minf(340,safe.size.x)/2,safe.position.y+76 if compact() else y-40,minf(340,safe.size.x),30),16)
	if home_overlay.is_empty(): return
	care_button.visible=false
	pet_badge.visible=false
	feedback.visible=false
	if home_overlay!="care": return
	var bounds=care_bounds()
	sheet=sheet_frame(bounds,"Care for "+app.game.pet().name)
	var row_height=(bounds.size.y-90)/2
	var tile_width=(bounds.size.x-56)/3
	var entries=[["Feed","feed","feed"],["Water","drink","water"],["Clean","clean","clean"],["Pet","paw","pet"],["Play","ball","play"],["Rest","rest","sleep"]]
	for i in range(entries.size()):
		var entry=entries[i]
		var b=button(sheet,"",Rect2(18+(i%3)*(tile_width+10),72+int(i/3)*(row_height+8),tile_width,row_height),func(): choose_care(entry[2]))
		b.name=entry[0]
		b.tooltip_text="Drinking water in a bowl" if entry[2]=="water" else entry[0]
		var icon_size=minf(44,row_height-42)
		CareArt.picture(b,entry[1],Rect2((tile_width-icon_size*1.25)/2,10,icon_size*1.25,icon_size))
		centered(b,entry[0],Rect2(4,row_height-32,tile_width-8,24),18).name="Caption"
		action_buttons.append(b)
		if entry[2]=="sleep": rest_button=b
	# Reframe the whole real room, not individual props or a pasted screenshot.
	var home=app.home
	if portrait():
		var target=(bounds.position.y-36)/logical_size.y*home.room_size.y
		app.world.position=Vector2(0,minf(0,target-home.floor_y))
	else:
		var zoom=1.35
		var factor=logical_size.y/360.0
		var target=(bounds.position.x-78)/factor
		var offset=clampf(target-home.pet_center*zoom,-(zoom-1)*home.room_size.x,0)
		app.world.transform=Transform2D(0,Vector2.ONE*zoom,0,Vector2(offset,home.floor_y*(1-zoom)))

func choose_care(value: String) -> void:
	close_overlay()
	if value=="play": app.show_ball()
	else: request_care(value)

func request_care(value: String) -> void:
	if is_instance_valid(app.home): app.home.request_care(value)

func scroll_card(rect: Rect2) -> VBoxContainer:
	var panel=frame(content,rect)
	var scroll=ScrollContainer.new()
	scroll.position=Vector2(18,18)
	scroll.size=rect.size-Vector2(36,36)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var column=VBoxContainer.new()
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",12)
	scroll.add_child(column)
	return column
func flow_label(parent: Node, value: String, points=20) -> Label:
	var label=text(parent,value,Rect2(0,0,0,0),points)
	label.custom_minimum_size=Vector2(0,32)
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return label
func flow_button(parent: Node, value: String, callback: Callable, kind="", primary=false) -> Button:
	var b=button(parent,value,Rect2(0,0,100,56),callback,kind,primary)
	b.custom_minimum_size=Vector2(0,56)
	b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return b
func page_bounds() -> Rect2:
	var top=safe.position.y+80
	return Rect2(safe.position.x,top,safe.size.x,safe.end.y-top)

func growth_cards(parent: Node, rect: Rect2, columns: int) -> void:
	var gap=8.0
	var width=(rect.size.x-gap*(columns-1))/columns
	for i in range(4):
		var current=app.game.pet().growth_stage==PetRules.STAGES[i]
		var position=rect.position+Vector2((i%columns)*(width+gap),int(i/columns)*88)
		var b=button(parent,PetRules.STAGES[i].capitalize()+"\n"+str([0,7,30,60][i])+" days",Rect2(position,Vector2(width,80)),func(): pass,"",current)
		b.disabled=not current
		b.tooltip_text="Growth follows real elapsed time, not XP."

func rename_field(parent: Node, bounds: Rect2) -> void:
	name_input=LineEdit.new()
	name_input.text=draft_name
	name_input.max_length=20
	name_input.position=bounds.position
	name_input.size=bounds.size
	name_input.add_theme_font_override("font",load(PetUI.MENU_FONT_PATH))
	name_input.add_theme_font_size_override("font_size",24)
	name_input.add_theme_color_override("font_color",PetUI.INK)
	name_input.add_theme_stylebox_override("normal",PetUI.style(Color("fff8e8"),6))
	name_input.text_changed.connect(func(value): draft_name=value)
	parent.add_child(name_input)

func save_name() -> void:
	if app.game.rename_pet(draft_name):
		app.notify("Your friend is now called "+app.game.pet().name+".")
		app.show_details()

func sharp_room_portrait(parent: Node, rect: Rect2) -> TextureRect:
	# The same room and the same pet, not the alternate room painted in V06.
	var image=TextureRect.new()
	live_portrait=AtlasTexture.new()
	live_portrait.atlas=app.viewport.get_texture()
	live_portrait.filter_clip=true
	image.texture=live_portrait
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	image.position=rect.position
	image.size=rect.size
	image.name="LiveRoomPortrait"
	parent.add_child(image)
	update_portrait()
	return image

func update_portrait() -> void:
	if live_portrait==null or not is_instance_valid(app.home): return
	var home=app.home
	var at=home.pet_art.position
	if app.game.pet().sleeping: at=Vector2(home.bed_bounds.get_center().x,home.floor_y)
	var area=Rect2(at-Vector2(74,113),Vector2(148,113))
	area.position.x=clampf(area.position.x,0,home.room_size.x-area.size.x)
	area.position.y=clampf(area.position.y,0,home.room_size.y-area.size.y)
	var density=Vector2(app.viewport.size)/home.room_size
	live_portrait.region=Rect2(area.position*density,area.size*density)

func clear_button(parent: Node, caption: String, rect: Rect2, callback: Callable, points=24) -> Button:
	var b=Button.new()
	b.text=caption
	b.position=rect.position
	b.size=rect.size
	b.add_theme_font_override("font",load(PetUI.MENU_FONT_PATH))
	b.add_theme_font_size_override("font_size",points)
	for key in ["font_color","font_hover_color","font_pressed_color"]: b.add_theme_color_override(key,PetUI.INK)
	for key in ["normal","hover","pressed","disabled"]: b.add_theme_stylebox_override(key,StyleBoxEmpty.new())
	b.add_theme_stylebox_override("focus",PetUI.style(Color(0,0,0,0),4))
	b.pressed.connect(callback)
	b.mouse_entered.connect(func(): b.modulate=Color(1.06,1.06,1.06))
	b.mouse_exited.connect(func(): b.modulate=Color.WHITE)
	parent.add_child(b)
	return b

func centered(parent: Node, caption: String, rect: Rect2, points: int) -> Label:
	var label=text(parent,caption,rect,points)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode=TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text=true
	return label

func build_details() -> void:
	app.home.focus_pet=true
	if portrait() or compact():
		build_compact_details()
		return
	# Measured V06 design canvas. Only the UI silhouette is retained from the
	# empty skin; transparent surroundings show our own blurred, live room.
	var factor=minf(logical_size.x/1280.0,logical_size.y/720.0)
	details_canvas=Control.new()
	details_canvas.position=logical_size/2-Vector2(1280,720)*factor/2
	details_canvas.scale=Vector2.ONE*factor
	details_canvas.size=Vector2(1280,720)
	content.add_child(details_canvas)
	picture(details_canvas,"res://assets/ui/care-v1/details-skin-alpha.png",Rect2(0,0,1280,720))
	var back=clear_button(details_canvas,"",Rect2(190,25,74,58),app.show_home)
	back.tooltip_text="Back to My Pet"
	CareArt.picture(back,"back",Rect2(24,10,38,38))
	centered(details_canvas,app.game.pet().name,Rect2(270,25,150,58),36)
	# Wallet and gear are native hit/label controls over their reference frames.
	picture(details_canvas,PetUI.COIN_PATH,Rect2(858,28,48,48))
	wallet_value=centered(details_canvas,"",Rect2(924,27,68,48),32)
	var gear=clear_button(details_canvas,"",Rect2(1018,20,64,64),app.toggle_pause)
	gear.tooltip_text="Settings"
	# Exact white gear art, without introducing a second framed button.
	CareArt.reference_crop(gear,Rect2(14,14,36,36),Rect2(1350,46,50,51))
	sharp_room_portrait(details_canvas,Rect2(211,118,324,241))
	centered(details_canvas,app.game.pet().name,Rect2(210,376,325,36),30)
	centered(details_canvas,age_caption(),Rect2(210,412,325,24),20)
	centered(details_canvas,"Curious · Playful",Rect2(210,437,325,22),18)
	CareArt.reference_crop(details_canvas,Rect2(251,450,52,40),Rect2(329,586,68,54))
	centered(details_canvas,"Favorite: Berry bowl",Rect2(307,456,191,30),19)
	for i in range(6):
		var entry=NEEDS[i]
		var yy=105+i*62.0
		# Preserve the approved icons' actual pixels and aspect, not substitutes.
		var raw_y=[142,220,300,381,462,543][i]
		CareArt.reference_crop(details_canvas,Rect2(647,yy+3,64,47),Rect2(844,raw_y,88,62))
		text(details_canvas,entry[1],Rect2(735,yy+9,82,34),22)
		meters[entry[0]]=CareArt.meter(details_canvas,Vector2(812,yy+15),196,entry[0],25)
		numbers[entry[0]]=centered(details_canvas,"",Rect2(1024,yy+7,62,38),22)
	text(details_canvas,"Growth Journey",Rect2(194,519,160,32),21)
	text(details_canvas,"Foxy grows over time
with your care!",Rect2(194,551,152,40),16)
	detail_growth(details_canvas,Rect2(355,512,729,69))
	clear_button(details_canvas,"Back to My Pet",Rect2(253,633,234,52),app.show_home,23)
	clear_button(details_canvas,"Care for "+app.game.pet().name,Rect2(736,633,292,52),app.show_home,25)

func age_caption() -> String:
	return app.game.pet().growth_stage.capitalize()+" · %d days"%int(app.game.pet().elapsed_age_seconds/PetRules.DAY)

func detail_growth(parent: Node, rect: Rect2) -> void:
	var thresholds=[0,7,30,60]
	var age=app.game.pet().elapsed_age_seconds/PetRules.DAY
	var current=PetRules.STAGES.find(app.game.pet().growth_stage)
	for i in range(4):
		var x=rect.position.x+i*190
		var selected=i==current
		var skin=StyleBoxTexture.new()
		skin.texture=load("res://assets/ui/care-v1/details-skin-alpha.png")
		skin.region_rect=Rect2(463,667,211,92) if selected else Rect2(714,667,205,92)
		for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: skin.set_texture_margin(side,12)
		var card=Panel.new()
		card.position=Vector2(x,rect.position.y)
		card.size=Vector2(160,69)
		card.add_theme_stylebox_override("panel",skin)
		parent.add_child(card)
		var source_x=[524,765,1010,1259][i]
		CareArt.reference_crop(card,Rect2(46,4,58,45),Rect2(source_x,675,77,61))
		# Gray silhouettes communicate future anatomy; they are UI art, not
		# a claim that the mature production animation set is complete.
		centered(card,PetRules.STAGES[i].capitalize(),Rect2(4,46,152,22),17)
		if selected:
			CareArt.reference_crop(card,Rect2(112,20,30,30),Rect2(610,691,47,43))
		elif i>current:
			CareArt.reference_crop(card,Rect2(115,28,20,20),Rect2(852,705,31,29))
		if i==current and i<3:
			centered(parent,"%d / %d days to %s"%[int(age),thresholds[i+1],PetRules.STAGES[i+1].capitalize()],Rect2(x,rect.position.y+70,160,23),15)
			var progress=CareArt.meter(parent,Vector2(x+5,rect.position.y+93),150,"health",11)
			progress.value=clampf((age-thresholds[i])/(thresholds[i+1]-thresholds[i])*100,0,100)
		else:
			centered(parent,("Fully grown" if i==3 and selected else "%d days"%thresholds[i]),Rect2(x,rect.position.y+76,160,25),17)

func build_compact_details() -> void:
	var y=safe.position.y
	button(content,app.game.pet().name,Rect2(safe.position.x,y,safe.size.x-202,56),app.show_home,"back")
	build_wallet(Rect2(safe.end.x-194,y,130,56))
	button(content,"",Rect2(safe.end.x-56,y,56,56),app.toggle_pause,"gear")
	var column=scroll_card(Rect2(safe.position+Vector2(0,64),safe.size-Vector2(0,64)))
	var portrait_box=Control.new()
	portrait_box.custom_minimum_size=Vector2(0,194)
	column.add_child(portrait_box)
	var width=safe.size.x-36
	sharp_room_portrait(portrait_box,Rect2(4,4,148,180))
	text(portrait_box,app.game.pet().name+"
"+age_caption()+"
Curious · Playful",Rect2(164,10,maxf(120,width-168),158),18)
	var meter_box=Control.new()
	meter_box.custom_minimum_size=Vector2(0,356)
	column.add_child(meter_box)
	for i in range(6):
		var entry=NEEDS[i]
		var row=frame(meter_box,Rect2(0,i*58,width,54))
		CareArt.picture(row,entry[2],Rect2(12,8,34,34))
		text(row,entry[1],Rect2(52,4,78,26),17)
		meters[entry[0]]=CareArt.meter(row,Vector2(134,17),maxf(65,width-194),entry[0],20)
		numbers[entry[0]]=centered(row,"",Rect2(width-56,6,50,38),17)
	flow_label(column,"Favorite: Berry bowl",18)
	flow_label(column,"Growth Journey",24)
	flow_label(column,"Baby → Child at 7 days → Teen at 30 → Adult at 60.
Growth follows real time and your care.",18)
	var growth=Control.new()
	growth.custom_minimum_size=Vector2(0,176)
	column.add_child(growth)
	growth_cards(growth,Rect2(0,0,width,176),2)
	flow_button(column,"Back to My Pet",app.show_home,"back")
	flow_button(column,"Care for "+app.game.pet().name,app.show_home,"",true)

func build_map() -> void:
	var bounds=page_bounds()
	var map_rect=Rect2(bounds.position,Vector2(bounds.size.x*(1 if portrait() else .67),minf(285,bounds.size.y*.43) if portrait() else bounds.size.y-80))
	var panel=frame(content,map_rect)
	picture(panel,"res://assets/ui/care-v1/meadows-map.png",Rect2(8,8,map_rect.size.x-16,map_rect.size.y-16),true)
	var image_area=Rect2(8,8,map_rect.size.x-16,map_rect.size.y-16)
	var map_scale=maxf(image_area.size.x/1536.0,image_area.size.y/1024.0)
	var map_offset=image_area.get_center()-Vector2(1536,1024)*map_scale/2
	var points=[Vector2(.163,.56),Vector2(.374,.513),Vector2(.521,.454),Vector2(.732,.576),Vector2(.86,.352)]
	for i in range(5):
		var size=52.0 if portrait() or compact() else 64.0
		var b=button(panel,str(i+1) if i<2 else "",Rect2(map_offset+points[i]*Vector2(1536,1024)*map_scale-Vector2.ONE*size/2,Vector2.ONE*size),func(): selected_level=i;signature="";layout(logical_size,safe),"" if i<2 else "lock",i==selected_level)
		b.disabled=i>=2
		b.tooltip_text=["The Lost Picnic","Windmill Walk","Coming later","Coming later","Coming later"][i]
	var side=Rect2(bounds.position+Vector2(0,map_rect.size.y+8),Vector2(bounds.size.x,bounds.size.y-map_rect.size.y-8)) if portrait() else Rect2(bounds.position+Vector2(map_rect.size.x+12,0),Vector2(bounds.size.x-map_rect.size.x-12,bounds.size.y))
	var column=scroll_card(side)
	flow_label(column,"Green Meadows",26)
	flow_label(column,["The Lost Picnic","Windmill Walk"][selected_level],24)
	flow_label(column,["Find Moss’s missing picnic basket.","Deliver food to the windmill with Foxy."][selected_level],18)
	var id=["W01_L01","W01_L02"][selected_level]
	flow_label(column,"Completed · Play again" if id in app.game.state.completed_levels else "Ready to explore",18)
	flow_button(column,"Start adventure",func(): app.show_adventure(id),"play",true)
	flow_button(column,"Back to My Pet",app.show_home,"back")
	if not portrait():
		var footer=frame(content,Rect2(bounds.position.x,bounds.end.y-68,map_rect.size.x,68))
		text(footer,"Sunny Beach  ·  Mystic Forest  ·  Coming later",Rect2(18,9,map_rect.size.x-36,50),20)

func build_shop() -> void:
	var bounds=page_bounds()
	var column=scroll_card(bounds)
	flow_label(column,"Little joys for your home",28)
	flow_label(column,"Free meals and washing are always available in My Pet.",18)
	for item in ItemCatalog.ITEMS:
		var owned=int(app.game.state.inventory.get(item.item_id,0))
		var row=VBoxContainer.new() if portrait() else HBoxContainer.new()
		row.add_theme_constant_override("separation",10)
		column.add_child(row)
		var preview=Control.new()
		preview.custom_minimum_size=Vector2(80,76)
		row.add_child(preview)
		var prop=ItemVisual.new()
		prop.item_id=item.item_id
		prop.position=Vector2(40,40)
		prop.scale=Vector2.ONE*3
		preview.add_child(prop)
		var info=flow_label(row,item.display_name+" · %d coins\nOwned: %d"%[item.price,owned],21)
		info.custom_minimum_size=Vector2(240 if not portrait() else 0,60)
		var buy=flow_button(row,"Buy",func():
			if app.game.purchase(item.item_id,GameState.event_id("purchase")): app.show_shop())
		buy.disabled=app.game.state.coins<item.price or (item.permanent and owned>0)
		if owned>0:
			var use=flow_button(row,"Place" if item.item_id=="ball_sun" else "Use",func():
				if item.item_id=="ball_sun": app.show_decorate()
				elif item.item_id=="blue_collar": app.game.equip_collar();app.show_home()
				else: app.show_home();app.home.request_care("meal"))
	flow_button(column,"Back",app.show_home,"back")

func build_decorate() -> void:
	var bounds=page_bounds()
	var panel_rect=Rect2(bounds.position.x,safe.end.y-(250 if portrait() else 180),bounds.size.x,250 if portrait() else 180)
	var panel=frame(content,panel_rect)
	text(panel,"Choose a place for the ball",Rect2(20,12,panel_rect.size.x-40,36),24)
	if app.game.state.inventory.get("ball_sun",0)<1:
		text(panel,"The ball is in the Shop. Your care furniture is free.",Rect2(20,56,panel_rect.size.x-40,54),18)
		button(panel,"Shop",Rect2(20,panel_rect.size.y-74,140,56),app.show_shop,"shop")
		button(panel,"Back",Rect2(172,panel_rect.size.y-74,140,56),app.show_home,"back")
		return
	var gap=8.0
	var width=(panel_rect.size.x-40-gap*2)/3
	for i in range(3):
		var b=button(panel,["On the rug","By the bed","By the window"][i],Rect2(20+i*(width+gap),60,width,56),func(): app.home.toy_preview=i)
		b.add_theme_font_size_override("font_size",15 if portrait() else 20)
		decorate_buttons.append(b)
	var actions_y=132 if portrait() else 120
	var actions_w=(panel_rect.size.x-48)/3
	button(panel,"Confirm",Rect2(20,actions_y,actions_w,56),func():
		if app.home.toy_preview>=0 and app.game.place_toy(app.home.toy_preview): app.show_home();app.home.react_to("toy"),"",true)
	button(panel,"Cancel",Rect2(24+actions_w,actions_y,actions_w,56),app.show_home)
	button(panel,"Pack",Rect2(28+actions_w*2,actions_y,actions_w,56),func():
		if app.game.place_toy(-1): app.show_home())

func build_games() -> void:
	var column=scroll_card(page_bounds())
	flow_label(column,"Play together",30)
	flow_label(column,"You lead. Foxy catches and brings the ball back.",20)
	flow_button(column,"Catch the Ball",app.show_ball,"play",true)
	flow_label(column,"Practice first, then ten throws. A game together earns happiness and bond.",18)
	flow_button(column,"Back to My Pet",app.show_home,"back")

func build_collection() -> void:
	var column=scroll_card(page_bounds())
	flow_label(column,"Your little family",28)
	flow_label(column,app.game.pet().name+" · Foxy · "+app.game.pet().growth_stage.capitalize(),24)
	var portrait_box=Control.new()
	portrait_box.custom_minimum_size=Vector2(0,170)
	column.add_child(portrait_box)
	fox_portrait(portrait_box,Rect2(0,0,160,170))
	flow_label(column,"Adventure memories",26)
	var memories=0
	for entry in [["picnic_sticker","Picnic together"],["windmill_badge","Windmill delivery"]]:
		if entry[0] in app.game.state.discovered_ids:
			flow_label(column,entry[1]+" · Saved",22)
			memories+=1
	if memories==0: flow_label(column,"Complete an adventure to keep a memory here.",18)
	flow_button(column,"Adventures",app.show_map,"map")
	flow_button(column,"Back to My Pet",app.show_home,"back")

func settings_column(column: VBoxContainer) -> void:
	flow_label(column,"Settings",28)
	var prefs=app.game.preferences()
	flow_button(column,"Sound: "+("On" if prefs.sound else "Off"),func():
		app.game.set_preference("sound",not app.game.preferences().sound)
		AudioServer.set_bus_mute(0,not app.game.preferences().sound)
		signature="";layout(logical_size,safe))
	flow_button(column,"Reduced motion: "+("On" if prefs.reduced_motion else "Off"),func():
		app.game.set_preference("reduced_motion",not app.game.preferences().reduced_motion)
		signature="";layout(logical_size,safe))
	for entry in [["touch_size","Touch size",[52,60,68]],["touch_spacing","Spacing",[0,12,24]],["touch_raise","Raise controls",[0,16,32]]]:
		flow_label(column,entry[1],20)
		var row=HBoxContainer.new()
		row.add_theme_constant_override("separation",8)
		column.add_child(row)
		for value in entry[2]:
			var key=entry[0]
			flow_button(row,str(value),func():
				app.game.set_preference(key,value)
				signature="";layout(logical_size,safe),"",int(prefs[key])==value)
	flow_label(column,"Round stick / arrows: move · Space: jump\nUse: E · Find: Q · Bag: B · Pause: Esc",18)

func build_pause() -> void:
	var dim=ColorRect.new()
	dim.color=Color(.03,.08,.16,.62)
	dim.size=logical_size
	content.add_child(dim)
	if portrait():
		var column=scroll_card(Rect2(safe.position+Vector2(0,4),safe.size-Vector2(0,8)))
		flow_label(column,"A little pause",30)
		flow_label(column,"Rest, adjust your settings, then get back to the adventure.",18)
		flow_button(column,"Resume",app.toggle_pause,"play",true)
		flow_button(column,"My Pet",app.show_home,"paw")
		flow_button(column,"Main menu",app.show_menu,"back")
		settings_column(column)
		flow_button(column,"Resume",app.toggle_pause,"play")
		return
	var bounds=Rect2(safe.position+Vector2(24,12),safe.size-Vector2(48,24))
	var panel=frame(content,bounds)
	var left_width=bounds.size.x*.38
	text(panel,"A little pause",Rect2(24,18,left_width-40,44),30 if not compact() else 24).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var friends=preload("res://scripts/ui/menu_friends.gd").new()
	friends.reduced_motion=app.game.preferences().reduced_motion
	friends.position=Vector2(36,74)
	friends.size=Vector2(left_width-64,maxf(50,bounds.size.y-288))
	panel.add_child(friends)
	button(panel,"Resume",Rect2(24,bounds.size.y-198,left_width-48,56),app.toggle_pause,"play",true)
	button(panel,"My Pet",Rect2(24,bounds.size.y-134,left_width-48,56),app.show_home,"paw")
	button(panel,"Main menu",Rect2(24,bounds.size.y-70,left_width-48,56),app.show_menu,"back")
	var scroll=ScrollContainer.new()
	scroll.position=Vector2(left_width+12,20)
	scroll.size=Vector2(bounds.size.x-left_width-36,bounds.size.y-40)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var column=VBoxContainer.new()
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",10)
	scroll.add_child(column)
	settings_column(column)

func build_bag() -> void:
	var width=minf(600,safe.size.x)
	var height=minf(440,safe.size.y)
	var column=scroll_card(Rect2(safe.get_center()-Vector2(width,height)/2,Vector2(width,height)))
	column.add_theme_constant_override("separation",8)
	flow_label(column,"Your adventure bag",28)
	flow_label(column,"Reusable crates: %d free / %d owned\nMeals for home: %d\nChoose where to place crates, then jump on them.\nPack them to try another arrangement."%[app.game.available_crates(),int(app.game.state.inventory.get("trail_crate",0)),int(app.game.state.inventory.get("berry_bowl",0))],17).custom_minimum_size.y=88
	var build=flow_button(column,"Place a crate",func():
		app.toggle_bag()
		app.placement_ui=preload("res://scripts/ui/crate_placement.gd").new()
		app.placement_ui.app=app
		app.add_child(app.placement_ui),"",true)
	build.disabled=app.game.available_crates()<=0
	flow_button(column,"Pack all placed crates",func(): app.game.pack_trail_crates();app.toggle_bag())
	flow_button(column,"Back",app.toggle_bag,"back")

func reward_row(parent: Node, caption: String, amount: int, gold=false) -> void:
	var row=Control.new()
	row.custom_minimum_size=Vector2(0,58)
	row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(row)
	var panel=frame(row,Rect2(0,0,300,58))
	if gold: panel.add_theme_stylebox_override("panel",PetUI.menu_style(true))
	row.resized.connect(func(): panel.size.x=row.size.x)
	var coin=TextureRect.new()
	coin.name="CoinIcon"
	coin.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	coin.texture=load(PetUI.COIN_PATH)
	coin.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.position=Vector2(10,6)
	coin.size=Vector2(46,46)
	panel.add_child(coin)
	var label=text(panel,caption,Rect2(66,5,180,48),22)
	var value=centered(panel,"+%d"%amount,Rect2(252,5,70,48),24)
	row.resized.connect(func(): label.size.x=maxf(120,row.size.x-150);value.position.x=row.size.x-80)

func build_result() -> void:
	room_view.visible=false
	picture(content,"res://assets/ui/care-v1/picnic-finish.png",Rect2(Vector2.ZERO,logical_size),true)
	var bounds=Rect2(safe.position.x+(0 if portrait() else safe.size.x*.53),safe.position.y+(safe.size.y*.24 if portrait() else 72),safe.size.x*(1 if portrait() else .47),safe.size.y*(.76 if portrait() else 1)-(8 if portrait() else 80))
	var column=scroll_card(bounds)
	flow_label(column,"Adventure complete!" if mode=="result" else "Lovely time together",30)
	if mode=="result":
		var reward=app.game.state.quest_state.last_completion
		flow_label(column,"Moss has the basket back. A picnic together!" if reward.level_id=="W01_L01" else "The windmill food delivery is complete!",21)
		for entry in [["Adventure",reward.base_coins],["Trail coins",reward.pickup_coins],["First discovery",reward.discovery_coins]]:
			reward_row(column,entry[0],entry[1])
		reward_row(column,"Total earned",reward.total_coins,true)
		flow_label(column,"+%d Berry bowl%s for %s\n+%d bond XP"%[reward.meals,"s" if reward.meals>1 else "",app.game.pet().name,reward.bond],21)
		flow_label(column,"New memory saved" if reward.new_keepsake else "Memory already collected",20)
		flow_label(column,"Saved · Wallet: %d coins"%reward.wallet_after,18)
		flow_button(column,"My Pet",app.show_home,"paw",true)
		flow_button(column,"Play again",func(): app.show_adventure(reward.level_id),"play")
	else:
		flow_label(column,"A lovely game of fetch. Happiness and bond saved.",21)
		flow_button(column,"My Pet",app.show_home,"paw",true)
		flow_button(column,"Play again",app.show_ball,"play")

func refresh() -> void:
	if not is_instance_valid(app) or app.game.state.is_empty() or is_queued_for_deletion(): return
	var pet=app.game.pet()
	update_portrait()
	for key in meters:
		if not is_instance_valid(meters[key]): continue
		meters[key].value=minf(100,pet.bond_xp) if key=="bond" else pet.needs[key]
		if numbers.has(key) and is_instance_valid(numbers[key]): numbers[key].text=str(int(pet.bond_xp if key=="bond" else pet.needs[key]))+(" XP" if key=="bond" else "")
	if is_instance_valid(wallet_value): wallet_value.text=str(app.game.state.coins)
	if is_instance_valid(identity): identity.text=pet.name
	if is_instance_valid(stage_caption): stage_caption.text=pet.growth_stage.capitalize()+" · %d bond XP"%pet.bond_xp
	if is_instance_valid(feedback) and is_instance_valid(app.home):
		feedback.text=app.home.care_feedback
	for b in action_buttons:
		if is_instance_valid(app.home): b.disabled=app.home.busy()
	if is_instance_valid(rest_button): rest_button.get_node("Caption").text="Wake" if pet.sleeping else "Rest"
	if is_instance_valid(care_button) and is_instance_valid(app.home): care_button.disabled=app.home.busy()
	if is_instance_valid(pet_badge) and is_instance_valid(app.home):
		var home=app.home
		var point=(app.world.transform*home.pet_art.position)/home.room_size*logical_size
		var pet_height=float(home.STAGE_HEIGHTS[pet.growth_stage])*home.room_scale()/home.room_size.y*logical_size.y
		pet_badge.position=Vector2(clampf(point.x+18,safe.position.x,safe.end.x-pet_badge.size.x),point.y-pet_height-32)

func room_event(event: InputEvent) -> void:
	if mode!="home" or not home_overlay.is_empty() or not is_instance_valid(app.home) or app.home.busy(): return
	var point=Vector2.ZERO
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed: point=event.position
	elif event is InputEventScreenTouch and not event.pressed: point=event.position
	else: return
	point=point/logical_size*app.home.room_size
	var pet_height=float(app.home.STAGE_HEIGHTS[app.game.pet().growth_stage])*app.home.room_scale()
	if Rect2(app.home.pet_art.position-Vector2(pet_height*.65,pet_height),Vector2(pet_height*1.3,pet_height+10)).has_point(point): toggle_overlay("care")
	elif app.home.bed_bounds.has_point(point): request_care("sleep")
	elif app.home.wash_bounds().has_point(point): request_care("clean")
	elif point.y>app.home.floor_y-70: app.home.call_to(point.x)
