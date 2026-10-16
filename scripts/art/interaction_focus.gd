class_name InteractionFocus
extends Node2D
## One contextual focus treatment, driven by the action the level actually offers.
var meadow: GrayboxMeadow
var outline: Node2D
var target=""
var point=Vector2.ZERO
var focus_material: ShaderMaterial
func _ready() -> void:
 z_index=3
 outline=Node2D.new()
 var shader=Shader.new()
 shader.code="""shader_type canvas_item;
render_mode unshaded;
uniform float radius=14.0;
void fragment(){
 vec4 base=texture(TEXTURE,UV);
 vec2 d=TEXTURE_PIXEL_SIZE*radius;
 float edge=0.0;
 edge=max(edge,texture(TEXTURE,UV+vec2(d.x,0)).a);
 edge=max(edge,texture(TEXTURE,UV-vec2(d.x,0)).a);
 edge=max(edge,texture(TEXTURE,UV+vec2(0,d.y)).a);
 edge=max(edge,texture(TEXTURE,UV-vec2(0,d.y)).a);
 edge=max(edge,texture(TEXTURE,UV+d*0.707).a);
 edge=max(edge,texture(TEXTURE,UV-d*0.707).a);
 edge=max(edge,texture(TEXTURE,UV+vec2(d.x,-d.y)*0.707).a);
 edge=max(edge,texture(TEXTURE,UV+vec2(-d.x,d.y)*0.707).a);
 COLOR=vec4(1.0,0.91,0.43,edge*(1.0-base.a));
}
"""
 focus_material=ShaderMaterial.new()
 focus_material.shader=shader
 outline.material=focus_material
 outline.draw.connect(draw_outline)
 add_child(outline)
func _process(_delta: float) -> void:
 target=meadow.selected_target
 visible=ArtStyle.enabled and not target.is_empty()
 if not visible:return
 point=meadow.definition.crank
 match target:
  "discovery", "cache":point=meadow.definition.discovery
  "basket":point=meadow.definition.basket
  "gate":point=meadow.definition.return_gate
  "picnic":point=meadow.definition.arrival
  "crate", "crate_bundle":point=meadow.contextual_point
 # Completion and standing directly on an object remove decorative emphasis.
 outline.visible=not meadow.course_finished and meadow.player_point.distance_to(point)>20
 if target=="crank" and meadow.bridge:outline.visible=false
 focus_material.set_shader_parameter("radius",9.0 if target=="crank" else 7.0)
 outline.queue_redraw()
 queue_redraw()
func draw_outline() -> void:
 match target:
  "crank": MeadowCrossingKit.draw_crank(outline,point,meadow.crank_angle,true,true)
  "basket":draw_padded_prop("basket",Vector2(28,29))
  "cache":
   if not meadow.cache_open:draw_padded_prop("chest",Vector2(28,23))
func draw_padded_prop(key: String, size_value: Vector2) -> void:
 var tex=ArtStyle.prop_texture(key) as AtlasTexture
 if tex==null:return
 var factor=size_value/tex.region.size
 var padded=tex.region.grow(9)
 outline.draw_texture_rect_region(tex.atlas,Rect2(point-Vector2(size_value.x*.5,size_value.y)-Vector2.ONE*9*factor,padded.size*factor),padded)
# Action names belong to the real Use/Find controls and objective HUD.
