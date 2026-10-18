class_name ConceptScreen
extends RefCounted
## A55 screens built from their concepts: pieces sliced from each concept's
## Codex sheet (assets/ui/<kit>/, tools/build_screen_paper.py) placed at the
## concept's own coordinates (concept 1672x941), words drawn live.
const W=1672.0
const H=941.0
static var _tex: Dictionary={}
static func tex(kit: String, name: String) -> Texture2D:
	var path="res://assets/ui/%s/%s.png"%[kit,name]
	if not _tex.has(path): _tex[path]=ArtTexture.load_texture(path)
	return _tex[path]

static func piece(parent: Node, kit: String, name: String, rect: Rect2, keep_aspect=true) -> TextureRect:
	var t=TextureRect.new()
	t.name=name.to_pascal_case()
	t.texture=tex(kit,name)
	t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED if keep_aspect else TextureRect.STRETCH_SCALE
	t.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	t.mouse_filter=Control.MOUSE_FILTER_IGNORE
	t.position=rect.position
	t.size=rect.size
	parent.add_child(t)
	return t

static func words(parent: Node, caption: String, rect: Rect2, points: int, color=PetUI.INK, align=HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l=Label.new()
	l.name="Caption"
	l.text=caption
	l.add_theme_font_override("font",load(PetUI.MENU_FONT_PATH))
	l.add_theme_color_override("font_color",color)
	l.horizontal_alignment=align
	l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	l.position=rect.position
	l.size=rect.size
	l.clip_text=false
	parent.add_child(l)
	PetUI.fit_points(l,rect.size.x,maxi(10,points),10)
	return l

## A button drawn with a concept piece; content (optional icon, caption)
## lives in Content/ so callers can update Content/Caption.
static func button(parent: Node, name: String, kit: String, plank: String, rect: Rect2, callback: Callable, caption="", icon: Texture2D=null, points=0, color=PetUI.INK, icon_left=true) -> Button:
	var b=Button.new()
	b.name=name
	b.flat=true
	b.focus_mode=Control.FOCUS_NONE
	b.position=rect.position
	b.size=rect.size
	b.tooltip_text=caption if not caption.is_empty() else name
	for state in ["normal","hover","pressed","focus","disabled"]: b.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	parent.add_child(b)
	var face=piece(b,kit,plank,Rect2(Vector2.ZERO,rect.size),false)
	face.name="Face"
	var box=Control.new()
	box.name="Content"
	box.mouse_filter=Control.MOUSE_FILTER_IGNORE
	box.size=rect.size
	b.add_child(box)
	var h=rect.size.y
	if icon!=null and caption.is_empty():
		var s=h*0.56
		var ic=TextureRect.new()
		ic.name="Symbol"
		ic.texture=icon
		ic.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.mouse_filter=Control.MOUSE_FILTER_IGNORE
		ic.position=(rect.size-Vector2(s,s))*0.5
		ic.size=Vector2(s,s)
		box.add_child(ic)
	elif not caption.is_empty():
		var pts=points if points>0 else int(h*0.42)
		var inset=h*0.42
		var text_rect=Rect2(inset,0,rect.size.x-inset*2,h)
		if icon!=null:
			var s=h*0.5
			var font: Font=load(PetUI.MENU_FONT_PATH)
			var tw=minf(font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,pts).x,rect.size.x-inset*2-s-h*0.15)
			var start=(rect.size.x-(s+h*0.15+tw))*0.5
			var ic=TextureRect.new()
			ic.name="Symbol"
			ic.texture=icon
			ic.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ic.mouse_filter=Control.MOUSE_FILTER_IGNORE
			ic.position=Vector2(start,(h-s)*0.5)
			ic.size=Vector2(s,s)
			box.add_child(ic)
			text_rect=Rect2(start+s+h*0.15,0,tw+4,h)
		words(box,caption,text_rect,pts,color,HORIZONTAL_ALIGNMENT_CENTER if icon==null else HORIZONTAL_ALIGNMENT_LEFT)
	b.button_down.connect(func(): b.modulate=Color(0.86,0.84,0.8))
	b.button_up.connect(func(): b.modulate=Color.WHITE)
	b.pressed.connect(func(): Sound.play("ui_tap",0.0,-6.0); callback.call())
	return b

## A square care/menu tile: big icon above a caption.
static func tile(parent: Node, name: String, kit: String, plank: String, rect: Rect2, callback: Callable, caption: String, icon: Texture2D) -> Button:
	var b=button(parent,name,kit,plank,rect,callback)
	b.tooltip_text=caption
	var box: Control=b.get_node("Content")
	var s=minf(rect.size.x*0.62,rect.size.y*0.58)
	var ic=TextureRect.new()
	ic.name="Symbol"
	ic.texture=icon
	ic.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ic.position=Vector2((rect.size.x-s)*0.5,rect.size.y*0.1)
	ic.size=Vector2(s,s)
	box.add_child(ic)
	words(box,caption,Rect2(rect.size.x*0.08,rect.size.y*0.68,rect.size.x*0.84,rect.size.y*0.24),int(rect.size.y*0.2))
	return b

## A paper meter: a dark groove with a three-sliced coloured paper fill.
static func meter(parent: Node, rect: Rect2, fill: Texture2D, tint=Color.WHITE) -> ProgressBar:
	var bar=ProgressBar.new()
	bar.show_percentage=false
	bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	bar.position=rect.position
	bar.size=rect.size
	var groove=StyleBoxFlat.new()
	groove.bg_color=Color(0.33,0.22,0.12,0.55)
	groove.set_corner_radius_all(int(rect.size.y*0.5))
	bar.add_theme_stylebox_override("background",groove)
	var f=StyleBoxTexture.new()
	f.texture=fill
	f.texture_margin_left=fill.get_height()*0.5
	f.texture_margin_right=fill.get_height()*0.5
	f.modulate_color=tint
	bar.add_theme_stylebox_override("fill",f)
	parent.add_child(bar)
	return bar
