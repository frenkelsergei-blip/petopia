extends TextureRect
## A calm petting/ear/eye/tail pose cycle with one fixed canvas and foot baseline.
var reduced_motion=false
var elapsed=0.0
var frame_index=-1
var frames: Array[AtlasTexture]=[]
const SEQUENCE=[0,1,2,1,0,3]
const DURATIONS=[1.4,0.14,0.28,0.14,0.8,0.44]

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	var spec=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/menu-v3/manifest.json")).friends
	var source: Texture2D=ArtTexture.load_texture(spec.path)
	for r in spec.regions:
		var atlas=AtlasTexture.new()
		atlas.atlas=source
		atlas.region=Rect2(r[0],r[1],r[2],r[3])
		atlas.filter_clip=true
		frames.append(atlas)
	_process(0)

func _process(delta: float) -> void:
	if frames.is_empty(): return
	if not reduced_motion: elapsed=fmod(elapsed+delta,3.2)
	var time=elapsed if not reduced_motion else 0.0
	var next=0
	for i in range(SEQUENCE.size()):
		if time<DURATIONS[i]:
			next=SEQUENCE[i]
			break
		time-=DURATIONS[i]
	if next!=frame_index:
		frame_index=next
		texture=frames[next]
