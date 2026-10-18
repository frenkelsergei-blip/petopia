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

## A49 UI kit (assets/ui/kit-v1, scripts/ui/kit_style.gd): carved panel for
## outer containers, gold/cream pills for buttons, round icon buttons, tiles,
## strips, tags. Role weights below are kept for callers that pass them.
const CORNER_THIN=10.0
const CORNER_PANEL=14.0
const CORNER_BOARD=16.0
static func kit_style(piece: String, corner_px=20.0, tint=Color.WHITE) -> StyleBox:
	var s=preload("res://scripts/ui/kit_style.gd").new()
	s.piece=piece
	s.corner_px=corner_px
	s.tint=tint
	for side in [SIDE_LEFT,SIDE_RIGHT]: s.set_content_margin(side,16)
	for side in [SIDE_TOP,SIDE_BOTTOM]: s.set_content_margin(side,4)
	return s
## Buttons (A49): gold pill = primary/selected, cream pill = secondary.
static func frame_style(gold: bool, tint=Color.WHITE, corner=CORNER_THIN) -> StyleBox:
	var s=kit_style("pill_gold" if gold else "pill_cream",20.0,tint)
	s.corner=corner
	return s
## Point every state of a button at one kit piece (pressed uses its pair).
static func set_piece(control: Control, piece: String, pressed="", corner_px=20.0) -> void:
	if control is Button:
		control.add_theme_stylebox_override("normal",kit_style(piece,corner_px))
		control.add_theme_stylebox_override("hover",kit_style(piece,corner_px))
		control.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
		control.add_theme_stylebox_override("pressed",kit_style(pressed if not pressed.is_empty() else piece,corner_px,Color(.92,.92,.92) if pressed.is_empty() else Color.WHITE))
		control.add_theme_stylebox_override("disabled",kit_style(piece,corner_px,Color(.85,.85,.85,.8)))
	else:
		control.add_theme_stylebox_override("panel",kit_style(piece,corner_px))
static func pressed_style(gold: bool) -> StyleBox: return kit_style("pill_gold_pressed" if gold else "pill_cream_pressed")
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
## A48 component rules: every control takes one of these roles, so heights and
## text sizes repeat exactly across screens. Touch targets stay >= 48.
const H_PRIMARY=60.0
const H_BUTTON=52.0
const H_HEADER=52.0
const H_HUD=48.0
const H_TAG=32.0
const F_TITLE=28
const F_PRIMARY=24
const F_BUTTON=20
const F_TILE=16
const F_TAG=15
## Role height in layout points that still gives >=48 physical pixels when a
## screen draws its canvas smaller than the window (short phones, fixed canvases).
static func touch_height(base: float, control: Control, logical_height: float) -> float:
	var physical=float(control.get_window().size.y)
	return maxf(base,ceilf(48.0*logical_height/maxf(1,physical)))
## Tags are information, not actions: a flat rounded label so they never read
## as a broken button (pet name, region, "Coming later", goal).
## One text size per group: siblings use the largest size that fits all of them.
static func unify(controls: Array) -> void:
	var smallest=999
	for c in controls:
		if not is_instance_valid(c) or not c.has_meta("compose"): continue
		var caption: Label=c.get_node_or_null("Content/Caption")
		if caption: smallest=mini(smallest,caption.get_theme_font_size("font_size"))
	if smallest==999: return
	for c in controls:
		if not is_instance_valid(c) or not c.has_meta("compose"): continue
		var spec: Dictionary=c.get_meta("compose")
		spec.points=smallest
		spec.locked=true
		arrange(c)
const ROW_INSET=16.0
const FRAME_BORDER=6.0
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
		sub.add_theme_font_override("font",load(MENU_FONT_PATH))
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
			var s=2*floorf(minf(w-16,h*.56)/2)
			if glyph: _place(glyph,Rect2((w-s)/2,roundf(h*.1),s,s))
			if title:
				title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
				_place(title,Rect2(6,roundf(h*.62),w-12,roundf(h*.3)))
				fit_points(title,w-12,points if points>0 else int(clampf(h*.2,12,18)),10)
		"icon":
			if glyph:
				# Round buttons: the icon stays inside the inner circle of the ring.
				var s=2*floorf(minf(w,h)*.5/2)
				_place(glyph,Rect2((w-s)/2,(h-s)/2,s,s))
		"round_label":
			var d=minf(w,h)
			if glyph:
				# Icon and label share one fixed grid inside the ring's cream face
				# (face spans ~14%..86%), so every button reads at the same height.
				var s=2*floorf(d*.40/2)
				_place(glyph,Rect2((w-s)/2,roundf(h*.17),s,s))
			if title:
				title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
				title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
				_place(title,Rect2(d*.2,roundf(h*.58),d*.6,roundf(h*.2)))
				title.add_theme_font_size_override("font_size",int(clampf(d*.17,10,14)))
		_:
			# Content starts inside the pill's rounded end, whatever the height.
			var inset=maxf(ROW_INSET,roundf(h*.36)) if w>=110 and h>=40 else 10.0
			# Plank pieces have studs at their ends; keep content clear of them.
			var box_style=control.get_theme_stylebox("panel") if control is Panel else null
			if box_style!=null and box_style.get("piece")=="hud_plank": inset=maxf(inset,roundf(h*.5))
			var s=2*floorf(clampf(minf(h-22,h*.56),16,48)/2) if glyph else 0.0
			if glyph: _place(glyph,Rect2(inset,(h-s)/2,s,s))
			var left=inset+(s+8 if glyph else 0.0)
			var start=points if points>0 else int(clampf(h*.4,14,26))
			var subtitle_h=0.0
			# The wooden border uses about FRAME_BORDER on each side; a subtitle is
			# only shown when both lines fit inside it.
			if sub: sub.visible=h-2*FRAME_BORDER>=34
			if sub and sub.visible:
				while start>14 and 2*ceilf(start*1.25/2)+roundf(maxf(13,start*.68)*1.3)+2>h-2*FRAME_BORDER: start-=1
				sub.add_theme_font_size_override("font_size",int(maxf(13,start*.68)))
				subtitle_h=roundf(maxf(13,start*.68)*1.3)
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
				if two: fit_points(sub,area.size.x,sub.get_theme_font_size("font_size"),12)
				if two and sub.get_theme_font("font").get_string_size(sub.text,HORIZONTAL_ALIGNMENT_LEFT,-1,sub.get_theme_font_size("font_size")).x>area.size.x:
					# A subtitle that does not fit is dropped, never clipped.
					sub.visible=false
					title.position.y=roundf((h-line_h)/2)
				elif two:
					sub.horizontal_alignment=title.horizontal_alignment
					_place(sub,Rect2(area.position.x,top+line_h+2,area.size.x,subtitle_h))
	if glyph: glyph.set_meta("rest",glyph.position)

static func _place(control: Control, rect: Rect2) -> void:
	control.position=rect.position.round()
	control.size=rect.size.round()
static func menu_button(parent: Node, text: String, callback: Callable, primary=false) -> Button:
	var b=button(parent,text,Rect2(0,0,320,60),callback,primary)
	# User selected the quieter cream face for every menu action, including Start.
	b.add_theme_stylebox_override("normal",menu_style(primary))
	b.add_theme_stylebox_override("hover",menu_style(primary))
	b.add_theme_stylebox_override("pressed",pressed_style(primary))
	b.add_theme_stylebox_override("disabled",kit_style("pill_disabled"))
	b.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
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

static func set_frame_weight(control: Control, corner: float) -> void:
	for state_name in ["normal","hover","pressed","disabled","panel"]:
		if control.has_theme_stylebox_override(state_name):
			var box=control.get_theme_stylebox(state_name)
			if box.get("weight")!=null:
				box.corner=corner
				box.weight=1.0 if corner<=CORNER_THIN else (1.4 if corner<=CORNER_PANEL else 1.8)
## Inner cards (light parchment, no wood): the default for content blocks.
static func wallet_style() -> StyleBox: return kit_style("card",14.0)
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

## A flat single-colour copy of a picture (icon shapes in another ink).
static var _flat: Dictionary={}
static func flat_ink(color: Color) -> ShaderMaterial:
	var key=color.to_html()
	if not _flat.has(key):
		var sh=Shader.new()
		sh.code="shader_type canvas_item;\nuniform vec4 ink;\nvoid fragment(){ COLOR=vec4(ink.rgb,texture(TEXTURE,UV).a*ink.a); }"
		var m=ShaderMaterial.new()
		m.shader=sh
		m.set_shader_parameter("ink",color)
		_flat[key]=m
	return _flat[key]
