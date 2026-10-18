class_name CareArt
extends RefCounted
## Region-backed shared icons. Layout and interactive text remain native controls.
const ICONS=["feed","clean","ball","rest","happy","energy","water","health","bond","shop","decorate","back"]
static var cache: Dictionary={}
## A47 concept icon sheet: 4x4 cells (column, row), generated with Codex; see asset-register.
const CONCEPT_CELL=128
const CONCEPT_ICONS={"heart":[0,0],"heart_empty":[1,0],"left":[2,0],"right":[3,0],"up":[0,1],"hand":[1,1],"sense":[2,1],"music":[3,1],"speaker":[0,2],"voice":[1,2],"motion":[2,2],"hint":[3,2],"timer":[0,3],"controller":[1,3],"basket":[2,3],"check":[3,3]}
static func icon(kind: String) -> Texture2D:
	if cache.has(kind): return cache[kind]
	if CONCEPT_ICONS.has(kind):
		var cell: Array=CONCEPT_ICONS[kind]
		var sheet=AtlasTexture.new()
		sheet.atlas=ArtTexture.load_texture("res://assets/ui/concept-v1/hud-icons.png")
		sheet.region=Rect2(cell[0]*CONCEPT_CELL,cell[1]*CONCEPT_CELL,CONCEPT_CELL,CONCEPT_CELL)
		sheet.filter_clip=true
		cache[kind]=sheet
		return sheet
	if kind in ["drink","menu","close"]:
		var spec=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/home-flow-v1/icons.json"))[kind]
		var result=AtlasTexture.new()
		result.atlas=ArtTexture.load_texture("res://assets/ui/home-flow-v1/controls.png")
		result.region=Rect2(spec[0],spec[1],spec[2],spec[3])
		result.filter_clip=true
		cache[kind]=result
		return result
	var index=ICONS.find(kind)
	if index<0:
		var spec=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/menu-v3/manifest.json")).icons[kind]
		var result=AtlasTexture.new()
		result.atlas=ArtTexture.load_texture("res://assets/ui/menu-v3/"+kind+".png")
		result.region=Rect2(spec.region[0],spec.region[1],spec.region[2],spec.region[3])
		result.filter_clip=true
		cache[kind]=result
		return result
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/care-v1/icons.json"))
	var cell=data.cells[index]
	var r=cell.region
	var b=cell.visible_bounds
	var texture=AtlasTexture.new()
	texture.atlas=ArtTexture.load_texture("res://assets/ui/care-v1/icons.png")
	texture.region=Rect2(r[0]+b[0],r[1]+b[1],b[2]-b[0],b[3]-b[1])
	texture.filter_clip=true
	cache[kind]=texture
	return texture
static func picture(parent: Node, kind: String, bounds: Rect2) -> TextureRect:
	var image=TextureRect.new()
	image.texture=icon(kind)
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	image.position=bounds.position
	image.size=bounds.size
	parent.add_child(image)
	return image
static func frame(parent: Node, bounds: Rect2) -> Panel:
	var panel=PetUI.panel(parent,bounds)
	panel.add_theme_stylebox_override("panel",PetUI.wallet_style())
	panel.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	return panel
static func title(parent: Node, text: String, bounds: Rect2, font_size=24) -> Label:
	var label=PetUI.label(parent,text,bounds.position,font_size,PetUI.INK,bounds.size.x)
	label.add_theme_font_override("font",load(PetUI.MENU_FONT_PATH))
	label.size=bounds.size
	label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return label
static func button(parent: Node, text: String, bounds: Rect2, callback: Callable, kind="", primary=false) -> Button:
	if text.is_empty() and kind in ["gear","close"]: return icon_button(parent,kind,bounds,callback)
	var control=PetUI.menu_button(parent,text,callback,primary)
	control.name=text.to_pascal_case().validate_node_name() if not text.is_empty() else "IconButton"
	if primary: control.add_theme_stylebox_override("normal",PetUI.menu_style(true))
	for state_name in ["normal","hover","pressed","disabled"]:
		var style=control.get_theme_stylebox(state_name)
		style.content_margin_left=14
		style.content_margin_right=14
		style.content_margin_top=6
		style.content_margin_bottom=6
		style.corner=minf(20,bounds.size.y*.30)
	control.set_meta("animate_symbol",false)
	control.clip_text=true
	control.alignment=HORIZONTAL_ALIGNMENT_CENTER
	var points=20
	var budget=bounds.size.x-28-(36 if not kind.is_empty() else 0)
	var font=control.get_theme_font("font")
	while points>16 and font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,points).x>budget: points-=1
	control.add_theme_font_size_override("font_size",points)
	if not kind.is_empty():
		control.icon=icon(kind)
		control.expand_icon=true
		control.add_theme_constant_override("icon_max_width",26)
		control.add_theme_constant_override("h_separation",10)
		control.icon_alignment=HORIZONTAL_ALIGNMENT_LEFT
	control.position=bounds.position
	control.size=bounds.size
	return control

static func meter(parent: Node, at: Vector2, width: float, key: String, thickness=18.0) -> ProgressBar:
	var source: Texture2D=ArtTexture.load_texture("res://assets/ui/care-v1/shared-reference.png")
	var regions={"fullness":Rect2(254,900,114,27),"happiness":Rect2(466,900,128,27),"energy":Rect2(678,900,104,27),"cleanliness":Rect2(890,900,120,27),"health":Rect2(1103,900,113,27),"bond":Rect2(1312,900,133,27)}
	var track=StyleBoxTexture.new()
	track.texture=source
	track.region_rect=Rect2(371,900,32,27)
	var fill=StyleBoxTexture.new()
	fill.texture=source
	fill.region_rect=regions[key]
	for style in [track,fill]:
		for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:
			style.set_texture_margin(side,3)
			style.set_content_margin(side,0)
	var bar=ProgressBar.new()
	bar.position=at
	bar.size=Vector2(width,thickness)
	bar.show_percentage=false
	bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background",track)
	bar.add_theme_stylebox_override("fill",fill)
	parent.add_child(bar)
	bar.set_deferred("size",Vector2(width,thickness))
	return bar

static func icon_button(parent: Node, kind: String, bounds: Rect2, callback: Callable) -> Button:
	var control=Button.new()
	control.tooltip_text="Settings" if kind=="gear" else kind.capitalize()
	control.position=bounds.position
	control.size=bounds.size
	for key in ["normal","hover","pressed","disabled"]: control.add_theme_stylebox_override(key,StyleBoxEmpty.new())
	var focus=PetUI.style(Color(0,0,0,0),5)
	focus.border_color=PetUI.BLUE
	focus.set_border_width_all(3)
	control.add_theme_stylebox_override("focus",focus)
	control.pressed.connect(callback)
	parent.add_child(control)
	picture(control,kind,Rect2(Vector2.ZERO,bounds.size))
	control.mouse_entered.connect(func(): control.modulate=Color(1.08,1.08,1.08))
	control.mouse_exited.connect(func(): control.modulate=Color.WHITE)
	return control

static func reference_crop(parent: Node, rect: Rect2, source_rect: Rect2) -> TextureRect:
	var image=TextureRect.new()
	var atlas=AtlasTexture.new()
	atlas.atlas=ArtTexture.load_texture("res://assets/ui/care-v1/details-reference.png")
	atlas.region=source_rect
	atlas.filter_clip=true
	image.texture=atlas
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.position=rect.position
	image.size=rect.size
	image.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)
	return image

## On/Off pill matching the V08 settings switches.
static func toggle(parent: Node, on: bool, callback: Callable) -> Button:
	var pill=Button.new()
	pill.size=Vector2(104,40)
	pill.text="On" if on else "Off"
	pill.add_theme_font_override("font",load(PetUI.MENU_FONT_PATH))
	pill.add_theme_font_size_override("font_size",20)
	var style=PetUI.style(Color("5fb85a") if on else Color("c9c1b2"),20)
	style.border_color=PetUI.WOOD
	style.set_border_width_all(3)
	for key in ["normal","hover","pressed","focus"]: pill.add_theme_stylebox_override(key,style)
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: pill.add_theme_color_override(key,Color.WHITE if on else PetUI.INK)
	pill.alignment=HORIZONTAL_ALIGNMENT_LEFT if on else HORIZONTAL_ALIGNMENT_RIGHT
	pill.add_theme_constant_override("h_separation",0)
	var knob=Panel.new()
	var round=PetUI.style(PetUI.CREAM,15)
	round.border_color=PetUI.WOOD
	round.set_border_width_all(3)
	knob.add_theme_stylebox_override("panel",round)
	knob.size=Vector2(30,30)
	knob.position=Vector2(69 if on else 5,5)
	knob.mouse_filter=Control.MOUSE_FILTER_IGNORE
	pill.add_child(knob)
	for key in ["normal","hover","pressed","focus"]:
		var padded: StyleBoxFlat=pill.get_theme_stylebox(key).duplicate()
		padded.content_margin_left=16
		padded.content_margin_right=16
		pill.add_theme_stylebox_override(key,padded)
	pill.pressed.connect(callback)
	parent.add_child(pill)
	return pill

## Left/right stepper (V08 "Timing  < Relaxed >").
static func stepper(parent: Node, value: String, can_lower: bool, can_raise: bool, callback: Callable, width=196.0) -> Control:
	var holder=Panel.new()
	holder.size=Vector2(width,40)
	var style=PetUI.style(PetUI.CREAM,12)
	style.border_color=PetUI.WOOD
	style.set_border_width_all(2)
	holder.add_theme_stylebox_override("panel",style)
	parent.add_child(holder)
	for entry in [[-1,"left",0.0,can_lower],[1,"right",width-40,can_raise]]:
		var arrow=Button.new()
		arrow.name="Lower" if entry[0]<0 else "Raise"
		arrow.position=Vector2(entry[2],0)
		arrow.size=Vector2(40,40)
		arrow.disabled=not entry[3]
		for key in ["normal","hover","pressed","disabled","focus"]: arrow.add_theme_stylebox_override(key,StyleBoxEmpty.new())
		var direction: int=entry[0]
		arrow.pressed.connect(func(): callback.call(direction))
		holder.add_child(arrow)
		var picture_rect=picture(arrow,entry[1],Rect2(6,6,28,28))
		picture_rect.modulate=Color(1,1,1,1.0 if entry[3] else .3)
	var label=title(holder,value,Rect2(40,0,width-80,40),19)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	return holder
