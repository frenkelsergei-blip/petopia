class_name ConceptScenery
extends RefCounted
## A47 V02 scenery kit (Codex-generated, assets/art/concept-world-v1/scenery.png).
## Mid layer stands on banks behind the actors; front layer roots on the bank
## face below the walking line, so it adds depth without hiding the child/pet.
## Placement is a pure function of world x, so it never pops while scrolling.
const ATLAS="res://assets/art/concept-world-v1/scenery.png"
const META="res://assets/art/concept-world-v1/scenery.json"
static var _atlas: Texture2D
static var _props: Dictionary={}
static var _textures: Dictionary={}
## [kind, world height, spacing, phase, needs a continuous bank this wide]
const MID=[["oak",230.0,760.0,300.0,150.0],["birch",196.0,760.0,690.0,70.0],["flower_bush",58.0,520.0,120.0,80.0],["bush",42.0,430.0,380.0,60.0],["rock",26.0,610.0,520.0,50.0],["fence",34.0,980.0,820.0,60.0]]
const FRONT=[["fern",44.0,340.0,40.0],["flowers",34.0,290.0,190.0],["bush",40.0,530.0,410.0],["fern",38.0,470.0,300.0]]
static func prepare() -> void:
	if _atlas!=null: return
	_atlas=ArtTexture.load_texture(ATLAS)
	_props=JSON.parse_string(FileAccess.get_file_as_string(META)).props
static func release() -> void:
	_atlas=null
	_textures.clear()
static func texture(kind: String) -> AtlasTexture:
	prepare()
	if not _textures.has(kind):
		var r: Array=_props[kind].region
		var t=AtlasTexture.new()
		t.atlas=_atlas
		t.region=Rect2(r[0],r[1],r[2],r[3])
		t.filter_clip=true
		_textures[kind]=t
	return _textures[kind]
static func draw_kind(canvas: CanvasItem, kind: String, feet: Vector2, height: float, flip=false) -> void:
	var t=texture(kind)
	var width=height*t.region.size.x/t.region.size.y
	if flip: canvas.draw_set_transform(Vector2(feet.x*2,0),0,Vector2(-1,1))
	canvas.draw_texture_rect(t,Rect2(feet-Vector2(width*.5,height),Vector2(width,height)),false)
	if flip: canvas.draw_set_transform(Vector2.ZERO)
static func jitter(x: float, salt: float) -> float:
	return fposmod(sin(x*12.9898+salt*78.233)*43758.5453,1.0)
static func mid_placements(ground: Array[Rect2], camera_x: float, reserved: Array[Vector2]) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for spec in MID:
		var spacing: float=spec[2]
		var first=floorf((camera_x-260-spec[3])/spacing)
		for i in range(int(first),int(first)+4):
			var x=spec[3]+i*spacing
			x+=(jitter(x,spec[1])-.5)*spacing*.25
			if x<camera_x-260 or x>camera_x+900: continue
			if not ArtStyle.scenery_clear(x,spec[4]*.6,reserved): continue
			var y=ArtStyle.support_y(ground,x,spec[4]*.5)
			if y==INF: continue
			result.append({"kind":spec[0],"point":Vector2(x,y+3),"height":spec[1]*(0.9+jitter(x,3.0)*.2),"flip":jitter(x,7.0)>.5})
	# Big trees first so bushes overlap their roots.
	result.sort_custom(func(a,b): return a.height>b.height)
	return result
static func draw_mid(canvas: CanvasItem, camera_x: float, ground: Array[Rect2], reserved: Array[Vector2]) -> void:
	for entry in mid_placements(ground,camera_x,reserved):
		draw_kind(canvas,entry.kind,entry.point,entry.height,entry.flip)
static func draw_front(canvas: CanvasItem, camera_x: float, ground: Array[Rect2]) -> void:
	for spec in FRONT:
		var spacing: float=spec[2]
		var first=floorf((camera_x-120-spec[3])/spacing)
		for i in range(int(first),int(first)+4):
			var x=spec[3]+i*spacing+(jitter(spec[3]+i*spacing,spec[1])-.5)*spacing*.3
			if x<camera_x-120 or x>camera_x+760: continue
			var y=ArtStyle.support_y(ground,x,spec[1]*.6)
			if y==INF: continue
			# Rooted on the bank face; the top stays below the actors' feet.
			draw_kind(canvas,spec[0],Vector2(x,y+spec[1]+4),spec[1],jitter(x,5.0)>.5)
