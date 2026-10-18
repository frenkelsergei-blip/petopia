class_name ArtStyle
extends RefCounted
## Shared source-aligned art. Rendering never changes collision or saved layouts.
static var enabled=true
## A55: characters and worlds drawn in the paper-theater style.
static var paper=true
static var _atlas: Texture2D
static var _background: Texture2D
static var _environment: Texture2D
static var _tree: Texture2D
static var _runs: Dictionary={}
static var _run_atlases: Dictionary={}
static var _frames: Dictionary={}
static var _polish: Dictionary={}
static var _textures: Dictionary={}
const COIN_SIZE=20.0
static func prepare() -> void:
	if _atlas!=null: return
	_atlas=ArtTexture.load_texture("res://assets/art/pilot-v1/actors-terrain-atlas.png")
	_frames=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/pilot-v1/manifest.json")).frames
	_polish=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/polish-v2/manifest.json"))
	_background=ArtTexture.load_texture(_polish.background)
	_environment=ArtTexture.load_texture(_polish.atlas)
	_tree=ArtTexture.load_texture("res://assets/art/meadow-kit-v3/meadow-tree.png")
	_runs=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/meadow-system-v4/run-metadata.json"))
## Screens call this when they change; art still drawn stays alive through
## its nodes, everything else is released instead of held for the session.
static func release() -> void:
	_atlas=null
	_background=null
	_environment=null
	_tree=null
	_run_atlases.clear()
	_textures.clear()
	ConceptScenery.release()
static func region_texture(atlas: Texture2D, region: Array, key: String) -> AtlasTexture:
	if not _textures.has(key):
		var t=AtlasTexture.new()
		t.atlas=atlas
		t.region=Rect2(region[0],region[1],region[2],region[3])
		t.filter_clip=true
		_textures[key]=t
	return _textures[key]
static func texture(key: String) -> AtlasTexture:
	prepare()
	return region_texture(_atlas,_frames[key],key)
static func prop_texture(key: String) -> Texture2D:
	prepare()
	if key=="tree": return region_texture(_tree,[11,44,1069,1361],"tree_root_trimmed")
	return region_texture(_environment,_polish.frames[key],"prop_"+key)
static func run_count(identity: String) -> int:
	prepare()
	return _runs[identity].frames.size()
static func run_stride(identity: String) -> float:
	prepare()
	return float(_runs[identity].stride_world)
static func run_frame(identity: String, frame: int) -> Dictionary:
	prepare()
	return _runs[identity].frames[posmod(frame,run_count(identity))]
static func walk_texture(identity: String, frame: int) -> AtlasTexture:
	prepare()
	var path="res://"+_runs[identity].atlas
	if not _run_atlases.has(path): _run_atlases[path]=ArtTexture.load_texture(path)
	return region_texture(_run_atlases[path],run_frame(identity,frame).region,"v4_"+identity+"_"+str(posmod(frame,run_count(identity))))
static func walk_row(identity: String) -> Dictionary:
	prepare()
	return _runs[identity]
static func draw_background(canvas: CanvasItem, camera_x: float) -> void:
	prepare()
	# Keep background architecture behind the hero scale instead of magnifying
	# a panorama to fill the scene. Mirrored distant panels preserve edge color.
	canvas.draw_rect(Rect2(camera_x-4,0,648,400),Color("61b5fc"))
	var drift=fposmod(camera_x*0.08,800)
	for index in range(-1,4):
		var x=camera_x+index*400-drift
		if x+400<camera_x or x>camera_x+640: continue
		if posmod(index,2):
			canvas.draw_set_transform(Vector2(x*2+400,0),0,Vector2(-1,1))
		canvas.draw_texture_rect(_background,Rect2(x,120,400,200),false)
		canvas.draw_set_transform(Vector2.ZERO)
	canvas.draw_rect(Rect2(camera_x-2,0,646,400),Color(0.87,0.92,0.96,0.13))

static func support_y(ground: Array[Rect2], x: float, half_width: float) -> float:
	# Trees/bushes require a continuous deep bank, never a gap or thin moving ledge.
	var found=INF
	for rect in ground:
		if rect.size.y<48: continue
		if x-half_width>=rect.position.x and x+half_width<=rect.end.x: found=minf(found,rect.position.y)
	return found
static func root_support(ground: Array[Rect2], x: float, width: float) -> float:
	var y=support_y(ground,x,width*.5)
	if y==INF:return INF
	for rect in ground:
		if rect.position.x<x+width*.4 and rect.end.x>x-width*.4 and rect.position.y<y and rect.end.y>=y:
			return INF
	return y
static func scenery_clear(x: float, width: float, reserved: Array[Vector2]) -> bool:
	for point in reserved:
		if absf(x-point.x)<width*.5+32:return false
	return true
static func scenery_placements(ground: Array[Rect2], camera_x: float, reserved: Array[Vector2]=[]) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for kind in ["tree","shrub"]:
		var stride=550 if kind=="tree" else 310
		var first=420 if kind=="tree" else 80
		var width=82 if kind=="tree" else 42
		for index in range(14):
			var x=float(first+index*stride)
			if x<camera_x-100 or x>camera_x+740: continue
			if not scenery_clear(x,width,reserved):continue
			var y=root_support(ground,x,width) if kind=="tree" else support_y(ground,x,width*.5)
			if y==INF: continue
			result.append({"kind":kind,"point":Vector2(x,y),"width":width,"height":96 if kind=="tree" else 25})
	for index in range(5):
		var x=float(60+index*1100)
		if x<camera_x-100 or x>camera_x+740: continue
		if not scenery_clear(x,130,reserved):continue
		var y=root_support(ground,x,130)
		if y!=INF: result.append({"kind":"tree","point":Vector2(x,y),"width":130,"height":150})
	return result
static func draw_scenery(canvas: CanvasItem, camera_x: float, ground: Array[Rect2], reserved: Array[Vector2]=[]) -> void:
	draw_background(canvas,camera_x)
	for entry in scenery_placements(ground,camera_x,reserved):
		draw_prop(canvas,entry.kind,entry.point+Vector2(0,7 if entry.kind=="tree" else 2),Vector2(entry.width,entry.height))
static func draw_prop(canvas: CanvasItem, key: String, feet: Vector2, size_value: Vector2) -> void:
	canvas.draw_texture_rect(prop_texture(key),Rect2(feet-Vector2(size_value.x*0.5,size_value.y),size_value),false)
static func draw_chest(canvas: CanvasItem, feet: Vector2, opened: bool, treasure=true) -> void:
	if not opened:
		draw_prop(canvas,"chest",feet,Vector2(28,23))
		return
	var tex=prop_texture("chest") as AtlasTexture
	var factor=Vector2(28,23)/tex.region.size
	var lid=tex.region.size.y*.34
	canvas.draw_texture_rect_region(tex.atlas,Rect2(feet+Vector2(-14,-23+lid*factor.y),Vector2(28,23-lid*factor.y)),Rect2(tex.region.position+Vector2(0,lid),Vector2(tex.region.size.x,tex.region.size.y-lid)))
	canvas.draw_rect(Rect2(feet+Vector2(-12,-16),Vector2(24,4)),Color("443523"))
	if treasure:
		var coin=ArtTexture.load_texture(PetUI.COIN_PATH)
		for at in [Vector2(-6,-14),Vector2(0,-16),Vector2(6,-13)]:
			canvas.draw_texture_rect(coin,Rect2(feet+at-Vector2(3,3),Vector2(6,6)),false)
	canvas.draw_set_transform(feet+Vector2(-14,-13),-.65)
	canvas.draw_texture_rect_region(tex.atlas,Rect2(0,-lid*factor.y,28,lid*factor.y),Rect2(tex.region.position,Vector2(tex.region.size.x,lid)))
	canvas.draw_set_transform(Vector2.ZERO)
static func draw_picnic(canvas: CanvasItem, feet: Vector2, basket_present=false) -> void:
	# Grounded story landmark. The blanket has a shallow, angled ground plane.
	var points=PackedVector2Array([feet+Vector2(-23,-2),feet+Vector2(18,-2),feet+Vector2(25,2),feet+Vector2(-28,2)])
	canvas.draw_colored_polygon(points,Color("b94e57"))
	for i in range(7):
		canvas.draw_line(feet+Vector2(-20+i*6,-2),feet+Vector2(-23+i*7,2),Color("fff0cd"),1.3)
	canvas.draw_line(feet+Vector2(-25,0),feet+Vector2(22,0),Color("fff0cd"),1)
	if basket_present:draw_prop(canvas,"basket",feet+Vector2(8,0),Vector2(25,25))
static func exposed_segments(rect: Rect2, ground: Array[Rect2]) -> Array[Vector2]:
	var segments: Array[Vector2]=[Vector2(rect.position.x,rect.end.x)]
	for other in ground:
		if other==rect or other.position.y>rect.position.y-0.1 or other.end.y<rect.position.y: continue
		var next: Array[Vector2]=[]
		for segment in segments:
			if other.end.x<=segment.x or other.position.x>=segment.y: next.append(segment)
			else:
				if other.position.x>segment.x: next.append(Vector2(segment.x,other.position.x))
				if other.end.x<segment.y: next.append(Vector2(other.end.x,segment.y))
		segments=next
	return segments
