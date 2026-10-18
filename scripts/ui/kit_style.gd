extends StyleBox
## A49 UI kit piece (assets/ui/kit-v1). Pieces are never stretched out of shape:
##  three - rounded ends keep their true proportions, scaled by height only;
##          the length comes from a thin uniform centre slice of the source.
##  nine  - corners keep their shape at one size (corner_px); edges extend
##          from uniform centre slices; the plain centre fills the rest.
##  fixed - drawn at its own aspect ratio, centred (round buttons, medals).
const DIR="res://assets/ui/kit-v1/"
static var spec: Dictionary={}
static var textures: Dictionary={}
var piece="pill_cream"
var corner_px=20.0
var tint=Color.WHITE
var corner=0.0   # role weight, kept for callers that read/compare it
var weight=1.0

## A55: the paper kit (assets/ui/kit-paper, tools/build_kit_paper.py) has the
## same piece names; pieces it does not have fall back to kit-v1.
const PAPER_DIR="res://assets/ui/kit-paper/"
static var paper_spec: Dictionary={}
static func paper_has(name: String) -> bool:
	if not ArtStyle.paper: return false
	if paper_spec.is_empty(): paper_spec=JSON.parse_string(FileAccess.get_file_as_string(PAPER_DIR+"kit.json"))
	return paper_spec.has(name)
static func info(name: String) -> Dictionary:
	if paper_has(name): return paper_spec[name]
	if spec.is_empty(): spec=JSON.parse_string(FileAccess.get_file_as_string(DIR+"kit.json"))
	return spec[name]
static func texture(name: String) -> Texture2D:
	if not textures.has(name): textures[name]=ArtTexture.load_texture((PAPER_DIR if paper_has(name) else DIR)+name+".png")
	return textures[name]
## Smallest width at which a three-slice piece of this height keeps both ends.
static func min_width(name: String, height: float) -> float:
	var i=info(name)
	if i.slice!="three": return 0.0
	return 2.0*float(i.cap)*height/float(i.size[1])+2.0

func _get_minimum_size() -> Vector2: return Vector2.ZERO

func _draw(canvas: RID, rect: Rect2) -> void:
	var i=info(piece)
	var tex=texture(piece)
	var sw=float(i.size[0])
	var sh=float(i.size[1])
	match i.slice:
		"three":
			var s=rect.size.y/sh
			var cap=float(i.cap)
			var cap_d=minf(cap*s,rect.size.x*.5)
			var src_cap=cap_d/s
			var mid=Rect2(sw*.5-2,0,4,sh)
			tex.draw_rect_region(canvas,Rect2(rect.position,Vector2(cap_d,rect.size.y)),Rect2(0,0,src_cap,sh),tint)
			tex.draw_rect_region(canvas,Rect2(rect.position+Vector2(rect.size.x-cap_d,0),Vector2(cap_d,rect.size.y)),Rect2(sw-src_cap,0,src_cap,sh),tint)
			if rect.size.x>2*cap_d: tex.draw_rect_region(canvas,Rect2(rect.position+Vector2(cap_d,0),Vector2(rect.size.x-2*cap_d,rect.size.y)),mid,tint)
		"nine":
			var m=float(i.margin)
			var c=minf(corner_px,minf(rect.size.x,rect.size.y)*.5)
			var cx=[0.0,m,sw-m,sw]
			var cy=[0.0,m,sh-m,sh]
			var dx=[0.0,c,rect.size.x-c,rect.size.x]
			var dy=[0.0,c,rect.size.y-c,rect.size.y]
			for row in range(3):
				for col in range(3):
					var src=Rect2(cx[col],cy[row],cx[col+1]-cx[col],cy[row+1]-cy[row])
					# Edges use a thin slice from the middle of their span, so
					# wood grain is never squeezed or smeared along an edge.
					if col==1 and row!=1: src=Rect2(sw*.5-2,src.position.y,4,src.size.y)
					if row==1 and col!=1: src=Rect2(src.position.x,sh*.5-2,src.size.x,4)
					var dst=Rect2(rect.position+Vector2(dx[col],dy[row]),Vector2(dx[col+1]-dx[col],dy[row+1]-dy[row]))
					if dst.size.x>0 and dst.size.y>0: tex.draw_rect_region(canvas,dst,src,tint)
		_:
			var f=minf(rect.size.x/sw,rect.size.y/sh)
			var size_value=Vector2(sw,sh)*f
			tex.draw_rect(canvas,Rect2(rect.position+(rect.size-size_value)*.5,size_value),false,tint)
