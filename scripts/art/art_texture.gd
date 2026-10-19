class_name ArtTexture
extends RefCounted
## Every source image loads here. Runtime copies are sized for the largest
## supported display but report the source size, so atlas regions, pivots and
## layouts keep source coordinates while phones hold far fewer texels.
const MANIFEST="res://assets/runtime/manifest.json"
static var _plan: Dictionary={}
static var _cache: Dictionary={}
## Tooling only: replaces a source path for measurement captures.
static var overrides: Dictionary={}

static func plan() -> Dictionary:
	if _plan.is_empty() and FileAccess.file_exists(MANIFEST):
		_plan=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST)).textures
	return _plan

## A55: paper-cut redraws (tools/build_paper_pictures.py) replace these pictures.
const PAPER_SWAP={"res://assets/ui/care-v1/meadows-map.png":"res://assets/ui/paper-pictures/care-map.png",
	"res://assets/ui/map-v1/meadows-map.png":"res://assets/ui/paper-pictures/world-map.png",
	"res://assets/ui/care-v1/picnic-finish.png":"res://assets/ui/paper-pictures/picnic-finish.png",
	"res://assets/art/polish-v2/home-garden-scaled.png":"res://assets/ui/paper-pictures/garden.png",
	"res://assets/ui/concept-v1/world-sunny-beach.png":"res://assets/ui/paper-pictures/beach.png",
	"res://assets/ui/concept-v1/world-mystic-forest.png":"res://assets/ui/paper-pictures/forest.png",
	"res://assets/ui/concept-v1/rotate-phone.png":"res://assets/ui/paper-pictures/phone.png",
	"res://assets/art/meadows-v2/town.png":"res://assets/art/paper-v1/village.png"}
## Every path loaded this run (tools check them against the web export list).
static var seen: Dictionary={}
static func load_texture(path: String) -> Texture2D:
	if ArtStyle.paper and PAPER_SWAP.has(path) and ResourceLoader.exists(PAPER_SWAP[path]): path=PAPER_SWAP[path]
	seen[path]=true
	if overrides.has(path): return overrides[path]
	if _cache.has(path):
		var held=_cache[path].get_ref()
		if held!=null: return held
	var texture: Texture2D
	var entry=plan().get(path,{})
	# Uncached Image: the decoded copy is released once uploaded.
	var image: Image=ResourceLoader.load(entry.runtime,"Image",ResourceLoader.CACHE_MODE_IGNORE) if not entry.is_empty() else null
	if image==null:
		# No plan entry, or the copy is not imported yet: the source still works.
		texture=load(path)
	else:
		# Small pieces are drawn far below their size: give them mipmaps.
		if not image.has_mipmaps() and not image.is_compressed() and maxi(image.get_width(),image.get_height())<=520: image.generate_mipmaps()
		var runtime=ImageTexture.create_from_image(image)
		runtime.set_size_override(Vector2i(entry.source[0],entry.source[1]))
		# Registered under the source path: every load of it shares this copy.
		runtime.take_over_path(path)
		texture=runtime
	# Weak: a screen's art is released when that screen lets go of it.
	_cache[path]=weakref(texture)
	return texture
