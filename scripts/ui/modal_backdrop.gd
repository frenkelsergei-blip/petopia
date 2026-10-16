class_name ModalBackdrop
extends TextureRect
## Blur only the live world texture. UI and portrait are drawn afterwards.
## Both Gaussian passes run at half resolution; no screenshot/readback per frame.
var horizontal_view: SubViewport
var vertical_view: SubViewport
const BLUR_SHADER=preload("res://scripts/ui/modal_blur.gdshader")

func configure(source: Texture2D, dimensions: Vector2) -> void:
	name="ModalBackdrop"
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	size=dimensions
	var reduced=Vector2i(maxi(1,ceili(dimensions.x*.5)),maxi(1,ceili(dimensions.y*.5)))
	horizontal_view=make_pass(source,reduced,Vector2(2.0/dimensions.x,0))
	vertical_view=make_pass(horizontal_view.get_texture(),reduced,Vector2(0,2.0/dimensions.y))
	texture=vertical_view.get_texture()

func make_pass(source: Texture2D, dimensions: Vector2i, direction: Vector2) -> SubViewport:
	var view=SubViewport.new()
	view.size=dimensions
	view.disable_3d=true
	view.transparent_bg=false
	view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	add_child(view)
	var image=TextureRect.new()
	image.texture=source
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	image.size=Vector2(dimensions)
	var blur=ShaderMaterial.new()
	blur.shader=BLUR_SHADER
	blur.set_shader_parameter("direction",direction)
	image.material=blur
	view.add_child(image)
	return view
