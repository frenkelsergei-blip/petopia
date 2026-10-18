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
## Every icon is cropped to its visible pixels (icon-bounds.json), so all icons
## fill their slot the same way instead of carrying different empty margins.
static var bounds: Dictionary={}
## Context action icons (one 128 px cell each in concept-v1/actions.png).
const ACTION_ICONS=["act_find","act_use","act_jump","act_enter","act_open","act_read","act_pick","act_dig","act_place"]
static func tight(kind: String, cell: Rect2) -> Rect2:
	if bounds.is_empty(): bounds=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/concept-v1/icon-bounds.json"))
	if not bounds.has(kind): return cell
	var r: Array=bounds[kind]
	return Rect2(r[0],r[1],r[2],r[3])
static func icon(kind: String) -> Texture2D:
	if cache.has(kind): return cache[kind]
	if kind.begins_with("food_"):
		var foods: Dictionary=GameState.foods().foods
		var id=kind.substr(5)
		var food_icon=AtlasTexture.new()
		food_icon.atlas=ArtTexture.load_texture("res://assets/ui/food-v1/foods.png")
		food_icon.region=Rect2(int(foods[id].icon)*128,0,128,128)
		food_icon.filter_clip=true
		cache[kind]=food_icon
		return food_icon
	if kind=="ball":
		# The yellow sun ball: the same ball Foxy carries in its animations.
		cache[kind]=ArtTexture.load_texture("res://assets/ui/ball-v1/sun-ball.png")
		return cache[kind]
	if kind=="menu":
		# Menu: a hanging wooden sign, like the signs in the world.
		cache[kind]=ArtTexture.load_texture("res://assets/ui/concept-v1/menu-sign.png")
		return cache[kind]
	if kind in ACTION_ICONS:
		var action=AtlasTexture.new()
		action.atlas=ArtTexture.load_texture("res://assets/ui/concept-v1/actions.png")
		action.region=tight(kind,Rect2(ACTION_ICONS.find(kind)*128,0,128,128))
		action.filter_clip=true
		cache[kind]=action
		return action
	if GLYPHS.has(kind):
		var g: Array=GLYPHS[kind]
		var glyph=AtlasTexture.new()
		glyph.atlas=ArtTexture.load_texture("res://assets/ui/concept-v1/glyphs.png")
		glyph.region=tight(kind,Rect2(g[0]*CONCEPT_CELL,g[1]*CONCEPT_CELL,CONCEPT_CELL,CONCEPT_CELL))
		glyph.filter_clip=true
		cache[kind]=glyph
		return glyph
	if CONCEPT_ICONS.has(kind):
		var cell: Array=CONCEPT_ICONS[kind]
		var sheet=AtlasTexture.new()
		sheet.atlas=ArtTexture.load_texture("res://assets/ui/concept-v1/hud-icons.png")
		sheet.region=tight(kind,Rect2(cell[0]*CONCEPT_CELL,cell[1]*CONCEPT_CELL,CONCEPT_CELL,CONCEPT_CELL))
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
## Outer container: the only element with the carved wood frame (A49).
static func panel(parent: Node, bounds: Rect2) -> Panel:
	var box=PetUI.panel(parent,bounds)
	PetUI.set_piece(box,"panel","",22.0)
	box.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	return box
## Frameless strip for stat and reward rows; gold for totals.
static func strip(parent: Node, bounds: Rect2, gold=false) -> Panel:
	var box=PetUI.panel(parent,bounds)
	PetUI.set_piece(box,"row_gold" if gold else "row")
	box.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	return box
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
	if shape=="tile": PetUI.set_piece(control,"tile_gold" if primary else "tile","",16.0)
	PetUI.compose(control,text,icon(kind) if not kind.is_empty() else null,shape)
	return control

## Need meters: fully rounded track and fill at every width (the painted bar
## crop left a square right end), colours from PetUI.NEED_COLORS.
## Need meter from the kit: track plus a tinted fill. The fill is never
## narrower than its height, so its rounded ends never squash.
static func meter(parent: Node, at: Vector2, width: float, key: String, thickness=18.0) -> ProgressBar:
	var bar=ProgressBar.new()
	bar.position=at
	bar.size=Vector2(width,thickness)
	bar.custom_minimum_size=Vector2(0,thickness)
	bar.show_percentage=false
	bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background",PetUI.kit_style("meter_track"))
	bar.add_theme_stylebox_override("fill",StyleBoxEmpty.new())
	parent.add_child(bar)
	bar.set_deferred("size",Vector2(width,thickness))
	var fill=Panel.new()
	fill.name="Fill"
	fill.mouse_filter=Control.MOUSE_FILTER_IGNORE
	fill.add_theme_stylebox_override("panel",PetUI.kit_style("meter_fill",20.0,PetUI.NEED_COLORS.get(key,PetUI.GOLD).lightened(.05)))
	bar.add_child(fill)
	var place=func():
		var ratio=clampf((bar.value-bar.min_value)/maxf(1,bar.max_value-bar.min_value),0,1)
		var inner=bar.size-Vector2(4,4)
		fill.visible=ratio>0
		fill.position=Vector2(2,2)
		fill.size=Vector2(maxf(inner.y,inner.x*ratio),inner.y)
	bar.value_changed.connect(func(_v): place.call())
	bar.resized.connect(place)
	return bar

static func icon_button(parent: Node, kind: String, bounds: Rect2, callback: Callable) -> Button:
	return square(parent,kind,bounds,callback)

## A48: every icon-only control is the same cream square with a background-free
## glyph (settings, menu, close, bag, back), whatever screen it is on.
const TOOLTIPS={"gear":"Settings","menu":"Menu","close":"Close","basket":"Bag","back":"Back"}
static func square(parent: Node, kind: String, bounds: Rect2, callback: Callable) -> Button:
	var control=PetUI.menu_button(parent,"",callback)
	PetUI.set_piece(control,"round","round_pressed")
	control.name=TOOLTIPS.get(kind,kind.capitalize()).to_pascal_case()+"Button"
	control.tooltip_text=TOOLTIPS.get(kind,kind.capitalize())
	control.set_meta("animate_symbol",false)
	control.position=bounds.position
	control.size=Vector2.ONE*minf(bounds.size.x,bounds.size.y)
	# The Menu button carries a small label under its bars, as in the kit.
	PetUI.compose(control,"",icon(kind),"icon")
	return control

## fit=true: the pill hugs its text and is centred in the given bounds.
## Pet name badge: our fox's face in a small gold medallion ring, overlapping
## a cream name pill (used above Foxy in the room).
static func name_badge(parent: Node, caption: String, at: Vector2) -> Control:
	var holder=Control.new()
	holder.name="NameBadge"
	holder.mouse_filter=Control.MOUSE_FILTER_IGNORE
	holder.position=at
	parent.add_child(holder)
	var d=40.0
	var font: Font=load(PetUI.MENU_FONT_PATH)
	var text_w=ceilf(font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x)
	var pill=Panel.new()
	pill.mouse_filter=Control.MOUSE_FILTER_IGNORE
	PetUI.set_piece(pill,"tag")
	pill.position=Vector2(d*.6,(d-30)/2)
	pill.size=Vector2(d*.4+text_w+18,30)
	holder.add_child(pill)
	var label=Label.new()
	label.name="Caption"
	label.text=caption
	label.add_theme_font_override("font",font)
	label.add_theme_font_size_override("font_size",17)
	label.add_theme_color_override("font_color",PetUI.INK)
	label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	label.position=Vector2(d*.4+4,0)
	label.size=Vector2(text_w+8,30)
	pill.add_child(label)
	var face=TextureRect.new()
	face.texture=ArtTexture.load_texture("res://assets/ui/kit-v1/fox-medal.png")
	face.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	face.position=Vector2(d*.12,d*.12)
	face.size=Vector2.ONE*d*.76
	face.mouse_filter=Control.MOUSE_FILTER_IGNORE
	holder.add_child(face)
	var ring=TextureRect.new()
	ring.texture=ArtTexture.load_texture("res://assets/ui/kit-v1/medal_ring.png")
	ring.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	ring.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ring.size=Vector2.ONE*d
	ring.mouse_filter=Control.MOUSE_FILTER_IGNORE
	holder.add_child(ring)
	holder.size=Vector2(pill.position.x+pill.size.x,d)
	return holder

static func tag(parent: Node, caption: String, bounds: Rect2, kind="", fit=false) -> Panel:
	var panel=Panel.new()
	PetUI.set_piece(panel,"tag")
	panel.position=bounds.position
	panel.size=Vector2(bounds.size.x,PetUI.H_TAG)
	panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	PetUI.compose(panel,caption,icon(kind) if not kind.is_empty() else null,"left",PetUI.F_TAG)
	if fit:
		var label: Label=panel.get_node("Content/Caption")
		var font: Font=label.get_theme_font("font")
		var inset=maxf(PetUI.ROW_INSET,roundf(PetUI.H_TAG*.36))
		var glyph=(2*floorf(clampf(minf(PetUI.H_TAG-22,PetUI.H_TAG*.56),16,48)/2)+8) if not kind.is_empty() else 0.0
		var needed=ceilf(inset*2+glyph+font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,PetUI.F_TAG).x+4)
		if needed<bounds.size.x:
			panel.position.x=bounds.position.x+roundf((bounds.size.x-needed)/2)
			panel.size.x=needed
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
		PetUI.set_piece(purse,"wallet")
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
			PetUI.set_piece(parts.title,"hud_plank")
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
## On/Off switch from the kit, drawn at its own proportions (knob included).
const SWITCH_SIZE=Vector2(84,42)
static func toggle(parent: Node, on: bool, callback: Callable) -> Button:
	var pill=Button.new()
	pill.size=SWITCH_SIZE
	pill.custom_minimum_size=SWITCH_SIZE
	pill.text="On" if on else "Off"
	pill.tooltip_text=pill.text
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: pill.add_theme_color_override(key,Color.TRANSPARENT)
	PetUI.set_piece(pill,"switch_on" if on else "switch_off")
	pill.pressed.connect(callback)
	parent.add_child(pill)
	return pill

## Left/right selector: two round arrow buttons around a value pill.
static func stepper(parent: Node, value: String, can_lower: bool, can_raise: bool, callback: Callable, width=196.0) -> Control:
	var holder=Control.new()
	holder.size=Vector2(width,42)
	parent.add_child(holder)
	for entry in [[-1,"left",0.0,can_lower],[1,"right",width-42,can_raise]]:
		var arrow=PetUI.menu_button(holder,"",func(): pass)
		arrow.get_node("MenuButtonMotion").queue_free()
		PetUI.set_piece(arrow,"round","round_pressed")
		arrow.name="Lower" if entry[0]<0 else "Raise"
		arrow.position=Vector2(entry[2],0)
		arrow.size=Vector2(42,42)
		arrow.disabled=not entry[3]
		var direction: int=entry[0]
		for c in arrow.pressed.get_connections(): arrow.pressed.disconnect(c.callable)
		arrow.pressed.connect(func(): callback.call(direction))
		PetUI.compose(arrow,"",icon(entry[1]),"icon")
		arrow.modulate=Color(1,1,1,1.0 if entry[3] else .45)
	var value_tag=tag(holder,value,Rect2(46,5,width-92,PetUI.H_TAG))
	(value_tag.get_meta("compose") as Dictionary).layout="row"
	PetUI.arrange(value_tag)
	return holder
