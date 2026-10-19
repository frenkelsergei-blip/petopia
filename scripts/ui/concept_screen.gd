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

## A soft, blurred shadow of a piece's own silhouette (cached per texture),
## as under every button and icon in the P32 concepts.
static var _shadows: Dictionary={}
## One soft shadow for every button in the game (P60: light, low, blurred).
const BUTTON_SHADOW=0.3
static func soft_shadow(t: Texture2D) -> Texture2D:
	if t==null: return null
	var key=t.get_rid()
	if _shadows.has(key): return _shadows[key]
	var img: Image=t.get_image()
	if img==null:
		_shadows[key]=null
		return null
	img=img.duplicate()
	if img.is_compressed(): img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	# Work at ~64 px with a wide transparent margin, then blur many times so
	# the edge falls off smoothly (no blocky steps when scaled up).
	var f=64.0/maxf(img.get_width(),img.get_height())
	var w=maxi(8,int(img.get_width()*f))
	var h=maxi(8,int(img.get_height()*f))
	img.resize(w,h,Image.INTERPOLATE_LANCZOS)
	var pad=8
	var out=Image.create(w+pad*2,h+pad*2,false,Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			out.set_pixel(x+pad,y+pad,Color(0.18,0.12,0.06,img.get_pixel(x,y).a))
	var full=out.get_size()
	for k in 4:
		out.resize(maxi(2,int(full.x*0.6)),maxi(2,int(full.y*0.6)),Image.INTERPOLATE_BILINEAR)
		out.resize(full.x,full.y,Image.INTERPOLATE_CUBIC)
	out.resize(full.x*4,full.y*4,Image.INTERPOLATE_CUBIC)
	var tex=ImageTexture.create_from_image(out)
	_shadows[key]=tex
	return tex
## Adds the soft shadow just below `t` (same parent, drawn behind it).
static func add_shadow(t: TextureRect, strength=0.32) -> void:
	var sh=soft_shadow(t.texture)
	if sh==null: return
	var s=TextureRect.new()
	s.name=t.name+"Shadow"
	s.texture=sh
	s.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	s.stretch_mode=t.stretch_mode
	s.mouse_filter=Control.MOUSE_FILTER_IGNORE
	# The padded shadow covers a little more than the piece, offset downwards.
	var f=64.0/maxf(t.texture.get_width(),t.texture.get_height())
	var grow=t.size*Vector2(8.0/maxf(8,t.texture.get_width()*f),8.0/maxf(8,t.texture.get_height()*f))
	# Lit from above: the shadow sits a little lower than the piece.
	s.position=t.position-grow+Vector2(0,maxf(1.0,t.size.y*0.02))
	s.size=t.size+grow*2
	s.modulate.a=strength
	t.get_parent().add_child(s)
	t.get_parent().move_child(s,t.get_index())

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

## A large torn-paper board drawn as a nine-patch: the torn edges keep their
## own scale (crisp) and only the paper middle stretches.
static func slab(parent: Node, kit: String, name: String, rect: Rect2, margin=0.18) -> NinePatchRect:
	var t=NinePatchRect.new()
	t.name=name.to_pascal_case()
	t.texture=tex(kit,name)
	var m=int(minf(t.texture.get_width(),t.texture.get_height())*margin)
	t.patch_margin_left=m
	t.patch_margin_right=m
	t.patch_margin_top=m
	t.patch_margin_bottom=m
	# Repeat the paper rather than stretch it (stretching draws streaks).
	t.axis_stretch_horizontal=NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	t.axis_stretch_vertical=NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	t.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	t.mouse_filter=Control.MOUSE_FILTER_IGNORE
	t.position=rect.position
	t.size=rect.size
	parent.add_child(t)
	# Icons and pictures on a button carry the soft shadow too.
	if parent is Button or (parent.name=="Content" and parent.get_parent() is Button): add_shadow(t,BUTTON_SHADOW*0.8)
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
	# The native text stays (accessibility, tests) but is never drawn.
	b.text=caption
	b.clip_text=true
	for c in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color"]: b.add_theme_color_override(c,Color.TRANSPARENT)
	for state in ["normal","hover","pressed","focus","disabled"]: b.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	parent.add_child(b)
	var face=piece(b,kit,plank,Rect2(Vector2.ZERO,rect.size),false)
	face.name="Face"
	# P60/P61: every paper button sits on a soft, low shadow.
	add_shadow(face,BUTTON_SHADOW)
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
		add_shadow(ic,BUTTON_SHADOW*0.8)
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
	b.text=caption
	var box: Control=b.get_node("Content")
	var s=minf(rect.size.x*0.56,rect.size.y*0.52)
	var ic=TextureRect.new()
	ic.name="Symbol"
	ic.texture=icon
	ic.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ic.position=Vector2((rect.size.x-s)*0.5,rect.size.y*0.1)
	ic.size=Vector2(s,s)
	box.add_child(ic)
	add_shadow(ic,BUTTON_SHADOW*0.8)
	words(box,caption,Rect2(rect.size.x*0.08,rect.size.y*0.62,rect.size.x*0.84,rect.size.y*0.3),int(rect.size.y*0.26))
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
