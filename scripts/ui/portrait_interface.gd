class_name PortraitInterface
extends Control
## Responsive presentation of the shared screen actions. Mechanics and transactions
## stay in Main/GameState; hidden desktop widgets remain their authoritative bindings.
var app: Control
var signature = ""
var bindings: Array = []
var page: Control
var controls: TouchControls
var stage_rect: Rect2
var safe_override = Vector4(-1,-1,-1,-1)
var control_size = 60
var control_spacing = 12
var control_raise = 0
var settings_open = false
var safe_bounds: Rect2
var active_overlay: Panel
var home_caption: Label

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	mouse_filter=Control.MOUSE_FILTER_IGNORE

func safe_rect(logical: Vector2) -> Rect2:
	var inset=Vector4(12,12,12,12)
	if safe_override.x>=0:
		inset=safe_override
	elif OS.get_name() in ["Android","iOS"]:
		var area=DisplayServer.get_display_safe_area()
		var pixels=Vector2(get_window().size)
		if area.size.x>0 and area.size.y>0:
			inset=Vector4(maxf(12,area.position.x/pixels.x*logical.x),maxf(12,area.position.y/pixels.y*logical.y),maxf(12,(pixels.x-area.end.x)/pixels.x*logical.x),maxf(12,(pixels.y-area.end.y)/pixels.y*logical.y))
	return Rect2(Vector2(inset.x,inset.y),logical-Vector2(inset.x+inset.z,inset.y+inset.w))

func _process(_delta: float) -> void:
	if not is_instance_valid(app.ui): return
	var pixels=Vector2(get_window().size)
	var portrait=pixels.x<pixels.y
	var logical=(pixels if pixels.x>=600 and is_instance_valid(app.native_screen) else Vector2(390,roundf(390*pixels.y/maxf(1,pixels.x)))) if portrait else (pixels if is_instance_valid(app.native_screen) else Vector2(1280,720))
	if portrait and app.screen in ["menu","adoption"] and logical.y<720:
		logical=Vector2(roundf(720*pixels.x/pixels.y),720)
	if get_window().content_scale_size!=Vector2i(logical): get_window().content_scale_size=Vector2i(logical)
	safe_bounds=safe_rect(logical)
	if is_instance_valid(app.native_screen):
		visible=false
		app.ui.visible=true
		app.viewport.get_parent().visible=true
		if is_instance_valid(controls): controls.set_process_input(false)
		app.native_screen.layout(logical,safe_bounds)
		if app.screen=="home" and is_instance_valid(app.care_ui): home_caption=app.care_ui.stage_caption
		return
	if app.screen in ["menu","adoption"]:
		visible=false
		app.ui.visible=true
		app.viewport.get_parent().visible=false
		if is_instance_valid(controls): controls.set_process_input(false)
		if not signature.is_empty():
			for child in get_children(): child.queue_free()
			bindings.clear()
			controls=null
			signature=""
		var native_screen=app.main_menu if app.screen=="menu" else app.adoption_screen
		native_screen.layout(logical,safe_bounds)
		return
	visible=portrait
	app.ui.visible=not portrait
	var container=app.viewport.get_parent() as SubViewportContainer
	container.visible=true
	container.stretch=not portrait
	for original in app.ui.get_children():
		if original is TouchControls: original.set_process_input(not portrait)
	if not portrait:
		WorldRender.configure(app.viewport,Vector2i(640,360))
		if is_instance_valid(controls): controls.set_process_input(false)
		if not signature.is_empty():
			TouchControls.release_actions()
			signature=""
		return
	safe_bounds=safe_rect(logical)
	var preferences=app.game.preferences()
	control_size=int(preferences.touch_size)
	control_spacing=int(preferences.touch_spacing)
	control_raise=int(preferences.touch_raise)
	var structure=[]
	for child in app.ui.get_children():
		if not child.is_queued_for_deletion(): structure.append(child.get_instance_id())
	if settings_open and not is_instance_valid(app.pause_panel): settings_open=false
	var next_signature=str([app.ui.get_instance_id(),structure,logical,safe_bounds,control_size,control_spacing,control_raise,settings_open])
	if signature!=next_signature:
		signature=next_signature
		rebuild()
	for pair in bindings:
		if not is_instance_valid(pair[0]) or not is_instance_valid(pair[1]): continue
		if pair[0] is Button:
			pair[1].disabled=pair[0].disabled
			if not pair[1].has_meta("caption"): pair[1].text=pair[0].text.replace(" · Space", "").replace(" · B", "")
		elif pair[0] is Label:
			pair[1].text=pair[0].text
			if pair[0]==app.prompt_label:
				pair[1].text=pair[1].text.replace("E •","Use ·").replace("Q •","Find ·").replace("B opens your bag","open Bag for tools").replace("R resets; F recalls the pet.","Tap Reset to return; Foxy recovers automatically.").replace("Move with A/D or arrows. Space to jump.","Hold ← / → to move. Tap Jump with your other thumb.")
		elif pair[0] is ProgressBar: pair[1].value=pair[0].value
	var toast=get_node_or_null("Toast")
	if app.screen=="home" and not app.game.state.is_empty() and is_instance_valid(home_caption):
		home_caption.text=app.game.pet().name+" · "+app.game.pet().growth_stage.capitalize()
	if toast:
		toast.visible=app.toast_time>0 and app.toast_panel.visible
		toast.get_child(0).text=app.toast_label.text.replace("B opens the bag; E builds at marked spots.","Open Bag to build at marked spots.")

func caption(parent: Node, text: String, font_size=18) -> Label:
	var label=PetUI.label(parent,text,Vector2.ZERO,font_size,PetUI.INK)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return label

func button(parent: Node, text: String, callback: Callable, primary=false) -> Button:
	var result=PetUI.button(parent,text,Rect2(0,0,0,56),callback,primary)
	result.add_theme_font_size_override("font_size",18)
	result.custom_minimum_size=Vector2(0,56)
	result.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	result.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return result

func proxy(parent: Node, source: Button, text="") -> Button:
	var b=button(parent,source.text if text.is_empty() else text,func():
		if is_instance_valid(source) and not source.disabled: source.pressed.emit())
	b.disabled=source.disabled
	if not text.is_empty(): b.set_meta("caption",true)
	bindings.append([source,b])
	return b

func find_button(text: String) -> Button:
	for source in app.ui.find_children("*","Button",true,false):
		if source.text==text: return source
	return null

func action(parent: Node, text: String, mobile_text="") -> void:
	var source=find_button(text)
	if source: proxy(parent,source,mobile_text)

func scroll_page(bounds: Rect2) -> VBoxContainer:
	var panel=PetUI.panel(page,bounds)
	var scroll=ScrollContainer.new()
	scroll.position=Vector2(12,12)
	scroll.size=bounds.size-Vector2(24,24)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var column=VBoxContainer.new()
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",10)
	scroll.add_child(column)
	return column

func rebuild() -> void:
	TouchControls.release_actions()
	bindings.clear()
	controls=null
	home_caption=null
	for child in get_children():
		remove_child(child)
		child.queue_free()
	page=Control.new()
	page.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(page)
	var fill=ColorRect.new()
	fill.color=Color("d3e5dd")
	fill.size=Vector2(get_window().content_scale_size)
	fill.mouse_filter=Control.MOUSE_FILTER_IGNORE
	page.add_child(fill)
	var x=safe_bounds.position.x
	var y=safe_bounds.position.y
	var w=safe_bounds.size.x
	caption_at("PETOPIA",Rect2(x+4,y,w,30),24)
	caption_at("Little friends, big adventures",Rect2(x+4,y+30,w,22),14)
	var nav=HBoxContainer.new()
	nav.position=Vector2(x,y+58)
	nav.size=Vector2(w,56)
	nav.add_theme_constant_override("separation",6)
	page.add_child(nav)
	button(nav,"Main menu" if app.screen=="hub" else "Play",app.show_menu if app.screen=="hub" else app.show_hub)
	button(nav,"My Pet",app.show_home)
	button(nav,"Pause",app.toggle_pause)
	var gameplay=app.screen in ["adventure","lab"]
	var top=y+124
	var bottom=safe_bounds.end.y
	var stage_height=maxf(140,bottom-top-250-86) if gameplay else minf(245,w*360/640.0)
	stage_rect=Rect2(x,top+(86 if gameplay else 0),w,stage_height)
	if app.screen=="ball": stage_rect.size.y=w*360/440.0
	var world_size=Vector2(roundf(w*360/stage_rect.size.y),360) if gameplay else (Vector2(440,360) if app.screen=="ball" else Vector2(640,360))
	WorldRender.configure(app.viewport,Vector2i(world_size))
	var image=TextureRect.new()
	image.name="GameView"
	image.texture=app.viewport.get_texture()
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.position=stage_rect.position
	image.size=stage_rect.size
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	image.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	page.add_child(image)
	if gameplay: build_adventure(top,bottom)
	elif app.screen=="ball": build_ball(stage_rect.end.y+12,bottom)
	elif app.screen=="home": build_home(stage_rect.end.y+10,bottom)
	else:
		var column=scroll_page(Rect2(x,top,w,bottom-top))
		if app.screen=="hub":
			caption(column,"Choose your adventure",24)
			caption(column,"You lead. Foxy helps. Touch and keyboard use the same actions.")
			for text in ["River art test","Adventures","Movement lab","Pet home","Catch the Ball","Progress"]: action(column,text)
			action(column,"Visuals: Art pilot")
			action(column,"Visuals: Graybox")
		else:
			var progress_panel=app.ui.get_children().filter(func(c): return c is Panel and c.position.x==70)
			if not progress_panel.is_empty(): mirror_panel(column,progress_panel[0])
	var overlay: Panel=null
	for child in app.ui.get_children():
		if child is Panel and child.has_meta("modal") and not child.is_queued_for_deletion(): overlay=child
	active_overlay=overlay
	if overlay or settings_open:
		if is_instance_valid(controls): controls.set_process_input(false)
		var dim=ColorRect.new()
		dim.color=Color(0.07,0.12,0.20,0.7)
		dim.size=Vector2(get_window().content_scale_size)
		page.add_child(dim)
		# Keep the room preview visible above the decoration sheet.
		var sheet_y=stage_rect.end.y+10 if overlay and overlay.size.y==208 else y+60
		var column=scroll_page(Rect2(x,sheet_y,w,bottom-sheet_y))
		if settings_open: build_settings(column)
		else:
			mirror_panel(column,overlay)
			if overlay==app.pause_panel: button(column,"Touch controls",func(): settings_open=true)
	var modal_toast=overlay!=null or settings_open
	var toast_y=y if modal_toast else maxf(y+116,stage_rect.position.y+12)
	var toast_height=56 if modal_toast else 96
	if app.screen=="home" and not modal_toast:
		# Care feedback belongs on the foreground floor, below the child/bed.
		# The former tall message covered the pet throughout the rest reaction.
		toast_y=stage_rect.end.y-44
		toast_height=44
	var toast=PetUI.panel(self,Rect2(x,toast_y,w,toast_height),Color("364c5a"))
	toast.name="Toast"
	toast.mouse_filter=Control.MOUSE_FILTER_IGNORE
	PetUI.label(toast,"",Vector2(12,6),13 if modal_toast else (14 if app.screen=="home" else 16),Color("fff3d9"),w-24)

func caption_at(text: String, bounds: Rect2, font_size: int) -> Label:
	return PetUI.label(page,text,bounds.position,font_size,PetUI.INK,bounds.size.x)

func build_adventure(top: float, bottom: float) -> void:
	var w=safe_bounds.size.x
	var prompt=caption_at("",Rect2(safe_bounds.position.x,top,w,78),17)
	bindings.append([app.prompt_label,prompt])
	var row=HBoxContainer.new()
	row.position=Vector2(safe_bounds.position.x,stage_rect.end.y+6)
	row.size=Vector2(w,56)
	page.add_child(row)
	if is_instance_valid(app.coin_label):
		var coin=PetUI.coin_display(row,Vector2.ZERO,"Run" if app.screen=="adventure" else "Practice")
		coin.get_parent().custom_minimum_size=Vector2(130,72)
		coin.get_parent().size=Vector2(130,72)
		bindings.append([app.coin_label,coin])
	if app.screen=="adventure": action(row,"Bag · B","Bag")
	else: action(row,"Restart lab","Restart")
	button(row,"Reset",func(): Input.action_press("reset_checkpoint"); get_tree().create_timer(0.08).timeout.connect(func(): Input.action_release("reset_checkpoint")))
	controls=TouchControls.new()
	controls.process_mode=Node.PROCESS_MODE_PAUSABLE
	controls.portrait_bounds=Rect2(safe_bounds.position.x,bottom-152-control_raise,w,152)
	controls.button_size=control_size
	controls.button_spacing=control_spacing
	page.add_child(controls)

func build_ball(top: float, bottom: float) -> void:
	var column=scroll_page(Rect2(safe_bounds.position.x,top,safe_bounds.size.x,bottom-top))
	caption(column,"Catch the Ball",24)
	caption(column,"Home garden · play together",16)
	caption(column,"Tap Throw when the marker is in the gold band. Foxy catches and brings it back.")
	if is_instance_valid(app.throw_button): proxy(column,app.throw_button)
	var timing=ThrowMeter.new()
	timing.custom_minimum_size=Vector2(0,64)
	timing.activity=app.active_ball
	column.add_child(timing)

func build_home(top: float, bottom: float) -> void:
	var column=scroll_page(Rect2(safe_bounds.position.x,top,safe_bounds.size.x,bottom-top))
	if app.game.state.is_empty(): return
	home_caption=caption(column,app.game.pet().name+" · "+app.game.pet().growth_stage.capitalize(),24)
	var coin=PetUI.coin_display(column,Vector2.ZERO)
	coin.get_parent().custom_minimum_size=Vector2(0,72)
	bindings.append([app.coin_label,coin])
	var summary=GridContainer.new()
	summary.columns=2
	summary.add_theme_constant_override("h_separation",12)
	summary.add_theme_constant_override("v_separation",10)
	column.add_child(summary)
	for key in ["fullness","happiness","energy","cleanliness"]:
		var cell=VBoxContainer.new()
		cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		summary.add_child(cell)
		caption(cell,{"fullness":"Food","happiness":"Happy","energy":"Energy","cleanliness":"Clean"}[key],16)
		var bar=ProgressBar.new()
		bar.custom_minimum_size=Vector2(0,12)
		bar.show_percentage=false
		var fill_style=PetUI.style(PetUI.NEED_COLORS[key],5)
		fill_style.content_margin_top=0
		fill_style.content_margin_bottom=0
		bar.add_theme_stylebox_override("fill",fill_style)
		cell.add_child(bar)
		bindings.append([app.bars[key],bar])
	var care=GridContainer.new()
	care.columns=2
	care.add_theme_constant_override("h_separation",8)
	care.add_theme_constant_override("v_separation",8)
	column.add_child(care)
	for text in ["Feed (free)","Clean (free)","Play","Rest / Wake"]: action(care,text)
	for text in ["Pet","Water","Adventures","Shop","Decorate","Pet details"]: action(column,text)

func mirror_panel(column: VBoxContainer, panel: Panel) -> void:
	var items=panel.get_children().filter(func(c): return c is Label or c is Button or c is LineEdit or c is ProgressBar)
	items.sort_custom(func(a,b):
		var ay=a.position.y+(12 if a is Button else 0)
		var by=b.position.y+(12 if b is Button else 0)
		return a.position.x<b.position.x if is_equal_approx(ay,by) else ay<by)
	for source in items:
		if source is Button: proxy(column,source)
		elif source is Label:
			var label_parent: Node=column
			for child in panel.get_children():
				if child is ItemVisual and absf(child.position.y-source.position.y-19)<2:
					var row=HBoxContainer.new()
					column.add_child(row)
					var box=Control.new()
					box.custom_minimum_size=Vector2(48,52)
					row.add_child(box)
					var icon=ItemVisual.new()
					icon.item_id=child.item_id
					icon.position=Vector2(24,26)
					icon.scale=Vector2(1.8,1.8)
					box.add_child(icon)
					label_parent=row
			for child in panel.get_children():
				if child is TextureRect and absf(child.position.y-source.position.y)<10:
					var row=HBoxContainer.new()
					column.add_child(row)
					var icon=TextureRect.new()
					icon.texture=child.texture
					icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
					icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					icon.custom_minimum_size=Vector2(48,48)
					row.add_child(icon)
					label_parent=row
			var label=caption(label_parent,source.text,22 if source.position.y<40 else 18)
			bindings.append([source,label])
		elif source is LineEdit:
			var edit=LineEdit.new()
			edit.text=source.text
			edit.max_length=source.max_length
			edit.custom_minimum_size=Vector2(0,56)
			edit.add_theme_font_size_override("font_size",22)
			edit.text_changed.connect(func(text): source.text=text)
			column.add_child(edit)
		elif source is ProgressBar:
			var bar=ProgressBar.new()
			bar.custom_minimum_size=Vector2(0,16)
			bar.show_percentage=false
			column.add_child(bar)
			bindings.append([source,bar])

func build_settings(column: VBoxContainer) -> void:
	caption(column,"Touch controls",24)
	caption(column,"Choose a button size and the distance between your thumbs. Changes are saved for this pet.")
	for value in [52,60,68]:
		button(column,"%s %d · %s"%["✓" if control_size==value else "",value,{52:"Compact",60:"Comfort",68:"Large"}[value]],func(): set_touch("touch_size",value))
	for value in [0,12,24]:
		button(column,"Spacing %d%s"%[value," ✓" if control_spacing==value else ""],func(): set_touch("touch_spacing",value))
	for value in [0,16,32]:
		button(column,"Raise buttons %d%s"%[value," ✓" if control_raise==value else ""],func(): set_touch("touch_raise",value))
	button(column,"Back to pause",func(): settings_open=false)

func set_touch(key: String, value: int) -> void:
	app.game.set_preference(key,value)
