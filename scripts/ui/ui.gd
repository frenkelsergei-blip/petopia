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

const FRAME_DIR="res://assets/ui/frames-v2/"
## One wooden frame for every button, chip and panel (A47 alignment pass):
## rivet-free art from tools/build_clean_frames.py plus rivets drawn at a fixed
## size by illustrated_style. Gold marks the primary/selected action.
static func frame_style(gold: bool, tint=Color.WHITE) -> StyleBox:
	var key="gold" if gold else "cream"
	if not menu_textures.has(key):
		menu_textures[key]=ArtTexture.load_texture(FRAME_DIR+"frame-"+key+".png")
		menu_textures["rivet"]=ArtTexture.load_texture(FRAME_DIR+"rivet.png")
	var s=preload("res://scripts/ui/illustrated_style.gd").new()
	s.texture=menu_textures[key]
	s.rivet=menu_textures["rivet"]
	s.region=Rect2(73,76,1795,653)
	s.source_corner=175.23
	s.corner=18
	s.tint=tint
	s.content_margin_left=22
	s.content_margin_right=22
	s.content_margin_top=6
	s.content_margin_bottom=6
	return s
static func menu_style(gold: bool, tint=Color.WHITE) -> StyleBox: return frame_style(gold,tint)

## Shared content layout for every framed control. The native Button text is
## kept (accessibility, focus, tests) but drawn transparent; icon and caption
## are child nodes placed by one rule:
##   row  - icon at a fixed inset clear of the rivets, vertically centred;
##          caption centred on the whole button when it fits beside the icon
##   tile - icon centred in the upper part, caption centred below it
##   icon - icon centred
##   left - like row, caption left-aligned after the icon (chips, wallets)
## A caption with a line break shows its second line as a smaller subtitle.
const ROW_INSET=22.0
const FRAME_BORDER=9.0
static func compose(control: Control, caption: String, glyph: Texture2D, layout="row", points=0, color=INK) -> void:
	var box: Control=control.get_node_or_null("Content")
	if box==null:
		box=Control.new()
		box.name="Content"
		box.mouse_filter=Control.MOUSE_FILTER_IGNORE
		control.add_child(box)
		control.resized.connect(func(): arrange(control))
	for child in box.get_children(): child.free()
	if control is Button:
		control.text=caption.replace("\n"," · ") if caption.contains("\n") else caption
		control.icon=null
		control.clip_text=true
		for state_name in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color"]:
			control.add_theme_color_override(state_name,Color.TRANSPARENT)
	var lines=caption.split("\n")
	if glyph!=null:
		var image=TextureRect.new()
		image.name="Symbol"
		image.texture=glyph
		image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		image.mouse_filter=Control.MOUSE_FILTER_IGNORE
		box.add_child(image)
	if not lines[0].is_empty():
		var title=Label.new()
		title.name="Caption"
		title.text=lines[0]
		title.add_theme_font_override("font",load(MENU_FONT_PATH))
		title.add_theme_color_override("font_color",color)
		title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		title.mouse_filter=Control.MOUSE_FILTER_IGNORE
		title.clip_text=true
		box.add_child(title)
	if lines.size()>1:
		var sub=Label.new()
		sub.name="Subcaption"
		sub.text=lines[1]
		sub.add_theme_color_override("font_color",Color("495873"))
		sub.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		sub.mouse_filter=Control.MOUSE_FILTER_IGNORE
		sub.clip_text=true
		box.add_child(sub)
	control.set_meta("compose",{"layout":layout,"points":points})
	arrange(control)

static func fit_points(label: Label, width: float, start: int, minimum: int) -> int:
	var font: Font=label.get_theme_font("font")
	var points=start
	while points>minimum and font.get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,points).x>width: points-=1
	label.add_theme_font_size_override("font_size",points)
	return points

static func arrange(control: Control) -> void:
	var box: Control=control.get_node_or_null("Content")
	if box==null or not control.has_meta("compose"): return
	var spec: Dictionary=control.get_meta("compose")
	var size_value=control.size
	box.position=Vector2.ZERO
	box.size=size_value
	var glyph: TextureRect=box.get_node_or_null("Symbol")
	var title: Label=box.get_node_or_null("Caption")
	var sub: Label=box.get_node_or_null("Subcaption")
	var w=size_value.x
	var h=size_value.y
	var points: int=spec.points
	match spec.layout:
		"tile":
			var s=2*floorf(minf(w-16,h*.5)/2)
			if glyph: _place(glyph,Rect2((w-s)/2,roundf(h*.1),s,s))
			if title:
				title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
				_place(title,Rect2(6,roundf(h*.62),w-12,roundf(h*.3)))
				fit_points(title,w-12,points if points>0 else int(clampf(h*.2,12,18)),10)
		"icon":
			if glyph:
				var s=floorf(minf(w,h)-2*maxf(6,minf(w,h)*.16))
				_place(glyph,Rect2((w-s)/2,(h-s)/2,s,s))
		_:
			var inset=ROW_INSET if w>=110 and h>=44 else 10.0
			var s=2*floorf(clampf(minf(h-22,h*.56),16,48)/2) if glyph else 0.0
			if glyph: _place(glyph,Rect2(inset,(h-s)/2,s,s))
			var left=inset+(s+8 if glyph else 0.0)
			var start=points if points>0 else int(clampf(h*.4,14,26))
			var subtitle_h=0.0
			# The wooden border uses about FRAME_BORDER on each side; a subtitle is
			# only shown when both lines fit inside it.
			if sub: sub.visible=h-2*FRAME_BORDER>=34
			if sub and sub.visible:
				while start>12 and 2*ceilf(start*1.25/2)+roundf(maxf(11,start*.62)*1.3)+2>h-2*FRAME_BORDER: start-=1
				sub.add_theme_font_size_override("font_size",int(maxf(11,start*.62)))
				subtitle_h=roundf(maxf(11,start*.62)*1.3)
			if title:
				var balanced=w-2*left
				var centred=spec.layout!="left" and glyph!=null
				var area=Rect2(left,0,balanced,h) if centred else Rect2(left,0,w-left-inset,h)
				if not glyph and spec.layout!="left": area=Rect2(inset,0,w-2*inset,h)
				title.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT if spec.layout=="left" else HORIZONTAL_ALIGNMENT_CENTER
				var font: Font=title.get_theme_font("font")
				if centred and font.get_string_size(title.text,HORIZONTAL_ALIGNMENT_LEFT,-1,start).x>balanced:
					area=Rect2(left,0,w-left-inset,h)
				fit_points(title,area.size.x,start,12)
				var line_h=2*ceilf(title.get_theme_font_size("font_size")*1.25/2)
				var two=sub!=null and sub.visible
				if not two: subtitle_h=0.0
				var top=(h-line_h-subtitle_h-(2 if two else 0))/2
				_place(title,Rect2(area.position.x,top,area.size.x,line_h))
				if two:
					sub.horizontal_alignment=title.horizontal_alignment
					_place(sub,Rect2(area.position.x,top+line_h+2,area.size.x,subtitle_h))
	if glyph: glyph.set_meta("rest",glyph.position)

static func _place(control: Control, rect: Rect2) -> void:
	control.position=rect.position.round()
	control.size=rect.size.round()
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

static func wallet_style() -> StyleBox: return frame_style(false)
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
	icon.texture = ArtTexture.load_texture(COIN_PATH)
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
