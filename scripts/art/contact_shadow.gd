class_name ContactShadow
extends Node2D
## Sparse pixel clusters projected onto terrain, separate from the actor sprite.
var actor: GrayboxActor
var clearance=0.0
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
  var w=(9.0 if actor.kind=="child" else 14.0)*span
  draw_set_transform(Vector2(0,0.5),0,Vector2(1,0.2))
  draw_circle(Vector2.ZERO,w,Color(0.12,0.15,0.05,strength*1.3))
  draw_circle(Vector2.ZERO,w*0.7,Color(0.12,0.15,0.05,strength*0.8))
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
