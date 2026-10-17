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

static func load_texture(path: String) -> Texture2D:
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
		var runtime=ImageTexture.create_from_image(image)
		runtime.set_size_override(Vector2i(entry.source[0],entry.source[1]))
		# Registered under the source path: every load of it shares this copy.
		runtime.take_over_path(path)
		texture=runtime
	# Weak: a screen's art is released when that screen lets go of it.
	_cache[path]=weakref(texture)
	return texture
