extends "res://scripts/ui/main_menu.gd"
## V05 native screen. Shares menu settings, motion preference and illustrated UI;
## adoption itself still uses the existing ordered durable GameState transaction.
var name_input: LineEdit
var adopt_button: Button
var card: Panel
var portrait_frame: Panel
var fox_portrait: TextureRect
var heading: Label
var heading_panel: Panel
var traits: Label
var name_caption: Label
var description: Label
var card_title: Label
var retry_button: Button
var bed: TextureRect
var room_source: Texture2D

func display_label(parent: Node, text: String, font_size: int) -> Label:
	var result=PetUI.label(parent,text,Vector2.ZERO,font_size)
	result.add_theme_font_override("font",load(PetUI.MENU_FONT_PATH))
	return result

func picture(path: String, parent: Node) -> TextureRect:
	var result=TextureRect.new()
	result.texture=ArtTexture.load_texture(path)
	result.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	result.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(result)
	return result

func _ready() -> void:
	name="Adoption"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	background=picture("res://assets/ui/adoption-v1/room.png",self)
	room_source=background.texture
	background.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	heading_panel=PetUI.panel(self,Rect2())
	PetUI.set_piece(heading_panel,"hud_plank")
	heading_panel.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	heading=display_label(heading_panel,"Meet Foxy",36)
	heading.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	var value=PetUI.coin_display(self,Vector2.ZERO,"",true)
	value.text="0"
	value.add_theme_font_override("font",load(PetUI.MENU_FONT_PATH))
	wallet=value.get_parent()
	wallet.get_child(1).visible=false
	wallet.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	bed=picture("res://assets/art/home-v1/bed-states.png",self)
	var bed_atlas=AtlasTexture.new()
	bed_atlas.atlas=bed.texture
	bed_atlas.region=Rect2(40,140,944,500)
	bed_atlas.filter_clip=true
	bed.texture=bed_atlas
	contact_shadow=preload("res://scripts/ui/menu_contact_shadow.gd").new()
	add_child(contact_shadow)
	friends=preload("res://scripts/ui/menu_friends.gd").new()
	add_child(friends)
	card=PetUI.panel(self,Rect2())
	PetUI.set_piece(card,"panel","",22.0)
	card.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	portrait_frame=PetUI.panel(card,Rect2(),Color("f8e9c9"))
	PetUI.set_piece(portrait_frame,"card","",14.0)
	fox_portrait=picture("res://assets/ui/adoption-v1/foxy.png",portrait_frame)
	var atlas=AtlasTexture.new()
	atlas.atlas=fox_portrait.texture
	atlas.region=Rect2(220,180,860,900)
	atlas.filter_clip=true
	fox_portrait.texture=atlas
	card_title=display_label(card,"Your new little friend",28)
	traits=display_label(card,"Curious  ·  Playful",22)
	traits.add_theme_color_override("font_color",Color("476348"))
	name_caption=display_label(card,"Name",24)
	name_input=LineEdit.new()
	name_input.text="Foxy"
	name_input.max_length=20
	name_input.virtual_keyboard_enabled=true
	name_input.virtual_keyboard_type=LineEdit.KEYBOARD_TYPE_DEFAULT
	name_input.add_theme_font_override("font",load(PetUI.MENU_FONT_PATH))
	name_input.add_theme_font_size_override("font_size",26)
	name_input.add_theme_color_override("font_color",PetUI.INK)
	var field=PetUI.style(Color("fff8e8"),8)
	field.border_color=PetUI.WOOD
	name_input.add_theme_stylebox_override("normal",field)
	var focus=field.duplicate()
	focus.border_color=PetUI.BLUE
	focus.set_border_width_all(3)
	name_input.add_theme_stylebox_override("focus",focus)
	card.add_child(name_input)
	description=PetUI.label(card,"A friend to explore with.",Vector2.ZERO,20)
	description.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	adopt_button=PetUI.menu_button(card,"Adopt Foxy",adopt,true)
	adopt_button.add_theme_stylebox_override("normal",PetUI.menu_style(true))
	adopt_button.set_meta("animate_symbol",false)
	actions.append(adopt_button)
	practice=PetUI.menu_button(card,"Back",app.show_menu)
	settings=CareArt.square(self,"gear",Rect2(0,0,52,52),toggle_settings)
	settings_icon=settings.get_node("Content/Symbol")
	status=PetUI.label(card,"",Vector2.ZERO,16)
	status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	status.visible=false
	retry_button=PetUI.menu_button(card,"Retry load",retry_load)
	# Shared A48 layout: same frames, insets and text sizes as every screen.
	PetUI.compose(adopt_button,"Adopt Foxy",CareArt.icon("paw"),"row",PetUI.F_BUTTON)
	PetUI.compose(practice,"Back",CareArt.icon("back"),"row",PetUI.F_BUTTON)
	PetUI.compose(retry_button,"Retry load",null,"row",PetUI.F_BUTTON)
	heading.visible=false
	PetUI.compose(heading_panel,"Meet Foxy",null,"left",PetUI.F_TITLE-4)
	wallet.get_child(2).visible=false
	wallet.get_node("CoinIcon").visible=false
	PetUI.set_piece(wallet,"wallet")
	PetUI.compose(wallet,"0",ArtTexture.load_texture(PetUI.COIN_PATH),"left",PetUI.F_BUTTON+4)
	retry_button.visible=app.game.store.blocked
	adopt_button.disabled=app.game.store.blocked
	if app.game.store.blocked: show_feedback("Your save needs recovery. Retry loading before adopting.")
	app.game.feedback.connect(show_feedback)
	name_input.text_submitted.connect(func(_text): adopt_button.grab_focus())
	layout(Vector2(get_window().content_scale_size),Rect2(12,12,1256,696))
	adopt_button.grab_focus()

func adopt() -> void:
	if adopt_button.disabled: return
	if not app.game.adopt(name_input.text):
		show_feedback("Your friend could not be saved. Please try again.")
		return
	adopt_button.disabled=true
	if app.next_after_adoption.is_valid(): app.next_after_adoption.call()
	else: app.show_home()

func retry_load() -> void:
	app.game.load_game()
	if not app.game.state.is_empty():
		app.continue_game()
		return
	retry_button.visible=app.game.store.blocked
	adopt_button.disabled=app.game.store.blocked
	status.visible=app.game.store.blocked
	last_layout=""
	layout(logical_size,safe)

func layout(dimensions: Vector2, bounds: Rect2) -> void:
	logical_size=dimensions
	safe=bounds
	# Keyboard appearance changes the available card area without rebuilding the
	# LineEdit, losing the typed name, or moving the entry below the keyboard.
	var keyboard_height=0.0
	if OS.get_name() in ["Android","iOS"]:
		keyboard_height=DisplayServer.virtual_keyboard_get_height()*dimensions.y/maxf(1,get_window().size.y)
	var signature=str([dimensions,bounds,is_instance_valid(modal),keyboard_height,retry_button.visible])
	if last_layout==signature: return
	last_layout=signature
	place(background,Rect2(Vector2.ZERO,dimensions))
	var portrait=dimensions.x<dimensions.y
	if not portrait: background.texture=room_source
	var inner_x=0.0
	var inner_w=0.0
	if portrait:
		var w=minf(400,safe.size.x)
		var x=safe.get_center().x-w/2
		var h=PetUI.touch_height(PetUI.H_HEADER,self,dimensions.y)
		place(settings,Rect2(safe.end.x-h,safe.position.y,h,h))
		place(wallet,Rect2(safe.end.x-h-8-118,safe.position.y,118,h))
		place(heading_panel,Rect2(safe.position.x,safe.position.y,safe.end.x-h-8-118-8-safe.position.x,h))
		var bottom=minf(safe.end.y,dimensions.y-keyboard_height-12)
		var card_h=430.0
		var card_top=bottom-card_h
		# The measured source floor starts at y530. Keep it above the pair's
		# contact on both tall and short phones instead of using one wall crop.
		var floor_fraction=clampf((card_top-34)/dimensions.y,0.05,0.7)
		var crop_y=clampf((530-floor_fraction*room_source.get_height())/(1-floor_fraction),0,360)
		var room_crop=AtlasTexture.new()
		room_crop.atlas=room_source
		room_crop.region=Rect2(0,crop_y,room_source.get_width(),room_source.get_height()-crop_y)
		background.texture=room_crop
		place(card,Rect2(x,card_top,w,card_h))
		var pair_h=minf(230,card_top-safe.position.y-72)
		friends.visible=pair_h>=100
		contact_shadow.visible=friends.visible
		place(friends,Rect2(x+20,card_top-pair_h-6,pair_h*1.13,pair_h))
		bed.visible=friends.visible
		place(bed,Rect2(x+w-128,card_top-82,120,72))
		place(portrait_frame,Rect2(20,20,96,106))
		place(fox_portrait,Rect2(4,4,88,98))
		place(card_title,Rect2(130,24,w-150,64))
		card_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		card_title.add_theme_font_size_override("font_size",23)
		place(traits,Rect2(130,94,w-148,30))
		traits.add_theme_font_size_override("font_size",16)
		inner_x=24
		inner_w=w-48
		place(name_caption,Rect2(inner_x,144,inner_w,28))
		place(name_input,Rect2(inner_x,178,inner_w,58))
		place(description,Rect2(inner_x,244,inner_w,30))
		var button_h=PetUI.touch_height(PetUI.H_BUTTON,self,dimensions.y)
		place(adopt_button,Rect2(inner_x,282,inner_w,maxf(PetUI.H_PRIMARY,button_h)))
		place(practice,Rect2(inner_x,350,inner_w,button_h))
		place(status,Rect2(inner_x,126,inner_w,50))
		place(retry_button,Rect2(inner_x,282,inner_w,PetUI.H_PRIMARY))
	else:
		# Fixed 1280x720 canvas: roles are 1.2x the 600-point screens.
		place(heading_panel,Rect2(40,24,360,64))
		place(wallet,Rect2(1036,24,148,64))
		place(settings,Rect2(1192,24,64,64))
		place(friends,Rect2(160,270,390,344))
		bed.visible=true
		place(bed,Rect2(40,500,192,112))
		friends.visible=true
		contact_shadow.visible=true
		place(card,Rect2(586,130,650,532))
		place(portrait_frame,Rect2(24,40,224,380))
		place(fox_portrait,Rect2(12,52,200,276))
		place(card_title,Rect2(270,42,355,60))
		card_title.add_theme_font_size_override("font_size",28)
		place(traits,Rect2(270,114,355,34))
		traits.add_theme_font_size_override("font_size",22)
		inner_x=270
		inner_w=354
		place(name_caption,Rect2(inner_x,170,inner_w,34))
		place(name_input,Rect2(inner_x,211,inner_w,62))
		place(description,Rect2(inner_x,288,inner_w,42))
		place(adopt_button,Rect2(inner_x,356,inner_w,72))
		place(practice,Rect2(inner_x,440,inner_w,64))
		place(status,Rect2(28,434,218,70))
		place(retry_button,Rect2(inner_x,356,inner_w,72))
	var scale_value=1.0 if portrait else 1.2
	for b in [adopt_button,practice,retry_button]:
		(b.get_meta("compose") as Dictionary).points=int(PetUI.F_BUTTON*scale_value)
		PetUI.arrange(b)
	(heading_panel.get_meta("compose") as Dictionary).points=int((PetUI.F_TITLE-4)*scale_value)
	(wallet.get_meta("compose") as Dictionary).points=int((PetUI.F_BUTTON+4)*scale_value)
	for c in [heading_panel,wallet,settings]: PetUI.arrange(c)
	place(contact_shadow,Rect2(friends.position+Vector2(0,friends.size.y-7),Vector2(friends.size.x,12)))
	contact_shadow.queue_redraw()
	if is_instance_valid(modal): layout_settings()
