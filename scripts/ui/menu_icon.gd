extends TextureRect
## Reference-derived full-resolution icons; fit without stretching the silhouette.
var kind="play"
static var textures: Dictionary={}
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	if not textures.has(kind):
		var spec=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/menu-v3/manifest.json")).icons[kind]
		var atlas=AtlasTexture.new()
		atlas.atlas=load("res://assets/ui/menu-v3/"+kind+".png")
		var r=spec.region
		atlas.region=Rect2(r[0],r[1],r[2],r[3])
		atlas.filter_clip=true
		textures[kind]=atlas
	texture=textures[kind]
