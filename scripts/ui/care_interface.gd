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
	# A48: the Care drawer and Menu sit over the sharp live room (concept),
	# so Foxy and the child stay visible while choosing; full pages still blur.
	if mode in ["details","map","shop","collection","games","pause","bag","world_bag","world_map"]:
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
	elif mode=="world_bag":
		build_world_bag()
	elif mode=="world_map":
		build_world_map()
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
	if mode not in ["pause","bag","world_bag","world_map","result","minigame_result"] and home_overlay=="menu": build_navigation()
	if not notice_data.is_empty(): build_notice()
	refresh()

func portrait() -> bool: return logical_size.x<logical_size.y
func compact() -> bool: return logical_size.y<600 and not portrait()
func text(parent: Node, caption: String, rect: Rect2, points=22) -> Label:
	return CareArt.title(parent,caption,rect,points)
func button(parent: Node, caption: String, rect: Rect2, callback: Callable, icon="", primary=false, layout="") -> Button:
	return CareArt.button(parent,caption,rect,callback,icon,primary,layout)
func frame(parent: Node, rect: Rect2) -> Panel: return CareArt.frame(parent,rect)
func picture(parent: Node, path: String, rect: Rect2, cover=false) -> TextureRect:
	var image=TextureRect.new()
	image.texture=ArtTexture.load_texture(path)
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
	PetUI.set_piece(panel,"wallet")
	PetUI.compose(panel,"0",ArtTexture.load_texture(PetUI.COIN_PATH),"left",28)
	panel.get_node("Content/Symbol").name="CoinIcon"
	wallet_value=panel.get_node("Content/Caption")
	if mode=="home": app.coin_label=wallet_value

func tab(caption: String, icon: String, rect: Rect2, callback: Callable, selected=false) -> void:
	var b=button(content,caption,rect,callback,icon,selected,"tile" if portrait() else "row")
	b.tooltip_text=caption
	nav_buttons.append(b)

func build_header() -> void:
	var parts: Dictionary
	if mode=="home":
		parts=CareArt.header(content,safe,"",Callable(),"menu",func(): toggle_overlay("menu"))
		# Home has no back: the wallet sits on the left, the menu square on the right.
		parts.wallet.position.x=safe.position.x
	else:
		parts=CareArt.header(content,safe,TITLES.get(mode,"My Pet"),app.show_home,"menu",func(): toggle_overlay("menu"))
		parts.back.tooltip_text="Back to My Pet"
	menu_button=parts.square
	menu_button.name="HomeMenu"
	wallet_value=parts.wallet_label
	if mode=="home": app.coin_label=wallet_value

## One-off explanation card over the room (e.g. why Foxy can't go out).
## Kept across re-layouts until dismissed.
var notice_data: Array=[]
func notice(title: String, body: String) -> void:
	notice_data=[title,body]
	signature=""
	layout(logical_size,safe)
func build_notice() -> void:
	var w=minf(420,safe.size.x)
	var card=CareArt.panel(content,Rect2(safe.get_center().x-w*0.5,safe.position.y+PetUI.H_HEADER+24,w,200))
	card.name="Notice"
	CareArt.picture(card,"paw",Rect2(24,28,48,48))
	var heading=text(card,notice_data[0],Rect2(84,20,w-104,36),24)
	heading.autowrap_mode=TextServer.AUTOWRAP_OFF
	text(card,notice_data[1],Rect2(84,56,w-104,76),17)
	var ok=button(card,"Got it",Rect2(w-160,200-PetUI.H_BUTTON-18,136,PetUI.H_BUTTON),func(): notice_data=[];signature="";layout(logical_size,safe),"",true)
	ok.name="GotIt"

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
	var panel=CareArt.panel(content,rect)
	panel.name="CareDrawer" if home_overlay=="care" else "NavigationMenu"
	# Concept drawer: centred title between paw ornaments, close at the right.
	var title=text(panel,caption,Rect2(64,12,rect.size.x-128,48),PetUI.F_TITLE-2)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode=TextServer.AUTOWRAP_OFF
	var font: Font=title.get_theme_font("font")
	var width=minf(font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,PetUI.F_TITLE-2).x,rect.size.x-128)
	for side in [-1,1]:
		picture(panel,"res://assets/ui/concept-v1/paw-ornament.png",Rect2(rect.size.x/2+side*(width/2+20)-11,25,22,22))
	var close=CareArt.square(panel,"close",Rect2(rect.size.x-60,12,48,48),close_overlay)
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
	var row_height=PetUI.H_BUTTON
	for i in range(rows.size()):
		var entry=rows[i]
		var b=button(sheet,entry[0],Rect2(18+(i%2)*(column_width+12),top+int(i/2)*(row_height+8),column_width,row_height),func(): close_overlay();entry[2].call(),entry[1])
		b.name=entry[0].to_pascal_case()
		(b.get_meta("compose") as Dictionary).points=PetUI.F_BUTTON
		nav_buttons.append(b)
	PetUI.unify(nav_buttons)

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
	var width=minf(260,safe.size.x)
	var y=minf(logical_size.y*.80,safe.end.y-PetUI.H_PRIMARY)
	if not portrait(): y=safe.end.y-PetUI.H_PRIMARY-8
	care_button=button(content,"Care for "+app.game.pet().name,Rect2(safe.get_center().x-width/2,y,width,PetUI.H_PRIMARY),func(): toggle_overlay("care"),"paw",true)
	care_button.name="CareForPet"
	care_button.tooltip_text="Feed, drinking water, wash, pet, play and rest"
	pet_badge=CareArt.name_badge(content,app.game.pet().name,Vector2.ZERO)
	identity=pet_badge.get_node("Panel/Caption") if pet_badge.has_node("Panel/Caption") else pet_badge.find_child("Caption",true,false)
	feedback=centered(content,"",Rect2(safe.get_center().x-minf(340,safe.size.x)/2,safe.position.y+76 if compact() else y-40,minf(340,safe.size.x),30),16)
	if home_overlay.is_empty(): return
	care_button.visible=false
	pet_badge.visible=false
	feedback.visible=false
	if home_overlay=="food":
		build_food_picker()
		return
	if home_overlay!="care": return
	var bounds=care_bounds()
	sheet=sheet_frame(bounds,"Care for "+app.game.pet().name)
	var row_height=(bounds.size.y-90)/2
	var tile_width=(bounds.size.x-56)/3
	var entries=[["Feed","feed","feed"],["Water","drink","water"],["Clean","clean","clean"],["Pet","paw","pet"],["Play","ball","play"],["Rest","rest","sleep"]]
	for i in range(entries.size()):
		var entry=entries[i]
		var b=button(sheet,entry[0],Rect2(18+(i%3)*(tile_width+10),72+int(i/3)*(row_height+8),tile_width,row_height),func(): choose_care(entry[2]),entry[1],false,"tile")
		b.name=entry[0]
		b.tooltip_text="Drinking water in a bowl" if entry[2]=="water" else entry[0]
		action_buttons.append(b)
		if entry[2]=="sleep": rest_button=b
	PetUI.unify(action_buttons)
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
	if value=="feed":
		home_overlay="food"
		signature=""
		layout(logical_size,safe)
		return
	close_overlay()
	if value=="play": app.show_ball()
	else: request_care(value)

## A51: choose what Foxy eats. Kibble is always free; other foods come from
## the shop. Hearts mark favourites.
func build_food_picker() -> void:
	var bounds=care_bounds()
	bounds=Rect2(bounds.position.x,bounds.position.y-40,bounds.size.x,bounds.size.y+40)
	sheet=sheet_frame(bounds,"What should %s eat?"%app.game.pet().name)
	var data=GameState.foods()
	var ids: Array=data.order
	var cols=3
	var tile_w=(bounds.size.x-36-(cols-1)*10)/cols
	var tile_h=(bounds.size.y-72-60-8)/2
	var tiles=[]
	for i in range(ids.size()):
		var id: String=ids[i]
		var f: Dictionary=data.foods[id]
		var count=app.game.food_count(id)
		var caption=f.short
		var rect=Rect2(18+(i%cols)*(tile_w+10),72+int(i/cols)*(tile_h+8),tile_w,tile_h)
		var b=button(sheet,caption,rect,func(): close_overlay(); if is_instance_valid(app.home): app.home.request_food(id),"food_"+id,false,"tile")
		b.name="Food_"+id
		b.clip_text=true
		b.custom_minimum_size=Vector2.ZERO
		b.size=rect.size
		b.disabled=count<1
		if id!="kibble":
			var badge=CareArt.tag(b,"%d"%count,Rect2(6,6,30,24))
			badge.size=Vector2(30,24)
			(badge.get_meta("compose") as Dictionary).layout="row"
			(badge.get_meta("compose") as Dictionary).points=13
			PetUI.arrange(badge)
		if count<1: b.tooltip_text="Buy in the shop"
		var taste=app.game.food_taste(id)
		if taste=="like": CareArt.picture(b,"heart",Rect2(tile_w-26,6,20,20))
		tiles.append(b)
	PetUI.unify(tiles)
	var shop=button(sheet,"Buy more food",Rect2(18,bounds.size.y-60,bounds.size.x-36,PetUI.H_BUTTON-6),func(): close_overlay();app.show_shop(),"shop_stall")
	shop.name="BuyFood"

func request_care(value: String) -> void:
	if is_instance_valid(app.home): app.home.request_care(value)

func scroll_card(rect: Rect2) -> VBoxContainer:
	var panel=CareArt.panel(content,rect)
	var scroll=ScrollContainer.new()
	scroll.position=Vector2(18,18)
	scroll.size=rect.size-Vector2(36,36)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	# Drag/wheel scrolling stays; the bar itself is hidden so it never covers
	# the right edge of rows and cards (phone convention).
	scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_NEVER
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
	var h=PetUI.H_PRIMARY if primary else PetUI.H_BUTTON
	var b=button(parent,value,Rect2(0,0,100,h),callback,kind,primary)
	(b.get_meta("compose") as Dictionary).points=PetUI.F_BUTTON
	b.custom_minimum_size=Vector2(0,h)
	b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return b
func page_bounds() -> Rect2:
	var top=safe.position.y+PetUI.H_HEADER+12
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
		skin.texture=ArtTexture.load_texture("res://assets/ui/care-v1/details-skin-alpha.png")
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
	var parts=CareArt.header(content,safe,app.game.pet().name,app.show_home,"menu",func(): toggle_overlay("menu"))
	menu_button=parts.square
	wallet_value=parts.wallet_label
	var column=scroll_card(Rect2(safe.position+Vector2(0,PetUI.H_HEADER+10),safe.size-Vector2(0,PetUI.H_HEADER+10)))
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
		var row=CareArt.strip(meter_box,Rect2(0,i*58,width,54))
		PetUI.compose(row,entry[1],CareArt.icon(entry[2]),"left",17)
		var inset=PetUI.ROW_INSET
		meters[entry[0]]=CareArt.meter(row,Vector2(134,17),maxf(60,width-134-inset-56),entry[0],20)
		numbers[entry[0]]=centered(row,"",Rect2(width-inset-50,8,50,38),17)
		numbers[entry[0]].horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	flow_label(column,"Favorite: Berry bowl",18)
	flow_label(column,"Growth Journey",24)
	flow_label(column,"Baby at birth. Child at 7 days.
Teen at 30 days. Adult at 60 days.
Growth follows real time and your care.",18)
	var growth=Control.new()
	growth.custom_minimum_size=Vector2(0,176)
	column.add_child(growth)
	growth_cards(growth,Rect2(0,0,width,176),2)
	flow_button(column,"Back to My Pet",app.show_home,"back")
	flow_button(column,"Care for "+app.game.pet().name,app.show_home,"paw",true)

## V2: one connected region per stop; the V1 practice levels are retired from the map.
const LEVELS=[["WORLD","Green Meadows","Explore the connected meadows with Foxy: secrets, toy parts and a new ability.","res://assets/art/meadows-v2/town.png"]]
const MAP_POINTS=[Vector2(.163,.56),Vector2(.374,.513),Vector2(.521,.454),Vector2(.732,.576),Vector2(.86,.352)]
func chip(parent: Node, caption: String, rect: Rect2, icon="", points=18) -> Panel:
	var panel=frame(parent,rect)
	PetUI.set_piece(panel,"tag")
	PetUI.compose(panel,caption,CareArt.icon(icon) if not icon.is_empty() else null,"left",points)
	return panel
func map_board(rect: Rect2) -> void:
	var panel=CareArt.panel(content,rect)
	panel.name="MapBoard"
	panel.clip_contents=true
	var area=Rect2(8,8,rect.size.x-16,rect.size.y-16)
	picture(panel,"res://assets/ui/care-v1/meadows-map.png",area,true)
	var map_scale=maxf(area.size.x/1536.0,area.size.y/1024.0)
	var offset=area.get_center()-Vector2(1536,1024)*map_scale/2
	var spots: Array[Vector2]=[]
	for point in MAP_POINTS: spots.append(offset+point*Vector2(1536,1024)*map_scale)
	# Stone path between stops (kit path_dot at its own proportion).
	for i in range(spots.size()-1):
		var count=int(spots[i].distance_to(spots[i+1])/16)
		for k in range(1,count):
			var at=spots[i].lerp(spots[i+1],float(k)/count)
			var stone=picture(panel,"res://assets/ui/kit-v1/path_dot.png",Rect2(at-Vector2(6,4.5),Vector2(12,9)))
			stone.modulate=Color(1,1,1,1.0 if i<LEVELS.size()-1 else .6)
	# A49 medallions: done (gold check), current (our fox in a gold ring with
	# a flag), open (number), locked (padlock). Drawn at their own proportions.
	var size=56.0 if portrait() or compact() else 64.0
	for i in range(spots.size()):
		var open=i<LEVELS.size()
		var done=open and LEVELS[i][0] in app.game.state.completed_levels
		var current=i==selected_level
		var piece="medal_locked" if not open else ("medal_ring" if current else ("medal_done" if done else "medal_open"))
		var b=PetUI.menu_button(panel,"",func(): selected_level=i;signature="";layout(logical_size,safe))
		b.get_node("MenuButtonMotion").queue_free()
		PetUI.set_piece(b,piece)
		b.name="Level%d"%(i+1)
		b.position=(spots[i]-Vector2.ONE*size/2).round()
		b.size=Vector2.ONE*size
		b.disabled=not open
		b.tooltip_text=LEVELS[i][1] if open else "Coming later"
		if current:
			# Our fox inside the ring (pre-cut circle), drawn under the ring art.
			var face=picture(b,"res://assets/ui/kit-v1/fox-medal.png",Rect2(size*.14,size*.14,size*.72,size*.72))
			face.show_behind_parent=true
			var flag=picture(b,"res://assets/ui/kit-v1/flag.png",Rect2(size*.62,-size*.42,size*.42,size*.5))
			flag.name="Flag"
		elif open and not done:
			PetUI.compose(b,str(i+1),null,"row",int(size*.36))
		# A number plate only where the medallion does not already show it.
		if open and not done and not current: continue
		var label=CareArt.tag(panel,str(i+1),Rect2(b.position.x+size*.5-14,b.position.y+size-6,28,24))
		label.size=Vector2(28,24)
		(label.get_meta("compose") as Dictionary).layout="row"
		PetUI.arrange(label)
	CareArt.tag(panel,"Green Meadows",Rect2(12,12,minf(176,rect.size.x-24),PetUI.H_TAG),"map")
func world_card(parent: Node, rect: Rect2, caption: String, path: String) -> void:
	var card=frame(parent,rect)
	card.name=caption.to_pascal_case()
	var narrow=rect.size.x<rect.size.y*3.2
	var thumb_w=rect.size.x-16 if narrow else rect.size.y*1.6-16
	var thumb=picture(card,path,Rect2(8,8,thumb_w,rect.size.y-16),true)
	thumb.modulate=Color(.78,.78,.82)
	if narrow:
		# Phone width: the caption sits on the picture as a small locked chip.
		var label=CareArt.tag(card,caption,Rect2(10,rect.size.y-PetUI.H_TAG-10,rect.size.x-20,PetUI.H_TAG),"lock")
		label.name="Locked"
		return
	var x=rect.size.y*1.6
	text(card,caption,Rect2(x,6,rect.size.x-x-8,rect.size.y*.5),18)
	var lock=CareArt.tag(card,"Coming later",Rect2(x,rect.size.y-PetUI.H_TAG-10,minf(150,rect.size.x-x-10),PetUI.H_TAG),"lock")
	lock.name="Locked"
const LEVEL_CARD_BASE=14+34+38+48+136
func level_card_height(width: float, room: float) -> float:
	var preview=minf((width-32)*.42,150)+8
	var full=LEVEL_CARD_BASE+preview+54
	if room>=full: return full
	if room>=LEVEL_CARD_BASE+54: return LEVEL_CARD_BASE+54
	return minf(room,LEVEL_CARD_BASE)
func level_card(parent: Node, rect: Rect2) -> void:
	var level=LEVELS[selected_level]
	var card=CareArt.panel(parent,rect)
	card.name="LevelCard"
	var y=14.0
	var heading=text(card,"Green Meadows",Rect2(16,y,rect.size.x-32,34),26)
	heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	y+=34
	var sub=text(card,"%d · %s"%[selected_level+1,level[1]],Rect2(16,y,rect.size.x-32,30),20)
	sub.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	y+=38
	var preview_h=minf((rect.size.x-32)*.42,150)
	var room=rect.size.y-LEVEL_CARD_BASE
	if room>=preview_h+8+54:
		var preview=frame(card,Rect2(16,y,rect.size.x-32,preview_h))
		preview.name="LevelPreview"
		picture(preview,level[3],Rect2(6,6,rect.size.x-44,preview_h-12),true)
		y+=preview_h+8
	var goal=text(card,level[2],Rect2(16,y,rect.size.x-32,44),17)
	goal.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	y+=48
	var done=level[0] in app.game.state.completed_levels
	var pet=app.game.pet()
	var bottom=rect.size.y-16
	if y+46<=bottom-126:
		var companion=CareArt.tag(card,"%s · %s%s"%[pet.name,pet.growth_stage.capitalize(),"  ·  Completed" if done else ""],Rect2(16,y+6,rect.size.x-32,PetUI.H_TAG),"paw",true)
		companion.name="Companion"
	var back=button(card,"Back to My Pet",Rect2(16,bottom-PetUI.H_BUTTON,rect.size.x-32,PetUI.H_BUTTON),app.show_home,"back")
	back.name="BackToMyPet"
	var start=button(card,"Play again" if done else "Start adventure",Rect2(16,bottom-PetUI.H_BUTTON-8-PetUI.H_PRIMARY,rect.size.x-32,PetUI.H_PRIMARY),func(): app.show_world() if level[0]=="WORLD" else app.show_adventure(level[0]),"play",true)
	start.name="StartAdventure"
	PetUI.unify([back,start])
func build_map() -> void:
	var bounds=page_bounds()
	if portrait():
		var map_h=minf(300,bounds.size.y*.38)
		map_board(Rect2(bounds.position,Vector2(bounds.size.x,map_h)))
		var card_h=level_card_height(bounds.size.x,bounds.size.y-map_h-8-(98 if bounds.size.y-map_h>LEVEL_CARD_BASE+98 else 0))
		var worlds_h=bounds.size.y-map_h-card_h-16
		level_card(content,Rect2(bounds.position+Vector2(0,map_h+8),Vector2(bounds.size.x,card_h)))
		if worlds_h>=64:
			var w=(bounds.size.x-8)/2
			world_card(content,Rect2(bounds.position.x,bounds.end.y-worlds_h,w,minf(worlds_h,90)),"Sunny Beach","res://assets/ui/concept-v1/world-sunny-beach.png")
			world_card(content,Rect2(bounds.position.x+w+8,bounds.end.y-worlds_h,w,minf(worlds_h,90)),"Mystic Forest","res://assets/ui/concept-v1/world-mystic-forest.png")
		return
	var side_w=clampf(bounds.size.x*.32,260,380)
	var map_w=bounds.size.x-side_w-12
	var worlds_h=0.0 if compact() else clampf(bounds.size.y*.2,70,100)
	map_board(Rect2(bounds.position,Vector2(map_w,bounds.size.y-worlds_h-(8 if worlds_h>0 else 0))))
	if worlds_h>0:
		var w=(map_w-8)/2
		world_card(content,Rect2(bounds.position.x,bounds.end.y-worlds_h,w,worlds_h),"Sunny Beach","res://assets/ui/concept-v1/world-sunny-beach.png")
		world_card(content,Rect2(bounds.position.x+w+8,bounds.end.y-worlds_h,w,worlds_h),"Mystic Forest","res://assets/ui/concept-v1/world-mystic-forest.png")
	level_card(content,Rect2(bounds.position+Vector2(map_w+12,0),Vector2(side_w,bounds.size.y)))

## A51 shop: foods for Foxy (kibble stays free), then toys and accessories.
func shop_row(column: VBoxContainer, icon: String, title: String, detail: String, price: int, can_buy: bool, buy: Callable) -> void:
	var row=CareArt.strip(column,Rect2(0,0,100,64))
	row.custom_minimum_size=Vector2(0,64)
	PetUI.compose(row,title+"\n"+detail,CareArt.icon(icon),"left",19)
	var btn=button(row,"%d"%price,Rect2(0,9,112,46),buy,"",true)
	btn.name="Buy_"+title.to_pascal_case()
	var coin=TextureRect.new()
	coin.texture=ArtTexture.load_texture(PetUI.COIN_PATH)
	coin.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	coin.size=Vector2(22,22)
	coin.position=Vector2(16,12)
	coin.mouse_filter=Control.MOUSE_FILTER_IGNORE
	btn.add_child(coin)
	btn.disabled=not can_buy
	row.resized.connect(func(): btn.position.x=row.size.x-btn.size.x-14)

func build_shop() -> void:
	var bounds=page_bounds()
	var column=scroll_card(bounds)
	column.add_theme_constant_override("separation",8)
	flow_label(column,"Food for %s"%app.game.pet().name,PetUI.F_TITLE-2)
	var data=GameState.foods()
	for id in data.order:
		if id=="kibble": continue
		var f: Dictionary=data.foods[id]
		var taste=app.game.food_taste(id)
		var note=" · a favourite!" if taste=="like" else (" · not a favourite" if taste=="dislike" else "")
		shop_row(column,"food_"+id,f.name,"You have %d%s"%[app.game.food_count(id),note],int(f.price),app.game.state.coins>=int(f.price),func():
			if app.game.buy_food(id): app.notify("%s is in your bag."%f.name)
			signature="";layout(logical_size,safe))
	flow_label(column,"Toys and things",PetUI.F_TITLE-2)
	for item in ItemCatalog.ITEMS:
		if item.category=="food": continue
		var owned=int(app.game.state.inventory.get(item.item_id,0))
		shop_row(column,"ball" if item.item_id=="ball_sun" else "star",item.display_name,("Owned" if owned>0 else item.description),item.price,app.game.state.coins>=item.price and not (item.permanent and owned>0),func():
			if app.game.purchase(item.item_id,GameState.event_id("purchase")):
				if item.item_id=="blue_collar": app.game.equip_collar()
			signature="";layout(logical_size,safe))
	flow_label(column,"Kibble is always free. Earn coins on adventures and by caring for %s."%app.game.pet().name,15)
	flow_button(column,"Back to My Pet",app.show_home,"back")

func build_decorate() -> void:
	var bounds=page_bounds()
	var panel_rect=Rect2(bounds.position.x,safe.end.y-(250 if portrait() else 180),bounds.size.x,250 if portrait() else 180)
	var panel=CareArt.panel(content,panel_rect)
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

const STEPS={"touch_size":[[52,"Small"],[60,"Medium"],[68,"Large"]],"touch_spacing":[[0,"Close"],[12,"Normal"],[24,"Wide"]],"touch_raise":[[0,"Low"],[16,"Middle"],[32,"High"]]}
func setting_row(column: VBoxContainer, icon: String, caption: String) -> Control:
	var row=Control.new()
	row.custom_minimum_size=Vector2(0,50)
	row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	column.add_child(row)
	CareArt.picture(row,icon,Rect2(0,9,32,32))
	var label=text(row,caption,Rect2(42,0,200,50),20)
	label.name="Caption"
	return row
func toggle_setting(column: VBoxContainer, icon: String, caption: String, key: String) -> void:
	var row=setting_row(column,icon,caption)
	var on: bool=app.game.preferences()[key]
	var pill=CareArt.toggle(row,on,func():
		app.game.set_preference(key,not app.game.preferences()[key])
		if key in ["sound","music"]: Sound.apply_settings(app.game.preferences())
		signature="";layout(logical_size,safe))
	pill.name=caption.to_pascal_case()
	row.resized.connect(func(): pill.position=Vector2(row.size.x-pill.size.x,5))
func step_setting(column: VBoxContainer, icon: String, caption: String, key: String) -> void:
	var row=setting_row(column,icon,caption)
	var options: Array=STEPS[key]
	var current=0
	for i in range(options.size()):
		if int(app.game.preferences()[key])==options[i][0]: current=i
	var stepper=CareArt.stepper(row,options[current][1],current>0,current<options.size()-1,func(direction: int):
		app.game.set_preference(key,options[clampi(current+direction,0,options.size()-1)][0])
		signature="";layout(logical_size,safe),160.0 if portrait() else 196.0)
	stepper.name=caption.to_pascal_case()
	row.resized.connect(func(): stepper.position=Vector2(row.size.x-stepper.size.x,5))
func settings_column(column: VBoxContainer) -> void:
	text(column,"Settings",Rect2(0,0,0,0),28).custom_minimum_size=Vector2(0,40)
	toggle_setting(column,"speaker","Sound","sound")
	toggle_setting(column,"music","Music","music")
	toggle_setting(column,"motion","Reduced motion","reduced_motion")
	step_setting(column,"hand","Button size","touch_size")
	step_setting(column,"sense","Spacing","touch_spacing")
	step_setting(column,"up","Height","touch_raise")
	var controls=setting_row(column,"controller","Controls")
	var hint=text(controls,"Keyboard · Touch",Rect2(0,0,170,50),17)
	hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	controls.resized.connect(func(): hint.position.x=controls.size.x-hint.size.x)
	if not portrait():
		var keys=text(column,"Arrows / A D: move · Space: jump · E: use · Q: sense · B: bag · Esc: pause",Rect2(0,0,0,0),15)
		keys.custom_minimum_size=Vector2(0,40)
	# Start the Green Meadows adventure again (two taps, so it can't happen by accident).
	if not app.game.state.is_empty() and app.game.state.quest_state.has("world"):
		var again=flow_button(column,"Are you sure? Tap again to restart" if confirm_reset else "Start Green Meadows again",func():
			if confirm_reset:
				confirm_reset=false
				if app.game.world_reset():
					app.notify("Green Meadows starts fresh. Your pet, coins and food are kept.")
					app.show_world()
					return
			else: confirm_reset=true
			signature="";layout(logical_size,safe),"back")
		again.name="RestartMeadows"
		flow_label(column,"Keeps %s, coins and food. Chests, keys and quests start over."%app.game.pet().name,14)

var confirm_reset=false
func pause_card(rect: Rect2, art_height: float, framed=true) -> void:
	# Inside the portrait scroll panel it is plain content (no frame in a frame).
	var panel: Control=CareArt.panel(content,rect) if framed else Control.new()
	if not framed:
		panel.position=rect.position
		panel.size=rect.size
		content.add_child(panel)
	panel.name="PauseCard"
	var heading=text(panel,"A little pause",Rect2(16,14,rect.size.x-32,40),30)
	heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	if compact():
		# Short landscape phones: title and the three actions only.
		var h=PetUI.H_BUTTON
		var gap=10.0
		var top=58+maxf(0,(rect.size.y-58-3*h-2*gap)/2)
		var entries=[["Resume",app.toggle_pause,"play",true],["My Pet",app.show_home,"paw",false],["Main menu",app.show_menu,"back",false]]
		var group=[]
		for i in range(entries.size()):
			var entry=entries[i]
			var b=button(panel,entry[0],Rect2(16,top+i*(h+gap),rect.size.x-32,h),entry[1],entry[2],entry[3])
			b.name=entry[0].to_pascal_case()
			group.append(b)
		PetUI.unify(group)
		return
	var line=text(panel,"Rest, adjust your settings, then get back to the adventure.",Rect2(20,54,rect.size.x-40,44),16)
	line.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var friends=preload("res://scripts/ui/menu_friends.gd").new()
	friends.reduced_motion=app.game.preferences().reduced_motion
	friends.position=Vector2(rect.size.x*.14,102)
	friends.size=Vector2(rect.size.x*.72,art_height)
	panel.add_child(friends)
	var y=110+art_height
	var group=[]
	group.append(button(panel,"Resume",Rect2(20,y,rect.size.x-40,PetUI.H_PRIMARY),app.toggle_pause,"play",true))
	group.append(button(panel,"My Pet",Rect2(20,y+PetUI.H_PRIMARY+8,rect.size.x-40,PetUI.H_BUTTON),app.show_home,"paw"))
	group.append(button(panel,"Main menu",Rect2(20,y+PetUI.H_PRIMARY+PetUI.H_BUTTON+16,rect.size.x-40,PetUI.H_BUTTON),app.show_menu,"back"))
	for i in range(3): group[i].name=["Resume","MyPet","MainMenu"][i]
	PetUI.unify(group)

func build_pause() -> void:
	var dim=ColorRect.new()
	dim.color=Color(.03,.08,.16,.28)
	dim.size=logical_size
	content.add_child(dim)
	var tab_width=minf(330,safe.size.x)
	var header=button(content,"Pause & Settings",Rect2(safe.get_center().x-tab_width/2,safe.position.y,tab_width,PetUI.H_HEADER),app.toggle_pause,"back")
	header.name="PauseHeader"
	header.tooltip_text="Resume"
	var top=safe.position.y+PetUI.H_HEADER+10
	if portrait():
		var column=scroll_card(Rect2(safe.position.x,top,safe.size.x,safe.end.y-top))
		var card=Control.new()
		card.custom_minimum_size=Vector2(0,420)
		column.add_child(card)
		var holder=content
		content=card
		pause_card(Rect2(0,0,safe.size.x-36,410),110,false)
		content=holder
		settings_column(column)
		return
	var bounds=Rect2(safe.position.x+maxf(0,(safe.size.x-980)/2),top,minf(980,safe.size.x),safe.end.y-top-(0 if compact() else 40))
	var left=bounds.size.x*.38
	var art=clampf(bounds.size.y-300,40,220)
	pause_card(Rect2(bounds.position,Vector2(left-8,bounds.size.y)),art)
	var right=scroll_card(Rect2(bounds.position+Vector2(left+4,0),Vector2(bounds.size.x-left-4,bounds.size.y)))
	right.add_theme_constant_override("separation",6)
	settings_column(right)
	if not compact():
		var ribbon=CareArt.tag(content,"Paused",Rect2(safe.get_center().x-70,bounds.end.y+6,140,PetUI.H_TAG))
		ribbon.name="PausedRibbon"
		(ribbon.get_meta("compose") as Dictionary).layout="row"
		PetUI.arrange(ribbon)

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

## V2 area map: rooms you have visited, where you are, chests still hidden
## and locked ways. Unvisited rooms show as "?" until you get there.
func build_world_map() -> void:
	var data=GameState.world_data()
	var w=app.game.world()
	var current: String=app.active_world.room_id if is_instance_valid(app.active_world) else w.room
	var width=minf(900,safe.size.x)
	var height=minf(560,safe.size.y)
	var box=Rect2(safe.get_center()-Vector2(width,height)/2,Vector2(width,height))
	var panel=CareArt.panel(content,box)
	panel.name="WorldMap"
	# The painted map keeps its proportions inside the frame.
	var art: Texture2D=ArtTexture.load_texture(data.map_art)
	var inner=Rect2(16,16,width-32,height-32)
	var scale_value=minf(inner.size.x/art.get_width(),inner.size.y/art.get_height())
	var art_size=Vector2(art.get_width(),art.get_height())*scale_value
	var origin=inner.position+(inner.size-art_size)*0.5
	var painting=TextureRect.new()
	painting.texture=art
	painting.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	painting.position=origin
	painting.size=art_size
	painting.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.add_child(painting)
	var spot=func(f: Array) -> Vector2: return origin+Vector2(f[0],f[1])*art_size
	# Clouds over places not yet visited.
	var fog=Control.new()
	fog.mouse_filter=Control.MOUSE_FILTER_IGNORE
	fog.size=box.size
	panel.add_child(fog)
	var hidden_spots=[]
	for id in data.map_spots:
		if not id in w.visited: hidden_spots.append(spot.call(data.map_spots[id]))
	var r=art_size.y*0.13
	# Soft painted cumulus: a cool shadow layer, a white body and a sunlit
	# top, built from one feathered puff so the edges melt into the map.
	var puff=GradientTexture2D.new()
	puff.width=64
	puff.height=64
	puff.fill=GradientTexture2D.FILL_RADIAL
	puff.fill_from=Vector2(0.5,0.5)
	puff.fill_to=Vector2(1.0,0.5)
	var soft=Gradient.new()
	soft.offsets=PackedFloat32Array([0.0,0.68,0.84,1.0])
	soft.colors=PackedColorArray([Color(1,1,1,1),Color(1,1,1,0.95),Color(1,1,1,0.45),Color(1,1,1,0)])
	puff.gradient=soft
	# (offset in r, radius in r): a flat base row and a rounded crown.
	var shape=[[Vector2(-0.95,0.18),0.42],[Vector2(-0.45,0.22),0.5],[Vector2(0.1,0.24),0.52],[Vector2(0.65,0.2),0.46],[Vector2(1.05,0.16),0.36],[Vector2(-0.55,-0.12),0.46],[Vector2(0.0,-0.3),0.6],[Vector2(0.55,-0.14),0.48]]
	var started=Time.get_ticks_msec()
	fog.draw.connect(func():
		var t=(Time.get_ticks_msec()-started)/1000.0
		for i in hidden_spots.size():
			var c: Vector2=hidden_spots[i]+Vector2(sin(t*0.35+i*1.7)*r*0.06,0)
			# Faint mist halo so the place reads as hidden, not erased.
			fog.draw_texture_rect(puff,Rect2(c-Vector2(r*1.9,r*1.1),Vector2(r*3.8,r*2.2)),false,Color(0.93,0.95,1.0,0.35))
			for layer in [[Vector2(0.05,0.16),1.0,Color(0.6,0.64,0.86,0.75)],[Vector2.ZERO,0.96,Color(0.98,0.98,1.0,1.0)],[Vector2(-0.07,-0.1),0.6,Color(1,1,0.96,1.0)]]:
				for k in shape.size():
					var bob=sin(t*0.8+k*1.3+i)*r*0.015
					var rad: float=shape[k][1]*r*layer[1]*1.25
					var at: Vector2=c+(shape[k][0]+layer[0])*r+Vector2(0,bob)
					fog.draw_texture_rect(puff,Rect2(at-Vector2(rad,rad),Vector2(rad,rad)*2),false,layer[2]))
	(Engine.get_main_loop() as SceneTree).process_frame.connect(fog.queue_redraw)
	var found=0
	var robot=0
	for part in data.parts:
		if not part.begins_with("robot_"): continue
		robot+=1
		found+=1 if int(w.parts.get(part,0))>0 else 0
	# Route: dotted trail between connected places, solid where both are visited.
	var route=Control.new()
	route.mouse_filter=Control.MOUSE_FILTER_IGNORE
	route.size=box.size
	panel.add_child(route)
	var pairs=[]
	for id in data.map_spots:
		for exit in data.rooms[id].exits:
			if data.map_spots.has(exit.to) and not [exit.to,id] in pairs: pairs.append([id,exit.to])
		for sd in data.rooms[id].get("secret_doors",[]):
			if data.map_spots.has(sd.to) and sd.id in w.opened: pairs.append([id,sd.to])
	pairs.append(["home","meadow_fields"])
	var at_of=func(id: String) -> Vector2: return spot.call(data.map_home if id=="home" else data.map_spots[id])
	route.draw.connect(func():
		for pair in pairs:
			var a: Vector2=at_of.call(pair[0])
			var b: Vector2=at_of.call(pair[1])
			var known=(pair[0]=="home" or pair[0] in w.visited) and pair[1] in w.visited
			var n=int(a.distance_to(b)/9.0)
			for k in range(1,n):
				var p2=a.lerp(b,float(k)/n)
				route.draw_circle(p2,3.4 if known else 2.4,Color(0.35,0.2,0.08,0.95) if known else Color(1,1,1,0.75))
				if known: route.draw_circle(p2,2.0,Color("ffd65a")))
	var title=CareArt.tag(panel,"Green Meadows  ·  Robot parts %d / %d"%[found,robot],Rect2(28,26,330,PetUI.H_TAG),"map",true)
	title.position.x=28
	title.name="MapTitle"
	var close=CareArt.square(panel,"close",Rect2(width-62,14,48,48),app.toggle_world_map)
	close.name="CloseMap"
	var medal=clampf(art_size.y*0.1,36,54)
	var small=art_size.x<700
	var home=CareArt.tag(panel,"Home",Rect2(spot.call(data.map_home)+Vector2(-40,medal*0.2),Vector2(80,PetUI.H_TAG)),"home",true)
	home.name="HomeTag"
	for id in data.map_spots:
		var room=data.rooms[id]
		var at: Vector2=spot.call(data.map_spots[id])
		var seen=id in w.visited
		var hidden=0
		for chest in room.get("chests",[]):
			if not chest.id in w.opened: hidden+=1
		var piece="medal_ring" if id==current else ("medal_locked" if not seen else ("medal_open" if hidden>0 else "medal_done"))
		var m=PetUI.panel(panel,Rect2(at-Vector2.ONE*medal*0.5,Vector2.ONE*medal))
		m.name="Room_"+id
		PetUI.set_piece(m,piece)
		if id==current:
			var face=picture(m,"res://assets/ui/kit-v1/fox-medal.png",Rect2(medal*0.14,medal*0.14,medal*0.72,medal*0.72))
			face.show_behind_parent=true
			face.name="YouAreHere"
		if seen and hidden>0 and id!=current:
			CareArt.picture(m,"act_open",Rect2(medal*0.24,medal*0.24,medal*0.52,medal*0.52))
		if seen:
			var label=room.title
			if not small:
				if hidden>0: label+="  ·  %d chest%s"%[hidden,"" if hidden==1 else "s"]
				for g in room.get("gates",[]):
					if not app.game.has_ability(g.ability): label+="  ·  locked"
			var above=id in data.map_tag_above
			var y=at.y-medal*0.5-PetUI.H_TAG-2 if above else at.y+medal*0.5+2
			var tag=CareArt.tag(panel,label,Rect2(at.x-130,y,260,PetUI.H_TAG),"",true)
			tag.name="Tag_"+id
	# Next goal: a bouncing gold star over the place to go, and the step
	# written at the bottom of the map.
	var goal: Dictionary=app.game.world_goal()
	var next=CareArt.tag(panel,"Next: "+goal.text,Rect2(28,26+PetUI.H_TAG+6,width*0.62,PetUI.H_TAG),"star",true)
	next.position.x=28
	next.name="NextGoal"
	if data.map_spots.has(goal.room):
		var star=CareArt.picture(panel,"star",Rect2(spot.call(data.map_spots[goal.room])-Vector2(medal*0.4,medal*1.35),Vector2.ONE*medal*0.8))
		star.name="GoalStar"
		if not app.game.state.settings.reduced_motion:
			var bounce=star.create_tween().set_loops()
			bounce.tween_property(star,"position:y",star.position.y-8,0.45).set_trans(Tween.TRANS_SINE)
			bounce.tween_property(star,"position:y",star.position.y,0.45).set_trans(Tween.TRANS_SINE)

## V2 world bag on one screen (no scrolling): snacks to tap, crates,
## robot parts and the current quest step. Tapping a snack closes the bag and
## Foxy eats it in the world.
func build_world_bag() -> void:
	var width=minf(760,safe.size.x)
	var height=minf(400,safe.size.y)
	var box=Rect2(safe.get_center()-Vector2(width,height)/2,Vector2(width,height))
	var panel=CareArt.panel(content,box)
	panel.name="WorldBag"
	text(panel,"Your bag",Rect2(24,14,width-120,40),PetUI.F_TITLE)
	CareArt.square(panel,"close",Rect2(width-62,12,48,48),app.toggle_bag).name="CloseBag"
	var w=app.game.world()
	var pad=22.0
	var left_w=(width-pad*3)*0.56
	var right_x=pad*2+left_w
	var right_w=width-right_x-pad
	# Snacks
	text(panel,"Snacks for %s (tap to give)"%app.game.pet().name,Rect2(pad,62,left_w,26),17)
	var data=GameState.foods()
	var ids=[]
	for id in data.order:
		if id!="kibble": ids.append(id)
	var cols=3
	var tile_w=(left_w-(cols-1)*8)/cols
	# Three rows of tiles: two of snacks, one of things you found.
	var tile_h=floorf((height-94-pad-16-30)/3)
	var tiles=[]
	for i in range(ids.size()):
		var id: String=ids[i]
		var count=app.game.food_count(id)
		var b=button(panel,data.foods[id].short,Rect2(pad+(i%cols)*(tile_w+8),94+int(i/cols)*(tile_h+8),tile_w,tile_h),func(): app.toggle_bag(); if is_instance_valid(app.active_world): app.active_world.give_snack(id),"food_"+id,false,"tile")
		b.name="Snack_"+id
		b.clip_text=true
		b.disabled=count<1
		var badge=CareArt.tag(b,"%d"%count,Rect2(6,6,30,24))
		badge.size=Vector2(30,24)
		(badge.get_meta("compose") as Dictionary).layout="row"
		(badge.get_meta("compose") as Dictionary).points=13
		PetUI.arrange(badge)
		tiles.append(b)
	# Found on the way: jump carrots to use, the Sky Feather and the key.
	var found_y=94+2*(tile_h+8)
	text(panel,"Found on the way",Rect2(pad,found_y,left_w,26),17)
	var found=[
		["Jump carrot","res://assets/art/meadows-v2/pickup_carrot.png",w.get("carrots",0)>0,"%d"%int(w.get("carrots",0))],
		["Sky Feather","res://assets/art/meadows-v2/sky_feather.png","foxy_boost" in w.abilities,""],
		["Golden key","res://assets/art/meadows-v2/pickup_key.png","tower_key" in w.opened,""]]
	for i in range(found.size()):
		var f: Array=found[i]
		var b=button(panel,f[0],Rect2(pad+i*(tile_w+8),found_y+30,tile_w,tile_h),func(): pass,f[1],false,"tile")
		b.name="Found_"+String(f[0]).to_pascal_case()
		b.clip_text=true
		if i==0:
			b.pressed.connect(func(): app.toggle_bag(); if is_instance_valid(app.active_world): app.active_world.use_carrot())
			b.disabled=not f[2] or (is_instance_valid(app.active_world) and app.active_world.super_jump)
			var badge=CareArt.tag(b,f[3],Rect2(6,6,30,24))
			badge.size=Vector2(30,24)
			(badge.get_meta("compose") as Dictionary).layout="row"
			(badge.get_meta("compose") as Dictionary).points=13
			PetUI.arrange(badge)
		else:
			b.mouse_filter=Control.MOUSE_FILTER_IGNORE
			b.focus_mode=Control.FOCUS_NONE
			b.modulate=Color.WHITE if f[2] else Color(1,1,1,0.45)
		b.custom_minimum_size=Vector2.ZERO
		b.size=Vector2(tile_w,tile_h)
	PetUI.unify(tiles)
	# Robot parts
	text(panel,"Robot parts",Rect2(right_x,62,right_w,26),17)
	var parts=["robot_head","robot_arm","robot_body","robot_wheel"]
	var cell=minf((right_w-24)/4,64)
	for i in range(parts.size()):
		var have=int(w.parts.get(parts[i],0))>0
		var slot=PetUI.panel(panel,Rect2(right_x+i*(cell+8),94,cell,cell))
		PetUI.set_piece(slot,"tile_gold" if have else "tile","",12.0)
		var art_path="res://assets/art/meadows-v2/"+parts[i]+".png"
		if ResourceLoader.exists(art_path):
			var img=picture(slot,art_path,Rect2(6,6,cell-12,cell-12))
			img.modulate=Color.WHITE if have else Color(0.2,0.2,0.25,0.35)
	var free=app.game.world_crates_free()
	# Crates wait in the bag; tap to get ready to put one down in the world.
	var crate_btn=button(panel,"Place a crate  (%d in the bag)"%free if free>0 else ("Crates: %d placed"%(w.crates-free) if w.crates>0 else "No crates yet: Foxy can dig them up"),Rect2(right_x,104+cell,right_w,PetUI.H_TAG+6),func(): app.toggle_bag(); if is_instance_valid(app.active_world): app.active_world.start_placing(),"act_place")
	crate_btn.name="CratesTag"
	crate_btn.disabled=free<=0
	var stage="Talk to Moss the bunny in Meadow Fields" if not "picnic_asked" in w.opened else ("Find Moss's picnic basket at the top of the Old Tower" if not "picnic_basket" in w.opened else ("Bring the picnic basket to Moss in Meadow Fields" if not "picnic_done" in w.opened else "Picnic done!"))
	var quest=CareArt.strip(panel,Rect2(right_x,118+cell+PetUI.H_TAG,right_w,PetUI.H_BUTTON+6))
	PetUI.compose(quest,"The Lost Picnic\n"+stage,CareArt.icon("basket"),"left",16)
	quest.name="QuestRow"
	var back=button(panel,"Back to the adventure",Rect2(right_x,height-pad-PetUI.H_BUTTON,right_w,PetUI.H_BUTTON),app.toggle_bag,"back",true)
	back.name="BackToAdventure"

func reward_row(parent: Node, rect: Rect2, caption: String, amount: int, gold=false) -> Panel:
	var panel=CareArt.strip(parent,rect,gold)
	PetUI.compose(panel,caption,ArtTexture.load_texture(PetUI.COIN_PATH),"row" if gold else "left",22 if gold else 19)
	panel.get_node("Content/Symbol").name="CoinIcon"
	if gold: panel.get_node("Content/Caption").name="Total"
	else:
		var value=centered(panel,"+%d"%amount,Rect2(rect.size.x-PetUI.ROW_INSET-80,0,80,rect.size.y),22)
		value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	return panel

func build_result() -> void:
	room_view.visible=false
	var adventure=mode=="result"
	var wanted=(520.0 if adventure else 300.0) if not compact() else logical_size.y
	var reward: Dictionary=app.game.state.quest_state.get("last_completion",{}) if adventure else {}
	var level_name="The Lost Picnic" if reward.get("level_id","W01_L01")=="W01_L01" else "Windmill Walk"
	var parts=CareArt.header(content,safe,level_name if adventure else "Catch the Ball",Callable(),"",Callable())
	wallet_value=parts.wallet_label
	var top=safe.position.y+PetUI.H_HEADER+10
	var width=minf(440,safe.size.x) if not portrait() else safe.size.x
	var height=minf(safe.end.y-top,wanted)
	var x=safe.end.x-width if not portrait() else safe.position.x
	var y=top+(safe.end.y-top-height)*(1.0 if portrait() else .5)
	# Portrait: the celebration picture fills the space above the card so the
	# child, Foxy and Moss stay visible instead of sitting behind it.
	var scene=picture(content,"res://assets/ui/care-v1/picnic-finish.png",Rect2(Vector2.ZERO,Vector2(logical_size.x,y+40) if portrait() else logical_size),true)
	scene.name="Celebration"
	if portrait():
		# Keep the left two thirds, where the child, Foxy and Moss sit.
		var focus=AtlasTexture.new()
		focus.atlas=scene.texture
		focus.region=Rect2(0,0,scene.texture.get_width()*.66,scene.texture.get_height())
		scene.texture=focus
	content.move_child(scene,room_view.get_index()+1)
	var card=CareArt.panel(content,Rect2(x,y,width,height))
	card.name="ResultCard"
	var inner=width-32
	var title=text(card,("A picnic, together!" if level_name=="The Lost Picnic" else "Delivery complete!") if adventure else "Lovely time together",Rect2(16,12,inner,40),30)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var line=text(card,("Basket returned." if level_name=="The Lost Picnic" else "Food delivered to the windmill.") if adventure else "A lovely game of fetch. Happiness and bond saved.",Rect2(16,50,inner,30),18)
	line.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var row_y=88.0
	if adventure and not reward.is_empty() and compact():
		var summary=text(card,"Adventure +%d · Trail +%d · Discovery +%d"%[reward.base_coins,reward.pickup_coins,reward.discovery_coins],Rect2(16,row_y-6,inner,26),15)
		summary.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		reward_row(card,Rect2(16,row_y+22,inner,46),"Earned %d coins"%reward.total_coins,reward.total_coins,true)
		var note=text(card,("New memory saved" if reward.new_keepsake else "Memory collected")+" · +%d Berry bowl · +%d bond XP"%[reward.meals,reward.bond],Rect2(16,row_y+72,inner,26),15)
		note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	elif adventure and not reward.is_empty():
		var row_h=clampf((height-88-196)/4.6,38,50)
		for entry in [["Adventure",reward.base_coins],["Trail coins",reward.pickup_coins],["First discovery",reward.discovery_coins]]:
			reward_row(card,Rect2(16,row_y,inner,row_h),entry[0],entry[1])
			row_y+=row_h+6
		reward_row(card,Rect2(16,row_y+2,inner,row_h+6),"Earned %d coins"%reward.total_coins,reward.total_coins,true)
		row_y+=row_h+16
		var memory=CareArt.strip(card,Rect2(16,row_y,inner,58))
		memory.name="MemoryRow"
		PetUI.compose(memory,("New memory" if reward.new_keepsake else "Memory collected")+"\n+%d Berry bowl%s · +%d bond XP · Saved"%[reward.meals,"s" if reward.meals>1 else "",reward.bond],CareArt.icon("basket"),"left",18)
		CareArt.picture(memory,"check",Rect2(inner-PetUI.ROW_INSET-30,14,30,30))
		row_y+=66
	var buttons_y=height-16-PetUI.H_PRIMARY
	var half=(inner-10)/2
	var home=button(card,"My Pet",Rect2(16,buttons_y,half,PetUI.H_PRIMARY),app.show_home,"paw",true)
	home.name="MyPet"
	var again=button(card,"Play again",Rect2(26+half,buttons_y,half,PetUI.H_PRIMARY),(func(): app.show_adventure(reward.get("level_id","W01_L01"))) if adventure else app.show_ball,"play")
	again.name="PlayAgain"
	PetUI.unify([home,again])

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
	if is_instance_valid(rest_button): rest_button.get_node("Content/Caption").text="Wake" if pet.sleeping else "Rest"
	if is_instance_valid(care_button) and is_instance_valid(app.home): care_button.disabled=app.home.busy()
	if is_instance_valid(pet_badge) and is_instance_valid(app.home):
		var home=app.home
		var point=(app.world.transform*home.pet_art.position)/home.room_size*logical_size
		var pet_height=float(home.STAGE_HEIGHTS[pet.growth_stage])*home.room_scale()/home.room_size.y*logical_size.y
		# Beside Foxy's head, on the side away from the child, so it never covers him.
		pet_badge.position=Vector2(clampf(point.x+pet_height*.35,safe.position.x,safe.end.x-pet_badge.size.x),point.y-pet_height-pet_badge.size.y*.5).round()

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
