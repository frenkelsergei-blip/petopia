class_name CareArt
extends RefCounted
## Region-backed shared icons. Layout and interactive text remain native controls.
const ICONS=["feed","clean","ball","rest","happy","energy","water","health","bond","shop","decorate","back"]
static var cache: Dictionary={}
## A47 concept icon sheet: 4x4 cells (column, row), generated with Codex; see asset-register.
const CONCEPT_CELL=128
## A48 background-free glyph sheet (Codex), 4x4 cells of 128 px; these names
## take priority so every square/icon button shares one glyph family.
const GLYPHS={"gear":[0,0],"menu":[1,0],"close":[2,0],"back":[3,0],"home":[0,1],"world":[1,1],"star":[2,1],"paw_blue":[3,1],"plus":[0,2],"minus":[1,2],"pencil":[2,2],"shop_stall":[3,2],"trophy":[0,3],"mute":[1,3],"lock":[2,3],"help":[3,3]}
const CONCEPT_ICONS={"heart":[0,0],"heart_empty":[1,0],"left":[2,0],"right":[3,0],"up":[0,1],"hand":[1,1],"sense":[2,1],"music":[3,1],"speaker":[0,2],"voice":[1,2],"motion":[2,2],"hint":[3,2],"timer":[0,3],"controller":[1,3],"basket":[2,3],"check":[3,3]}
static func icon(kind: String) -> Texture2D:
	if cache.has(kind): return cache[kind]
	if GLYPHS.has(kind):
		var g: Array=GLYPHS[kind]
		var glyph=AtlasTexture.new()
		glyph.atlas=ArtTexture.load_texture("res://assets/ui/concept-v1/glyphs.png")
		glyph.region=Rect2(g[0]*CONCEPT_CELL,g[1]*CONCEPT_CELL,CONCEPT_CELL,CONCEPT_CELL)
		glyph.filter_clip=true
		cache[kind]=glyph
		return glyph
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
static func button(parent: Node, text: String, bounds: Rect2, callback: Callable, kind="", primary=false, layout="") -> Button:
	if text.is_empty() and not kind.is_empty(): return square(parent,kind,bounds,callback)
	var control=PetUI.menu_button(parent,text,callback,primary)
	control.name=text.to_pascal_case().validate_node_name() if not text.is_empty() else "IconButton"
	if primary: control.add_theme_stylebox_override("normal",PetUI.menu_style(true))
	control.set_meta("animate_symbol",false)
	control.position=bounds.position
	control.size=bounds.size
	var shape=layout if not layout.is_empty() else ("icon" if text.is_empty() else "row")
	PetUI.compose(control,text,icon(kind) if not kind.is_empty() else null,shape)
	return control

## Need meters: fully rounded track and fill at every width (the painted bar
## crop left a square right end), colours from PetUI.NEED_COLORS.
static func meter(parent: Node, at: Vector2, width: float, key: String, thickness=18.0) -> ProgressBar:
	var radius=int(thickness*.5)
	var track=StyleBoxFlat.new()
	track.bg_color=Color("e9dcc2")
	track.border_color=Color("6b4a33")
	track.set_border_width_all(2)
	track.set_corner_radius_all(radius)
	track.anti_aliasing=true
	var fill=StyleBoxFlat.new()
	fill.bg_color=PetUI.NEED_COLORS.get(key,PetUI.GOLD)
	fill.border_color=Color("6b4a33")
	fill.set_border_width_all(2)
	fill.set_corner_radius_all(radius)
	fill.anti_aliasing=true
	# A light band on the upper half gives the painted look without an image.
	fill.shadow_color=Color(1,1,1,0)
	var bar=ProgressBar.new()
	bar.position=at
	bar.size=Vector2(width,thickness)
	bar.custom_minimum_size=Vector2(0,thickness)
	bar.show_percentage=false
	bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background",track)
	bar.add_theme_stylebox_override("fill",fill)
	parent.add_child(bar)
	bar.set_deferred("size",Vector2(width,thickness))
	var shine=Panel.new()
	var gloss=StyleBoxFlat.new()
	gloss.bg_color=Color(1,1,1,.28)
	gloss.set_corner_radius_all(int(thickness*.25))
	shine.add_theme_stylebox_override("panel",gloss)
	shine.mouse_filter=Control.MOUSE_FILTER_IGNORE
	bar.add_child(shine)
	var place_shine=func():
		var filled=(bar.size.x-6)*clampf((bar.value-bar.min_value)/maxf(1,bar.max_value-bar.min_value),0,1)
		shine.position=Vector2(5,3)
		shine.size=Vector2(maxf(0,filled-6),maxf(2,thickness*.28))
		shine.visible=filled>radius
	bar.value_changed.connect(func(_v): place_shine.call())
	bar.resized.connect(place_shine)
	return bar

static func icon_button(parent: Node, kind: String, bounds: Rect2, callback: Callable) -> Button:
	return square(parent,kind,bounds,callback)

## A48: every icon-only control is the same cream square with a background-free
## glyph (settings, menu, close, bag, back), whatever screen it is on.
const TOOLTIPS={"gear":"Settings","menu":"Menu","close":"Close","basket":"Bag","back":"Back"}
static func square(parent: Node, kind: String, bounds: Rect2, callback: Callable) -> Button:
	var control=PetUI.menu_button(parent,"",callback)
	control.name=TOOLTIPS.get(kind,kind.capitalize()).to_pascal_case()+"Button"
	control.tooltip_text=TOOLTIPS.get(kind,kind.capitalize())
	control.set_meta("animate_symbol",false)
	control.position=bounds.position
	control.size=Vector2.ONE*minf(bounds.size.x,bounds.size.y)
	PetUI.compose(control,"",icon(kind),"icon")
	return control

static func tag(parent: Node, caption: String, bounds: Rect2, kind="") -> Panel:
	var panel=Panel.new()
	panel.add_theme_stylebox_override("panel",PetUI.tag_style())
	panel.position=bounds.position
	panel.size=Vector2(bounds.size.x,PetUI.H_TAG)
	panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	PetUI.compose(panel,caption,icon(kind) if not kind.is_empty() else null,"left",PetUI.F_TAG)
	return panel

## One header for every menu screen: back-with-title on the left; wallet and
## one square (menu or settings) on the right. Returns the parts by name.
static func header(parent: Node, safe: Rect2, title: String, back: Callable, square_kind: String, square_action: Callable, wallet=true) -> Dictionary:
	var h=PetUI.H_HEADER
	var parts={}
	var right=safe.end.x
	if not square_kind.is_empty():
		parts.square=square(parent,square_kind,Rect2(right-h,safe.position.y,h,h),square_action)
		right-=h+8
	if wallet:
		var purse=frame(parent,Rect2(right-118,safe.position.y,118,h))
		purse.name="Wallet"
		PetUI.compose(purse,"0",ArtTexture.load_texture(PetUI.COIN_PATH),"left",PetUI.F_BUTTON+4)
		purse.get_node("Content/Symbol").name="CoinIcon"
		parts.wallet=purse
		parts.wallet_label=purse.get_node("Content/Caption")
		right-=118+8
	if not title.is_empty():
		var width=minf(230,right-safe.position.x)
		if back.is_valid():
			parts.back=button(parent,title,Rect2(safe.position.x,safe.position.y,width,h),back,"back")
			parts.back.tooltip_text="Back"
			(parts.back.get_meta("compose") as Dictionary).points=PetUI.F_BUTTON
			PetUI.arrange(parts.back)
		else:
			parts.title=frame(parent,Rect2(safe.position.x,safe.position.y,width,h))
			PetUI.compose(parts.title,title,null,"left",PetUI.F_BUTTON)
	return parts

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
	pill.size=Vector2(96,40)
	pill.custom_minimum_size=Vector2(96,40)
	pill.clip_text=true
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
	knob.mouse_filter=Control.MOUSE_FILTER_IGNORE
	pill.add_child(knob)
	var centre=func(): knob.position=Vector2(pill.size.x-knob.size.x-5 if on else 5,roundf((pill.size.y-knob.size.y)/2))
	pill.resized.connect(centre)
	centre.call()
	for key in ["normal","hover","pressed","focus"]:
		var padded: StyleBoxFlat=pill.get_theme_stylebox(key).duplicate()
		padded.content_margin_left=16
		padded.content_margin_right=16
		padded.content_margin_top=0
		padded.content_margin_bottom=0
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
