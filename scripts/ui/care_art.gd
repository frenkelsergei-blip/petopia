class_name CareArt
extends RefCounted
## Region-backed shared icons. Layout and interactive text remain native controls.
const ICONS=["feed","clean","ball","rest","happy","energy","water","health","bond","shop","decorate","back"]
static var cache: Dictionary={}
static func icon(kind: String) -> Texture2D:
	if cache.has(kind): return cache[kind]
	if kind in ["drink","menu","close"]:
		var spec=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/home-flow-v1/icons.json"))[kind]
		var result=AtlasTexture.new()
		result.atlas=load("res://assets/ui/home-flow-v1/controls.png")
		result.region=Rect2(spec[0],spec[1],spec[2],spec[3])
		result.filter_clip=true
		cache[kind]=result
		return result
	var index=ICONS.find(kind)
	if index<0:
		var spec=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/menu-v3/manifest.json")).icons[kind]
		var result=AtlasTexture.new()
		result.atlas=load("res://assets/ui/menu-v3/"+kind+".png")
		result.region=Rect2(spec.region[0],spec.region[1],spec.region[2],spec.region[3])
		result.filter_clip=true
		cache[kind]=result
		return result
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/care-v1/icons.json"))
	var cell=data.cells[index]
	var r=cell.region
	var b=cell.visible_bounds
	var texture=AtlasTexture.new()
	texture.atlas=load("res://assets/ui/care-v1/icons.png")
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
	var source: Texture2D=load("res://assets/ui/care-v1/shared-reference.png")
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
	atlas.atlas=load("res://assets/ui/care-v1/details-reference.png")
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
