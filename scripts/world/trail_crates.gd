class_name TrailCrates
extends Node2D
## Child-chosen positions; no authored placement slots. Legacy saves still load.
var game: GameState
var level_id=""
var bodies: Array[StaticBody2D]=[]
var signature=""
var placing=false
var candidate=Vector2.ZERO
var reason=""
var actors: Array[Node2D]=[]
func _ready() -> void:sync_layout()
func _physics_process(_delta: float) -> void:
 sync_layout()
 if placing:queue_redraw()
func sync_layout() -> void:
 var positions=game.crate_positions(level_id)
 var next_signature=str(positions)
 if signature==next_signature:return
 signature=next_signature
 for body in bodies:
  remove_child(body)
  body.queue_free()
 bodies.clear()
 for point in positions:
  var body=StaticBody2D.new()
  body.position=point
  body.collision_layer=1
  body.collision_mask=0
  var shape=CollisionShape2D.new()
  var rect=RectangleShape2D.new()
  rect.size=Vector2(24,24)
  shape.shape=rect
  body.add_child(shape)
  add_child(body)
  bodies.append(body)
 queue_redraw()
func choose_at(point: Vector2, child: Vector2) -> void:
 # Horizontal choice is continuous, not snapped to a hidden level grid.
 var x=point.x
 var solids: Array[Rect2]=TrailTools.layout_for(level_id).ground.duplicate()
 for p in game.crate_positions(level_id):solids.append(Rect2(p-Vector2(12,12),Vector2(24,24)))
 var distance=INF
 var found=false
 candidate=Vector2(x,point.y-12)
 for solid in solids:
  if x-12<solid.position.x or x+12>solid.end.x:continue
  if absf(solid.position.y-child.y)>95:continue
  var trial=game.crate_positions(level_id)
  trial.append(Vector2(x,solid.position.y-12))
  if not TrailTools.valid_positions(level_id,trial):continue
  var d=absf(solid.position.y-point.y)
  if d<distance:
   distance=d
   candidate=Vector2(x,solid.position.y-12)
   found=true
 reason="" if found else "Choose solid ground or the top of another crate."
 queue_redraw()
func can_place(child: Vector2) -> bool:
 if game.available_crates()<=0:
  reason="No free crates. Pack them to use them again."
  return false
 if candidate.distance_to(child)>125:
  reason="Move closer before placing the crate."
  return false
 var points=game.crate_positions(level_id)
 points.append(candidate)
 if not TrailTools.valid_positions(level_id,points):
  reason="The crate needs full support and space around it."
  return false
 var box=Rect2(candidate-Vector2(12,12),Vector2(24,24)).grow(1)
 for actor in actors:
  if is_instance_valid(actor) and box.intersects(Rect2(actor.position-Vector2(10,30),Vector2(20,30))):
   reason="Choose a place beside you and Foxy."
   return false
 if is_inside_tree():
  var query=PhysicsShapeQueryParameters2D.new()
  var shape=RectangleShape2D.new()
  shape.size=Vector2(23.8,23.8)
  query.shape=shape
  query.transform=Transform2D(0,candidate)
  query.collision_mask=1
  query.margin=0
  if not get_world_2d().direct_space_state.intersect_shape(query,1).is_empty():
   reason="Give the crate some space from platforms and walls."
   return false
 reason="Ready to place."
 return true
func confirm(child: Vector2) -> bool:
 if not can_place(child):
  game.feedback.emit(reason)
  return false
 var okay=game.place_trail_crate_at(level_id,candidate)
 if okay:sync_layout()
 return okay
func _draw() -> void:
 for body in bodies:draw_crate(body.position)
 if placing:
  var okay=can_place(actors[0].position) if not actors.is_empty() else false
  draw_crate(candidate,Color(1,1,1,.6))
  draw_rect(Rect2(candidate-Vector2(12,12),Vector2(24,24)),Color("8ee3b5") if okay else Color("f29b79"),false,1.3)
func draw_crate(point: Vector2, tint=Color.WHITE) -> void:
 if ArtStyle.enabled:
  var tex=ArtStyle.prop_texture("crate")
  draw_texture_rect(tex,Rect2(point-Vector2(12,12),Vector2(24,24)),false,tint)
 else:
  draw_rect(Rect2(point-Vector2(12,12),Vector2(24,24)),Color("b8874f")*tint)
  draw_rect(Rect2(point-Vector2(12,12),Vector2(24,24)),Color("634a32")*tint,false,1)
  draw_line(point-Vector2(9,9),point+Vector2(9,9),Color("ebce91")*tint,3)
