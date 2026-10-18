class_name ContactShadow
extends Node2D
## Sparse pixel clusters projected onto terrain, separate from the actor sprite.
var actor: GrayboxActor
var clearance=0.0
static var _soft: GradientTexture2D
static func soft() -> GradientTexture2D:
 if _soft==null:
  var g=Gradient.new()
  g.set_color(0,Color(0.08,0.1,0.03,0.85))
  g.add_point(0.45,Color(0.1,0.12,0.04,0.45))
  g.set_color(g.get_point_count()-1,Color(0.1,0.12,0.04,0.0))
  _soft=GradientTexture2D.new()
  _soft.gradient=g
  _soft.fill=GradientTexture2D.FILL_RADIAL
  _soft.fill_from=Vector2(0.5,0.5)
  _soft.fill_to=Vector2(1.0,0.5)
  _soft.width=64
  _soft.height=64
 return _soft
func _ready() -> void:
 z_index=-1
 texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR if ArtStyle.paper else CanvasItem.TEXTURE_FILTER_NEAREST
func _physics_process(_delta: float) -> void:
 if not is_instance_valid(actor): return
 visible=ArtStyle.enabled
 var body=actor.get_parent()
 clearance=0
 position=Vector2.ZERO
 if body is CharacterBody2D:
  var query=PhysicsRayQueryParameters2D.create(body.global_position-Vector2(0,2),body.global_position+Vector2(0,125),1,[body.get_rid()])
  var hit=body.get_world_2d().direct_space_state.intersect_ray(query)
  if hit.is_empty():
   visible=false
   return
  clearance=maxf(0,hit.position.y-body.global_position.y)
  position=actor.to_local(hit.position)
 elif not actor.grounded:
  visible=false
 queue_redraw()
func _draw() -> void:
 var strength=lerpf(0.28,0.10,clampf(clearance/90,0,1))
 var span=lerpf(1.0,0.7,clampf(clearance/90,0,1))
 if actor.kind!="child": span*=0.8
 if ArtStyle.paper:
  # A55: a flat, soft-edged paper oval right under the feet.
  # P18: a soft contact shadow, darkest right under the feet, fading out.
  var w=(12.0 if actor.kind=="child" else 13.0)*span
  draw_set_transform(Vector2(0,0.5),0,Vector2(1,0.24))
  draw_texture_rect(soft(),Rect2(-w,-w,w*2,w*2),false,Color(1,1,1,minf(0.75,strength*2.0)))
  draw_set_transform(Vector2.ZERO)
  return
 draw_set_transform(Vector2.ZERO,0,Vector2(span,1))
 var ink=Color(0.20,0.22,0.15,strength)
 draw_rect(Rect2(-8,0,15,1.5),ink)
 draw_rect(Rect2(-5,-1,9,1),ink)
 draw_rect(Rect2(7,0.5,3,1),ink)
 draw_rect(Rect2(-11,0.5,2,1),ink*Color(1,1,1,0.65))
 draw_rect(Rect2(-6,1.5,4,1),ink*Color(1,1,1,0.5))
 draw_rect(Rect2(2,1.5,3,1),ink*Color(1,1,1,0.45))
 draw_rect(Rect2(11,1,1.5,1),ink*Color(1,1,1,0.4))
