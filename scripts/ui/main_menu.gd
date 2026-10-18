extends Control
## Native responsive menu; illustrations never contain interactive text or hitboxes.
var app: Control
var background: TextureRect
var logo: TextureRect
var friends: Control
var actions: Array[Button]=[]
var practice: Button
var settings: Button
var wallet: Panel
var modal: Control
var settings_panel: Panel
var settings_scroll: ScrollContainer
var settings_close: Button
var status: Label
var settings_feedback: Label
var collection_subtitle: Label
var collection_title: Label
var collection_text: VBoxContainer
var settings_content: HBoxContainer
var settings_icon: Control
var settings_title: Label
var version_tag: Label
var contact_shadow: Control
var motion_preference: Variant=null
var last_layout=""
var logical_size=Vector2(1280,720)
var safe=Rect2(12,12,1256,696)

func art(path: String, region=Rect2()) -> TextureRect:
	var picture=TextureRect.new()
	var source: Texture2D=null if path.is_empty() else ArtTexture.load_texture("res://assets/ui/menu-v1/"+path+".png")
	if region.size!=Vector2.ZERO:
		var atlas=AtlasTexture.new()
		atlas.atlas=source
		atlas.region=region
		picture.texture=atlas
	else: picture.texture=source
	picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter=Control.MOUSE_FILTER_IGNORE
	picture.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(picture)
	return picture

func _ready() -> void:
	name="MainMenu"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	# A55 paper menu loads only its own art (see paper_skin).
	background=art("" if ArtStyle.paper else "meadow")
	background.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	logo=art("" if ArtStyle.paper else "logo",Rect2() if ArtStyle.paper else Rect2(96,110,1768,580))
	contact_shadow=preload("res://scripts/ui/menu_contact_shadow.gd").new()
	add_child(contact_shadow)
	friends=preload("res://scripts/ui/menu_friends.gd").new()
	add_child(friends)
	var fresh=app.game.state.is_empty()
	var primary=PetUI.menu_button(self,"Start" if fresh else "Continue",app.continue_game,true)
	primary.tooltip_text="Meet Foxy and begin The Lost Picnic" if fresh else ("Resume your adventure" if not app.game.state.pending_run.is_empty() else "Return to your pet")
	actions.append(primary)
	actions.append(PetUI.menu_button(self,"My Pet",app.show_home))
	actions.append(PetUI.menu_button(self,"Adventures",app.show_map))
	var collection=PetUI.menu_button(self,"Collection",app.show_collection)
	collection.disabled=false
	collection.tooltip_text="More friends and discoveries are coming later."
	actions.append(collection)
	# Every action uses the shared PetUI.compose row: one icon inset, centred caption.
	var kinds=["play","paw","map","bond"]
	for i in range(actions.size()):
		PetUI.compose(actions[i],actions[i].text if i<3 else "Collection\nPets & memories",CareArt.icon(kinds[i]),"row",24)
	for b in actions: PetUI.set_frame_weight(b,PetUI.CORNER_BOARD)
	collection_title=collection.get_node("Content/Caption")
	collection_subtitle=collection.get_node("Content/Subcaption")
	practice=PetUI.menu_button(self,"Games",app.show_minigames)
	settings=PetUI.menu_button(self,"Settings",func(): app.show_settings())
	settings.set_meta("animate_symbol",false)
	PetUI.compose(practice,"Games",CareArt.icon("ball"),"row",20)
	PetUI.compose(settings,"Settings",CareArt.icon("gear"),"row",20)
	settings_icon=settings.get_node("Content/Symbol")
	settings_title=settings.get_node("Content/Caption")
	var value=PetUI.coin_display(self,Vector2.ZERO,"Coins",true)
	value.text="0" if fresh else str(app.game.state.coins)
	wallet=value.get_parent()
	wallet.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	wallet.get_node("CoinIcon").texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	value.add_theme_font_override("font",load(PetUI.MENU_FONT_PATH))
	# The original label keeps the value for code/tests; the visible content is the shared layout.
	value.visible=false
	wallet.get_node("CoinIcon").visible=false
	PetUI.set_piece(wallet,"wallet")
	PetUI.compose(wallet,value.text,ArtTexture.load_texture(PetUI.COIN_PATH),"left",PetUI.F_BUTTON+4)
	status=PetUI.label(self,"",Vector2.ZERO,16,PetUI.INK,300)
	status.visible=app.game.store.blocked
	status.text="Your save needs recovery. Practice is still available."
	version_tag=PetUI.label(self,"v"+str(ProjectSettings.get_setting("application/config/version","dev")),Vector2.ZERO,14,PetUI.INK)
	version_tag.add_theme_color_override("font_color",Color.WHITE)
	version_tag.add_theme_color_override("font_outline_color",Color("3b2412"))
	version_tag.add_theme_constant_override("outline_size",5)
	app.game.feedback.connect(show_feedback)
	if status.visible: primary.disabled=true
	if ArtStyle.paper: paper_skin()
	layout(Vector2(get_window().content_scale_size),Rect2(12,12,1256,696))
	primary.grab_focus()

## A55 (P11): the paper menu. Background is the concept's clean plate (the
## explorer and Foxy are part of it), planks and icons come from the kit
## copied from the concept, every word is drawn live.
const PAPER_MENU="res://assets/ui/menu-paper/"
const SKY=[15,32,52]
var tagline: TextureRect
var sky_band: ColorRect
var sign_words: Label
func paper_tex(name: String) -> Texture2D: return ArtTexture.load_texture(PAPER_MENU+name+".png")
func paper_box(name: String, tint=Color.WHITE) -> StyleBoxTexture:
	var box=StyleBoxTexture.new()
	box.texture=paper_tex(name)
	box.modulate_color=tint
	return box
func paper_plank(button: Button, plank: String, icon: Texture2D, caption: String, ink: Color, points: int) -> void:
	for state in ["normal","hover","focus","disabled"]: button.add_theme_stylebox_override(state,paper_box(plank))
	button.add_theme_stylebox_override("pressed",paper_box(plank,Color(0.86,0.83,0.8)))
	PetUI.compose(button,caption,icon,"row",points,ink)
func paper_skin() -> void:
	background.texture=paper_tex("plate")
	sky_band=ColorRect.new()
	sky_band.color=Color8(SKY[0],SKY[1],SKY[2])
	sky_band.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(sky_band)
	move_child(sky_band,0)
	sign_words=Label.new()
	sign_words.text="Green\nMeadows"
	sign_words.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	sign_words.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	sign_words.add_theme_font_override("font",load(PetUI.MENU_FONT_PATH))
	sign_words.add_theme_color_override("font_color",Color("3b2410"))
	sign_words.add_theme_constant_override("line_spacing",-4)
	sign_words.rotation=-0.05
	sign_words.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(sign_words)
	logo.texture=paper_tex("logo")
	friends.visible=false
	contact_shadow.visible=false
	tagline=TextureRect.new()
	tagline.texture=paper_tex("tagline")
	tagline.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	tagline.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(tagline)
	var words=Label.new()
	words.name="Tagline"
	words.text="Little Friends, Big Adventures"
	words.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	words.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	words.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	words.add_theme_font_override("font",load(PetUI.MENU_FONT_PATH))
	words.add_theme_color_override("font_color",PetUI.INK)
	tagline.add_child(words)
	var navy=PetUI.INK
	var icons=[paper_tex("ic_play"),paper_tex("ic_paw"),paper_tex("ic_map"),ArtTexture.load_texture("res://assets/ui/paper-v1/heart_full.png")]
	for i in range(actions.size()):
		var caption=actions[i].text if i<3 else "Collection\nPets & memories"
		paper_plank(actions[i],"plank_green" if i==0 else "plank_cream",icons[i],caption,Color("fff3d6") if i==0 else navy,24)
	collection_title=actions[3].get_node("Content/Caption")
	collection_subtitle=actions[3].get_node("Content/Subcaption")
	paper_plank(practice,"plank_small",paper_tex("ic_pad"),"Games",navy,20)
	paper_plank(settings,"plank_small",paper_tex("ic_gear"),"Settings",navy,20)
	settings_icon=settings.get_node("Content/Symbol")
	settings_title=settings.get_node("Content/Caption")
	for state in ["panel"]: wallet.add_theme_stylebox_override(state,paper_box("coin_plaque"))
	PetUI.compose(wallet,str(app.game.state.get("coins",0)) if not app.game.state.is_empty() else "0",paper_tex("coin"),"left",PetUI.F_BUTTON+4)

func hide_native_caption(button: Button) -> void:
	# Keep the native action name for accessibility/input; the visible content has
	# one container responsible for its line spacing and shared vertical center.
	for state_name in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color"]:
		button.add_theme_color_override(state_name,Color.TRANSPARENT)

func _process(_delta: float) -> void:
	var reduced=bool(app.game.preferences().reduced_motion)
	if reduced==motion_preference: return
	motion_preference=reduced
	friends.reduced_motion=reduced
	for b in actions+[practice,settings]:
		b.set_meta("reduced_motion",reduced)
		b.get_node("MenuButtonMotion").refresh()

func show_feedback(message: String) -> void:
	if is_instance_valid(modal) and is_instance_valid(settings_feedback): settings_feedback.text=message
	else:
		status.text=message
		status.visible=true

func place(control: Control, bounds: Rect2) -> void:
	control.position=bounds.position
	control.size=bounds.size
	control.set_meta("layout_size",bounds.size)

func layout(dimensions: Vector2, bounds: Rect2) -> void:
	logical_size=dimensions
	safe=bounds
	var signature=str([dimensions,bounds,is_instance_valid(modal)])
	if signature==last_layout: return
	last_layout=signature
	place(background,Rect2(Vector2.ZERO,dimensions))
	var portrait=dimensions.x<dimensions.y
	if ArtStyle.paper:
		# The plate is landscape: in portrait it slides down and centres on the
		# explorer and Foxy so they show below the buttons; the top is sky.
		background.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED if not portrait else TextureRect.STRETCH_SCALE
		place(sky_band,Rect2(Vector2.ZERO,dimensions))
		sign_words.visible=not portrait
		if portrait:
			var k=dimensions.y/720.0*0.74
			var drop=dimensions.y-720.0*k
			place(background,Rect2(dimensions.x*0.5-704.0*k,drop,1280.0*k,720.0*k))
		else:
			var k=maxf(dimensions.x/1280.0,dimensions.y/720.0)
			var at=(dimensions-Vector2(1280,720)*k)*0.5
			place(sign_words,Rect2(at+Vector2(1116,318)*k,Vector2(132,98)*k))
			sign_words.add_theme_font_size_override("font_size",int(24*k))
	if portrait:
		var x=safe.position.x
		var y=safe.position.y
		var w=safe.size.x
		var short_screen=safe.size.y<760
		var logo_h=68.0 if short_screen else 82.0
		var row_h=72.0 if short_screen else 76.0
		var gap=6.0
		var button_w=minf(282 if w<460 else 304,w-24)
		var button_x=x+(w-button_w)/2
		place(wallet,Rect2(x+w-118,y,118,PetUI.H_HEADER))
		place(logo,Rect2(x+4,y+58,w-8,logo_h))
		var top=y+58+logo_h+12
		if is_instance_valid(tagline):
			place(tagline,Rect2(x+(w-260)/2,y+58+logo_h-2,260,36))
			top+=34
		for i in range(actions.size()):
			place(actions[i],Rect2(button_x,top+i*(row_h+gap),button_w,row_h))
			var font_size=24
			actions[i].add_theme_font_size_override("font_size",font_size)
		var action_end=top+4*row_h+3*gap
		var pair_h=minf(220 if short_screen else 236,safe.end.y-68-action_end-16)
		place(friends,Rect2(x+(w-pair_h*1.13)/2,safe.end.y-68-pair_h,pair_h*1.13,pair_h))
		var footer_w=minf(140,(w-34)/2)
		var footer_x=x+(w-footer_w*2-12)/2
		place(practice,Rect2(footer_x,safe.end.y-56,footer_w,56))
		place(settings,Rect2(footer_x+footer_w+12,safe.end.y-56,footer_w,56))
		place(status,Rect2(x+12,top-34,w-24,34))
		place(version_tag,Rect2(x+6,y+16,100,24))
	elif ArtStyle.paper:
		# Measured on concept P11 (1672x941 -> 1280x720).
		place(logo,Rect2(78,44,500,124))
		place(tagline,Rect2(150,160,380,52))
		for i in range(actions.size()):
			place(actions[i],Rect2(115,236+i*110,384,100))
			actions[i].add_theme_font_size_override("font_size",34)
		place(wallet,Rect2(1011,40,218,96))
		place(practice,Rect2(905,615,176,78))
		place(settings,Rect2(1091,615,176,78))
	else:
		place(logo,Rect2(56,28,550,180))
		place(friends,Rect2(640,256,380,336))
		for i in range(actions.size()):
			place(actions[i],Rect2(150,224+i*108,352,104))
			actions[i].add_theme_font_size_override("font_size",34)
		place(wallet,Rect2(1108,24,148,64))
		place(practice,Rect2(852,610,196,92))
		place(settings,Rect2(1060,610,196,92))
		place(status,Rect2(150,198,352,32))
		place(version_tag,Rect2(24,690,132,24))
	wallet.get_child(1).visible=false
	if is_instance_valid(tagline):
		var words: Label=tagline.get_node("Tagline")
		words.add_theme_font_size_override("font_size",int(tagline.size.y*0.42))
	(wallet.get_meta("compose") as Dictionary).points=int((PetUI.F_BUTTON+4)*(1.0 if portrait else 1.2))
	PetUI.arrange(wallet)
	for b in actions+[practice,settings]:
		var spec: Dictionary=b.get_meta("compose")
		spec.points=(24 if portrait else 32) if b in actions else (18 if portrait else 20)
		b.size=b.get_meta("layout_size")
		PetUI.arrange(b)
		b.get_node("MenuButtonMotion").refresh()
	PetUI.unify([practice,settings])
	var shadow_height=maxf(7,roundf(friends.size.y*0.05))
	place(contact_shadow,Rect2(friends.position+Vector2(0,friends.size.y-shadow_height*0.35),Vector2(friends.size.x,shadow_height)))
	contact_shadow.queue_redraw()
	if is_instance_valid(modal): layout_settings()

func toggle_settings() -> void:
	if is_instance_valid(modal):
		modal.queue_free()
		modal=null
		for b in actions+[practice,settings]: b.focus_mode=Control.FOCUS_ALL
		settings.grab_focus()
		last_layout=""
		return
	modal=Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(modal)
	var dim=ColorRect.new()
	dim.color=Color(0.03,0.08,0.16,0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(dim)
	settings_panel=PetUI.panel(modal,Rect2(0,0,350,580))
	PetUI.set_piece(settings_panel,"panel","",22.0)
	PetUI.label(settings_panel,"Settings",Vector2(22,18),28)
	settings_scroll=ScrollContainer.new()
	settings_scroll.position=Vector2(18,65)
	settings_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	settings_panel.add_child(settings_scroll)
	var column=VBoxContainer.new()
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",10)
	settings_scroll.add_child(column)
	var prefs=app.game.preferences()
	var motion=PetUI.button(column,"Reduced motion: "+("On" if prefs.reduced_motion else "Off"),Rect2(0,0,0,56),func():
		if app.game.set_preference("reduced_motion",not app.game.preferences().reduced_motion):
			column.get_child(0).text="Reduced motion: "+("On" if app.game.preferences().reduced_motion else "Off"))
	motion.custom_minimum_size=Vector2(0,56)
	for spec in [["touch_size","Button size",[52,60,68],["Compact","Comfort","Large"]],["touch_spacing","Spacing",[0,12,24],["Close","Comfort","Wide"]],["touch_raise","Button height",[0,16,32],["Low","Middle","High"]]]:
		var caption=PetUI.label(column,spec[1],Vector2.ZERO,18)
		caption.custom_minimum_size.y=28
		var row=HBoxContainer.new()
		row.add_theme_constant_override("separation",6)
		column.add_child(row)
		for i in range(3):
			var key=spec[0]
			var value=spec[2][i]
			var b=PetUI.button(row,spec[3][i],Rect2(0,0,0,56),func(): pass)
			b.add_theme_font_size_override("font_size",16)
			b.custom_minimum_size=Vector2(0,56)
			b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			b.toggle_mode=true
			b.button_pressed=int(prefs[key])==value
			b.pressed.connect(func():
				app.game.set_preference(key,value)
				for other in row.get_children(): other.button_pressed=int(app.game.preferences()[key])==int(other.get_meta("value")))
			b.set_meta("value",value)
	var all=PetUI.button(column,"All settings…",Rect2(0,0,0,56),func():
		toggle_settings()
		app.show_settings(),true)
	all.name="AllSettings"
	all.custom_minimum_size=Vector2(0,56)
	settings_feedback=PetUI.label(column,"",Vector2.ZERO,16,PetUI.INK,280)
	settings_feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	settings_close=PetUI.menu_button(settings_panel,"Done",toggle_settings,true)
	for b in actions+[practice,settings]: b.focus_mode=Control.FOCUS_NONE
	layout_settings()
	motion.grab_focus()

func layout_settings() -> void:
	var w=minf(500,safe.size.x)
	var h=minf(590,safe.size.y)
	place(settings_panel,Rect2(safe.get_center()-Vector2(w,h)/2,Vector2(w,h)))
	settings_scroll.size=Vector2(w-36,h-145)
	place(settings_close,Rect2(18,h-70,w-36,56))
