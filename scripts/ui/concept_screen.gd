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
## One soft shadow for every button in the game (P41/P50/P60: a light halo
## all around the piece, a touch lower than it).
const BUTTON_SHADOW=0.42
## Shadow work size: the SHORT side is scaled to this, so a wide plank keeps
## as thick a halo as a square tile; PAD is the halo width at that scale.
const SHADOW_SHORT=36.0
const SHADOW_PAD=7
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
	var f=minf(SHADOW_SHORT/minf(img.get_width(),img.get_height()),256.0/maxf(img.get_width(),img.get_height()))
	var w=maxi(4,int(img.get_width()*f))
	var h=maxi(4,int(img.get_height()*f))
	img.resize(w,h,Image.INTERPOLATE_LANCZOS)
	var pad=SHADOW_PAD
	var out=Image.create(w+pad*2,h+pad*2,false,Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			out.set_pixel(x+pad,y+pad,Color(0.2,0.13,0.06,img.get_pixel(x,y).a))
	var full=out.get_size()
	for k in 3:
		out.resize(maxi(2,int(full.x*0.55)),maxi(2,int(full.y*0.55)),Image.INTERPOLATE_BILINEAR)
		out.resize(full.x,full.y,Image.INTERPOLATE_CUBIC)
	out.resize(full.x*4,full.y*4,Image.INTERPOLATE_CUBIC)
	var tex=ImageTexture.create_from_image(out)
	tex.set_meta("grow",Vector2(float(pad)/w,float(pad)/h))
	_shadows[key]=tex
	return tex
## Where a piece's soft shadow goes: grown evenly on every side, a little low.
static func shadow_rect(r: Rect2, sh: Texture2D) -> Rect2:
	var g: Vector2=sh.get_meta("grow",Vector2(0.12,0.12))*r.size
	return Rect2(r.position-g+Vector2(0,maxf(1.0,r.size.y*0.03)),r.size+g*2)
## Adds the soft shadow behind `t` (same parent, drawn behind it).
static func add_shadow(t: TextureRect, strength=BUTTON_SHADOW) -> void:
	var sh=soft_shadow(t.texture)
	if sh==null: return
	var s=TextureRect.new()
	s.name=t.name+"Shadow"
	s.texture=sh
	s.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	s.stretch_mode=TextureRect.STRETCH_SCALE
	s.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var r=shadow_rect(Rect2(t.position,t.size),sh)
	# Pieces kept to their aspect inside a wider box: shadow the drawn part.
	if t.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED and t.texture:
		var ts=t.texture.get_size()
		var k=minf(t.size.x/ts.x,t.size.y/ts.y)
		var d=ts*k
		r=shadow_rect(Rect2(t.position+(t.size-d)*0.5,d),sh)
	s.position=r.position
	s.size=r.size
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

## A coin pill that grows with its number: the coin end keeps its shape and
## the cream part stretches to the left, so 3, 4 or 5 digits always fit.
## Returns the number's label (meta "pill" holds the final pill rect).
static func coin_pill(parent: Node, kit: String, rect: Rect2, value: String, points: int, color=PetUI.INK, text_from=0.42, name="coins") -> Label:
	var t: Texture2D=tex(kit,name)
	var font: Font=load(PetUI.MENU_FONT_PATH)
	# The coin end keeps its true shape: its width follows the pill's height.
	var s=rect.size.y/float(t.get_height())
	var coin_w=t.get_width()*text_from*s
	var end_pad=rect.size.y*0.3
	var area=maxf(rect.size.x-coin_w-end_pad,rect.size.y*0.6)
	# Room for one more digit than shown, so the pill does not jump at once.
	var need=font.get_string_size(value+"0",HORIZONTAL_ALIGNMENT_LEFT,-1,points).x
	var w=coin_w+maxf(area,need)+end_pad
	var r=Rect2(rect.end.x-w,rect.position.y,w,rect.size.y)
	var np=NinePatchRect.new()
	np.name=name.to_pascal_case()
	np.texture=t
	np.patch_margin_left=int(t.get_width()*text_from)
	np.patch_margin_right=int(t.get_width()*0.12)
	np.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	np.mouse_filter=Control.MOUSE_FILTER_IGNORE
	np.position=r.position
	np.scale=Vector2(s,s)
	np.size=r.size/s
	parent.add_child(np)
	var l=words(parent,value,Rect2(r.position.x+coin_w,r.position.y,r.size.x-coin_w-end_pad*0.6,r.size.y),points,color)
	l.set_meta("pill",r)
	return l

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


## A58 (P68): ONE frame for every screen, from the style guide concept P68
## (frame-p68 kit, each piece with its own soft shadow): a header (round
## close X, title plaque with leaves, coin pill) above one cream card. Tiles,
## buttons, tabs, rows and slots inside come from the same kit.
const P68="res://assets/ui/frame-p68/"
static var _p68: Dictionary={}
static func p68_meta() -> Dictionary:
	if _p68.is_empty(): _p68=JSON.parse_string(FileAccess.get_file_as_string(P68+"kit.json"))
	return _p68
static func p68_ready() -> bool: return FileAccess.file_exists(P68+"kit.json")
## A kit piece whose paper (not its shadow) fills r. Long pieces stretch only
## in their middle; `edge` is the screen size of the torn border.
static func p68(parent: Node, name: String, r: Rect2, edge=-1.0) -> NinePatchRect:
	if p69_ready() and P68_TO_P69.has(name): return p69(parent,P68_TO_P69[name],r,edge)
	return _nine(parent,P68,p68_meta()[name],name,"P68_"+name,r,edge,[])
static func _nine(parent: Node, dir: String, M: Dictionary, name: String, node: String, r: Rect2, edge: float, ends: Array) -> NinePatchRect:
	var bd: Array=M.body
	var sz: Array=M.size
	var np=NinePatchRect.new()
	np.name=node
	np.texture=ArtTexture.load_texture(dir+name+".png")
	np.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	np.mouse_filter=Control.MOUSE_FILTER_IGNORE
	# Texture scale: the border keeps its drawn look (about 1/4 of the short side).
	var short=minf(float(bd[2]),float(bd[3]))
	var k=r.size.y/float(bd[3]) if edge<0 else edge/(short*0.25)
	k=minf(k,minf(r.size.x/float(bd[2]),r.size.y/float(bd[3]))*4.0)
	# Leaves or a coin at an end: that end keeps its drawn shape.
	var ml=short*0.3 if ends.is_empty() else float(bd[2])*float(ends[0])
	var mr=short*0.3 if ends.is_empty() else float(bd[2])*float(ends[1])
	if ml+mr>r.size.x/k*0.98: k=r.size.x*0.98/(ml+mr)
	np.patch_margin_left=int(float(bd[0])+ml)
	np.patch_margin_right=int(float(sz[0])-float(bd[0])-float(bd[2])+mr)
	np.patch_margin_top=int(float(bd[1])+short*0.3)
	np.patch_margin_bottom=int(float(sz[1])-float(bd[1])-float(bd[3])+short*0.3)
	np.scale=Vector2(k,k)
	np.position=r.position-Vector2(bd[0],bd[1])*k
	np.size=Vector2(r.size.x/k+float(sz[0])-float(bd[2]),r.size.y/k+float(sz[1])-float(bd[3]))
	parent.add_child(np)
	return np

## A59 (P69): every screen's pieces, copied by Codex from the approved P69
## concepts (assets/ui/<kit>-p69, tools/build_blue_kit.py). id = "kit/name".
static var _p69: Dictionary={}
static func p69_meta(kit: String) -> Dictionary:
	if not _p69.has(kit): _p69[kit]=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/%s-p69/kit.json"%kit))
	return _p69[kit]
static func p69_ready() -> bool: return FileAccess.file_exists("res://assets/ui/frame-p69/kit.json")
static func p69_tex(id: String) -> Texture2D:
	var a=id.split("/")
	return tex(a[0]+"-p69",a[1])
## The old P68 piece names now draw the P69 pieces.
const P68_TO_P69={"plaque":"frame/plaque","close":"frame/close","tile":"frame/tile","button":"frame/green","tab":"frame/tab","tab_on":"frame/tab_on","row":"frame/row","slot":"frame/tile","card":"controls/group"}
## Ends that must not stretch (fraction of the paper's width, left/right).
const P69_ENDS={"frame/plaque":[0.2,0.2],"frame/big_green":[0.14,0.14],"frame/coins":[0.36,0.12],"frame/price":[0.38,0.14],"overlay/banner":[0.24,0.24],"overlay/sign":[0.26,0.1],"ball/meter":[0.1,0.1],"ball/hint":[0.08,0.08],"ball/score":[0.1,0.1]}
static func p69(parent: Node, id: String, r: Rect2, edge=-1.0) -> NinePatchRect:
	var a=id.split("/")
	return _nine(parent,"res://assets/ui/%s-p69/"%a[0],p69_meta(a[0])[a[1]],a[1],"P69_"+a[1],r,edge,P69_ENDS.get(id,[]))
## Swaps a kit button's face for a P69 piece (still named Face).
static func p69_face(b: Button, id: String) -> NinePatchRect:
	var old=b.get_node_or_null("Face")
	if old:
		b.remove_child(old)
		old.free()
	var f=p69(b,id,Rect2(Vector2.ZERO,b.size))
	f.name="Face"
	b.move_child(f,0)
	return f
## A P69 piece at its own shape, its paper w wide, centred on c.
static func p69_whole(parent: Node, id: String, c: Vector2, w: float) -> TextureRect:
	var a=id.split("/")
	var M: Dictionary=p69_meta(a[0])[a[1]]
	var bd: Array=M.body
	var sz: Array=M.size
	var k=w/float(bd[2])
	var t=TextureRect.new()
	t.name="P69_"+a[1]
	t.texture=p69_tex(id)
	t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode=TextureRect.STRETCH_SCALE
	t.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	t.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var body=Rect2(c-Vector2(bd[2],bd[3])*k*0.5,Vector2(bd[2],bd[3])*k)
	t.position=body.position-Vector2(bd[0],bd[1])*k
	t.size=Vector2(sz[0],sz[1])*k
	parent.add_child(t)
	return t
## An icon or picture fitted (aspect kept) into r.
static func p69_icon(parent: Node, id: String, r: Rect2) -> TextureRect:
	var t=TextureRect.new()
	t.name="Icon_"+id.get_file()
	t.texture=p69_tex(id)
	t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	t.mouse_filter=Control.MOUSE_FILTER_IGNORE
	t.position=r.position
	t.size=r.size
	parent.add_child(t)
	return t
## A kit piece drawn at its own shape (no stretching) with its body width w,
## centred on c.
static func p68_whole(parent: Node, name: String, c: Vector2, w: float) -> TextureRect:
	if p69_ready() and P68_TO_P69.has(name): return p69_whole(parent,P68_TO_P69[name],c,w)
	var M: Dictionary=p68_meta()[name]
	var bd: Array=M.body
	var sz: Array=M.size
	var k=w/float(bd[2])
	var t=TextureRect.new()
	t.name="P68_"+name
	t.texture=ArtTexture.load_texture(P68+name+".png")
	t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode=TextureRect.STRETCH_SCALE
	t.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	t.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var body=Rect2(c-Vector2(bd[2],bd[3])*k*0.5,Vector2(bd[2],bd[3])*k)
	t.position=body.position-Vector2(bd[0],bd[1])*k
	t.size=Vector2(sz[0],sz[1])*k
	parent.add_child(t)
	return t
## A kit button: the piece, a centred caption (optional icon to its left).
static func p68_button(parent: Node, name: String, piece: String, r: Rect2, cb: Callable, caption="", icon: Texture2D=null, color=PetUI.INK, pts=0) -> Button:
	var b=Button.new()
	b.name=name
	b.flat=true
	b.focus_mode=Control.FOCUS_NONE
	b.text=caption
	b.tooltip_text=caption if not caption.is_empty() else name
	for c in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color"]: b.add_theme_color_override(c,Color.TRANSPARENT)
	for st in ["normal","hover","pressed","focus","disabled"]: b.add_theme_stylebox_override(st,StyleBoxEmpty.new())
	b.position=r.position
	b.size=r.size
	parent.add_child(b)
	var face=p68(b,piece,Rect2(Vector2.ZERO,r.size))
	face.name="Face"
	var box=Control.new()
	box.name="Content"
	box.size=r.size
	box.mouse_filter=Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	if not caption.is_empty():
		var p2=maxi(8,pts if pts>0 else int(r.size.y*0.42))
		var font: Font=load(PetUI.MENU_FONT_PATH)
		var tw=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,p2).x
		var isz=r.size.y*0.52 if icon!=null else 0.0
		var gap=r.size.y*0.12 if icon!=null else 0.0
		var x0=(r.size.x-(isz+gap+tw))*0.5
		if icon!=null:
			var ic=TextureRect.new()
			ic.name="Symbol"
			ic.texture=icon
			ic.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ic.mouse_filter=Control.MOUSE_FILTER_IGNORE
			ic.position=Vector2(maxf(x0,r.size.y*0.2),(r.size.y-isz)*0.5)
			ic.size=Vector2(isz,isz)
			box.add_child(ic)
			x0=ic.position.x+isz+gap
			words(box,caption,Rect2(x0,0,r.size.x-x0-r.size.y*0.2,r.size.y),p2,color,HORIZONTAL_ALIGNMENT_LEFT)
		else: words(box,caption,Rect2(r.size.y*0.2,0,r.size.x-r.size.y*0.4,r.size.y),p2,color)
	elif icon!=null:
		var s2=r.size.y*0.56
		var ic=TextureRect.new()
		ic.name="Symbol"
		ic.texture=icon
		ic.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.mouse_filter=Control.MOUSE_FILTER_IGNORE
		ic.position=(r.size-Vector2(s2,s2))*0.5
		ic.size=Vector2(s2,s2)
		box.add_child(ic)
	b.button_down.connect(func(): b.modulate=Color(0.88,0.85,0.8))
	b.button_up.connect(func(): b.modulate=Color.WHITE)
	b.pressed.connect(func(): Sound.play("ui_tap",0.0,-6.0); cb.call())
	return b
## The header and card. Returns {"card": Rect2 (the card's paper),
## "inner": Rect2 (content area inside its border), "k": unit scale,
## "coins": Label}. Same sizes on every screen for a given safe area.
static func p68_page(parent: Node, safe: Rect2, title: String, close_cb: Callable, coins: String) -> Dictionary:
	var dim=ColorRect.new()
	dim.name="P68Dim"
	dim.color=Color(0.12,0.09,0.05,0.5)
	dim.size=Vector2(4000,4000)
	dim.position=-Vector2(1000,1000)
	dim.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(dim)
	var u=page_unit(safe)
	var hd=page_header(parent,safe,title,close_cb,coins)
	# One layer only (P69): tiles, rows and buttons sit straight on the dimmed
	# screen; the content starts right under the header, 25 units from the sides.
	var top=safe.position.y+108.0*u
	var card=Rect2(safe.position.x+22.0*u,top,safe.size.x-44.0*u,safe.end.y-top-14.0*u)
	return {"card":card,"inner":card,"k":u,"coins":hd.coins}
## P69 measures: a portrait screen is 500 units wide.
static func page_unit(safe: Rect2) -> float:
	var portrait=safe.size.x<safe.size.y
	return clampf(minf(safe.size.x/500.0,safe.size.y/(880.0 if portrait else 500.0)),0.5,1.35)
## The one header of every screen (P69): round X on the left, the leafy
## title plaque centred, the coin pill on the right only when coins is set.
static func page_header(parent: Node, safe: Rect2, title: String, close_cb: Callable, coins: String) -> Dictionary:
	var u=page_unit(safe)
	var top=safe.position.y+26.0*u
	var hh=68.0*u
	var cy=top+hh*0.5
	var close=p68_button(parent,"CloseScreen","close",Rect2(safe.position.x+18.0*u,cy-32.0*u,64.0*u,64.0*u),close_cb)
	close.tooltip_text="Close"
	var coin: Label=null
	var right=safe.end.x-18.0*u
	if not coins.is_empty():
		coin=p68_coins(parent,Rect2(right-132.0*u,cy-37.0*u,132.0*u,74.0*u),coins)
		right=(coin.get_meta("pill") as Rect2).position.x-10.0*u
	var font: Font=load(PetUI.MENU_FONT_PATH)
	var pts=maxi(8,int(hh*0.6))
	var tw=font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,pts).x
	var left=safe.position.x+92.0*u
	var room=minf(right,safe.end.x-92.0*u)-left
	var pw=minf(room if coins.is_empty() else right-left,maxf(tw+120.0*u,200.0*u))
	var cx=clampf(safe.get_center().x,left+pw*0.5,right-pw*0.5)
	var plr=Rect2(cx-pw*0.5,top,pw,hh)
	p69(parent,"frame/plaque",plr)
	var tl=words(parent,title,plr.grow_individual(-48.0*u,0,-48.0*u,0),pts)
	tl.name="ScreenTitle"
	return {"coins":coin,"plaque":plr,"u":u}
## The dim behind a page (drawn first by the caller's parent order).
static func p68_dim(parent: Node, size: Vector2) -> void:
	var d=ColorRect.new()
	d.name="P68Dim"
	d.color=Color(0.12,0.09,0.05,0.62)
	d.size=size
	d.mouse_filter=Control.MOUSE_FILTER_STOP
	parent.add_child(d)
	parent.move_child(d,0)

## The coin pill of every screen (the main menu's, growing with the number).
static func p68_coins(parent: Node, r: Rect2, value: String) -> Label:
	if p69_ready():
		# P69: the one coin pill (its gold paw coin is part of the piece).
		var c=coin_pill(parent,"frame-p69",r,value,int(r.size.y*0.6),Color("fff8e8"),0.36,"coins")
		c.add_theme_color_override("font_outline_color",Color("2f6a1f"))
		c.add_theme_constant_override("outline_size",maxi(3,int(r.size.y*0.1)))
		# The canonical coin sits exactly on the pill's drawn coin (33..122 x
		# 24..110 of the 322 x 154 piece), so every screen shows one coin.
		var pr: Rect2=c.get_meta("pill")
		var s=pr.size.y/154.0
		var ci=TextureRect.new()
		ci.name="CoinIcon"
		ci.texture=ArtTexture.load_texture(PetUI.COIN_PATH)
		ci.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		ci.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ci.mouse_filter=Control.MOUSE_FILTER_IGNORE
		ci.position=pr.position+Vector2(31,22)*s
		ci.size=Vector2(93,90)*s
		parent.add_child(ci)
		return c
	var coin=coin_pill(parent,"menu41-p32",r,value,int(r.size.y*0.55),Color("fff6e0"),0.42,"m_coin_pill")
	coin.add_theme_color_override("font_outline_color",Color("2f5a1c"))
	coin.add_theme_constant_override("outline_size",maxi(3,int(r.size.y*0.09)))
	var pr: Rect2=coin.get_meta("pill")
	var cs=pr.size.y*1.12
	var ci=TextureRect.new()
	ci.name="CoinIcon"
	ci.texture=ArtTexture.load_texture(PetUI.COIN_PATH)
	ci.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	ci.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ci.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ci.position=Vector2(pr.position.x-cs*0.12,pr.get_center().y-cs*0.5)
	ci.size=Vector2(cs,cs)
	parent.add_child(ci)
	return coin
