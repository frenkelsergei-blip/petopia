class_name PetUI
extends RefCounted

const INK = Color("182952")
const CREAM = Color("fff3d9")
const GREEN = Color("47aa64")
const WOOD = Color("65432e")
const GOLD = Color("ffc84b")
const BLUE = Color("459ddd")
const COIN_PATH = "res://assets/ui/coin-gold-v1.png"
const MENU_FONT_PATH = "res://assets/fonts/lilita-one/LilitaOne-Regular.ttf"
static var menu_textures: Dictionary = {}

static func menu_style(gold: bool, tint=Color.WHITE) -> StyleBox:
	var key="gold" if gold else "cream"
	if not menu_textures.has(key):
		menu_textures[key]=load("res://assets/ui/menu-v1/button-"+key+".png")
	var s=preload("res://scripts/ui/illustrated_style.gd").new()
	s.texture=menu_textures[key]
	s.region=Rect2(24,96,2124,529) if gold else Rect2(45,114,2083,480)
	s.tint=tint
	s.content_margin_left=26
	s.content_margin_right=26
	s.content_margin_top=8
	s.content_margin_bottom=8
	return s

static func menu_button(parent: Node, text: String, callback: Callable, primary=false) -> Button:
	var b=button(parent,text,Rect2(0,0,320,60),callback,primary)
	# User selected the quieter cream face for every menu action, including Start.
	b.add_theme_stylebox_override("normal",menu_style(false))
	b.add_theme_stylebox_override("hover",menu_style(true))
	b.add_theme_stylebox_override("pressed",menu_style(true,Color("ecd19a")))
	b.add_theme_stylebox_override("disabled",menu_style(false,Color("d9dcdf")))
	b.add_theme_color_override("font_focus_color",INK)
	b.add_theme_color_override("font_disabled_color",Color("41495a"))
	b.add_theme_font_size_override("font_size",24)
	b.add_theme_font_override("font",load(MENU_FONT_PATH))
	b.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	var motion=preload("res://scripts/ui/menu_button_motion.gd").new()
	motion.name="MenuButtonMotion"
	motion.button=b
	b.add_child(motion)
	return b

static func wallet_style() -> StyleBox:
	var spec=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/menu-v2/manifest.json")).wallet
	var s=preload("res://scripts/ui/illustrated_style.gd").new()
	s.texture=load("res://assets/ui/menu-v2/wallet.png")
	var r=spec.region
	s.region=Rect2(r[0],r[1],r[2],r[3])
	s.source_corner=spec.source_corner
	s.corner=18
	return s
const NEED_COLORS = {"fullness": Color("f3a631"), "happiness": Color("ec5993"), "energy": Color("efcc42"), "cleanliness": Color("3cafe5"), "health": Color("45bf72"), "bond": Color("9464d9")}

static func style(color: Color, radius: int = 14) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.border_color = WOOD
	s.set_border_width_all(2)
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s

static func panel(parent: Node, bounds: Rect2, color: Color = CREAM) -> Panel:
	var p = Panel.new()
	p.position = bounds.position
	p.size = bounds.size
	p.add_theme_stylebox_override("panel", style(color))
	parent.add_child(p)
	return p

static func modal(parent: Node, bounds: Rect2) -> Panel:
	var result=panel(parent,bounds)
	result.set_meta("modal",true)
	return result

static func label(parent: Node, text: String, xy: Vector2, font_size: int = 22, color: Color = INK, width: float = 0) -> Label:
	var l = Label.new()
	l.position = xy
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if width > 0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size.x = width
	l.text = text
	parent.add_child(l)
	return l

static func button(parent: Node, text: String, bounds: Rect2, callback: Callable, primary: bool = false) -> Button:
	var b = Button.new()
	b.text = text
	b.position = bounds.position
	b.size = bounds.size
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_stylebox_override("normal", style(GOLD if primary else CREAM,10))
	b.add_theme_stylebox_override("hover", style(Color("ffdc81") if primary else Color("fff2ad"),10))
	b.add_theme_stylebox_override("pressed", style(Color("e9b248"),10))
	b.add_theme_stylebox_override("disabled", style(Color("dcd6c5"),10))
	var focus = style(Color(0,0,0,0),10)
	focus.border_color = BLUE
	focus.set_border_width_all(3)
	b.add_theme_stylebox_override("focus",focus)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_focus_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_pressed_color", INK)
	b.add_theme_color_override("font_disabled_color", Color("61657a"))
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

static func coin_display(parent: Node, xy: Vector2, caption: String = "Coins", illustrated=false) -> Label:
	var badge = panel(parent, Rect2(xy, Vector2(220,72)))
	if illustrated: badge.add_theme_stylebox_override("panel",wallet_style())
	badge.name = "CoinBadge"
	var icon = TextureRect.new()
	icon.name = "CoinIcon"
	icon.texture = load(COIN_PATH)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.position = Vector2(12,16)
	icon.size = Vector2(40,40)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(icon)
	label(badge, caption, Vector2(64,4),17)
	return label(badge, "0", Vector2(64,27),26)

static func meter(parent: Node, text: String, value: float, xy: Vector2, width: float = 270, color: Color = GREEN) -> ProgressBar:
	label(parent,text,xy,17)
	var bar = ProgressBar.new()
	bar.position = xy + Vector2(0,28)
	bar.size = Vector2(width,10)
	bar.value = value
	bar.show_percentage = false
	var track_style = style(Color("c9cbd4"),5)
	track_style.set_border_width_all(0)
	track_style.content_margin_left=0
	track_style.content_margin_right=0
	track_style.content_margin_top=0
	track_style.content_margin_bottom=0
	var fill_style = style(color,5)
	fill_style.set_border_width_all(0)
	fill_style.content_margin_left=0
	fill_style.content_margin_right=0
	fill_style.content_margin_top=0
	fill_style.content_margin_bottom=0
	bar.add_theme_stylebox_override("background",track_style)
	bar.add_theme_stylebox_override("fill",fill_style)
	parent.add_child(bar)
	# Theme changes invalidate the old minimum size on the next layout pass.
	bar.set_deferred("size",Vector2(width,10))
	return bar
