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
	var source: Texture2D=load("res://assets/ui/menu-v1/"+path+".png")
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
	background=art("meadow")
	background.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	logo=art("logo",Rect2(96,110,1768,580))
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
	for i in range(actions.size()):
		var icon=preload("res://scripts/ui/menu_icon.gd").new()
		icon.kind=["play","paw","map","bond"][i]
		actions[i].add_child(icon)
		icon.name="Symbol"
		icon.size=Vector2(40,40)
		if i==3: icon.modulate=Color.WHITE
		actions[i].alignment=HORIZONTAL_ALIGNMENT_CENTER
	hide_native_caption(collection)
	collection_text=VBoxContainer.new()
	collection_text.alignment=BoxContainer.ALIGNMENT_CENTER
	collection_text.mouse_filter=Control.MOUSE_FILTER_IGNORE
	collection_text.add_theme_constant_override("separation",3)
	collection.add_child(collection_text)
	collection_title=PetUI.label(collection_text,"Collection",Vector2.ZERO,24,Color("41495a"))
	collection_title.add_theme_font_override("font",load(PetUI.MENU_FONT_PATH))
	collection_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	collection_subtitle=PetUI.label(collection_text,"Pets & memories",Vector2.ZERO,16,Color("495873"))
	collection_subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	practice=PetUI.menu_button(self,"Games",app.show_minigames)
	settings=PetUI.menu_button(self,"Settings",toggle_settings)
	hide_native_caption(settings)
	settings.set_meta("animate_symbol",false)
	settings_content=HBoxContainer.new()
	settings_content.name="Content"
	settings_content.alignment=BoxContainer.ALIGNMENT_CENTER
	settings_content.mouse_filter=Control.MOUSE_FILTER_IGNORE
	settings_content.add_theme_constant_override("separation",8)
	settings.add_child(settings_content)
	var gear=preload("res://scripts/ui/menu_icon.gd").new()
	gear.kind="gear"
	gear.name="Symbol"
	gear.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	settings_content.add_child(gear)
	settings_icon=gear
	settings_title=PetUI.label(settings_content,"Settings",Vector2.ZERO,17)
	settings_title.add_theme_font_override("font",load(PetUI.MENU_FONT_PATH))
	settings_title.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	for b in [practice,settings]: b.add_theme_font_size_override("font_size",20)
	var value=PetUI.coin_display(self,Vector2.ZERO,"Coins",true)
	value.text="0" if fresh else str(app.game.state.coins)
	wallet=value.get_parent()
	wallet.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	wallet.get_node("CoinIcon").texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	value.add_theme_font_override("font",load(PetUI.MENU_FONT_PATH))
	status=PetUI.label(self,"",Vector2.ZERO,16,PetUI.INK,300)
	status.visible=app.game.store.blocked
	status.text="Your save needs recovery. Practice is still available."
	version_tag=PetUI.label(self,"v"+str(ProjectSettings.get_setting("application/config/version","dev")),Vector2.ZERO,14,PetUI.INK)
	app.game.feedback.connect(show_feedback)
	if status.visible: primary.disabled=true
	layout(Vector2(get_window().content_scale_size),Rect2(12,12,1256,696))
	primary.grab_focus()

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
	var icon_size=50.0
	var text_inset=104.0
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
		place(wallet,Rect2(x+w-138,y,138,50))
		wallet.get_node("CoinIcon").position=Vector2(15,9)
		wallet.get_node("CoinIcon").size=Vector2(34,34)
		wallet.get_child(2).position=Vector2(62,8)
		wallet.get_child(2).add_theme_font_size_override("font_size",28)
		place(logo,Rect2(x+4,y+58,w-8,logo_h))
		var top=y+58+logo_h+12
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
		icon_size=36
		text_inset=76
	else:
		place(logo,Rect2(56,28,550,180))
		place(friends,Rect2(666,292,390,344))
		for i in range(actions.size()):
			place(actions[i],Rect2(150,224+i*108,352,104))
			actions[i].add_theme_font_size_override("font_size",34)
		place(wallet,Rect2(1044,20,212,90))
		wallet.get_node("CoinIcon").position=Vector2(24,18)
		wallet.get_node("CoinIcon").size=Vector2(54,54)
		wallet.get_child(2).position=Vector2(102,21)
		wallet.get_child(2).add_theme_font_size_override("font_size",40)
		place(practice,Rect2(150,660,178,48))
		place(settings,Rect2(1100,628,164,76))
		place(status,Rect2(150,198,352,32))
		place(version_tag,Rect2(954,684,132,24))
	wallet.get_child(1).visible=false
	for i in range(actions.size()):
		var b=actions[i]
		for state_name in ["normal","hover","pressed","disabled"]:
			var box=b.get_theme_stylebox(state_name)
			box.content_margin_left=text_inset
			box.content_margin_right=18
			box.content_margin_bottom=(22 if portrait else 28) if i==3 else 8
			box.content_margin_top=0 if i==3 else 8
	collection_title.add_theme_font_size_override("font_size",24 if portrait else 34)
	collection_subtitle.add_theme_font_size_override("font_size",16 if portrait else 18)
	settings_icon.custom_minimum_size=Vector2.ONE*(26 if portrait else 36)
	settings_title.add_theme_font_size_override("font_size",17 if portrait else 20)
	for state_name in ["normal","hover","pressed","disabled"]:
		var box=settings.get_theme_stylebox(state_name)
		box.content_margin_left=46 if portrait else 58
		box.content_margin_right=12
	settings.add_theme_font_size_override("font_size",17 if portrait else 20)
	# Font and content insets must be applied before final size: a control cannot
	# shrink below its previous layout's minimum while those values are changing.
	for b in actions+[practice,settings]: b.size=b.get_meta("layout_size")
	# Center symbols only after font minima and final button sizes have settled.
	# Restart feedback from these bounds so a resize cannot reuse an old center.
	for i in range(actions.size()):
		var b=actions[i]
		var icon=b.get_node("Symbol")
		place(icon,Rect2(30 if i==2 else 34,(b.size.y-icon_size)/2,icon_size+8 if i==2 else icon_size,icon_size))
		icon.set_meta("rest",icon.position)
		b.get_node("MenuButtonMotion").refresh()
	place(collection_text,Rect2(text_inset,8,actions[3].size.x-text_inset-18,actions[3].size.y-16))
	place(settings_content,Rect2(12,8,settings.size.x-24,settings.size.y-16))
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
