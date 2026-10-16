class_name MeadowCrossingKit
extends RefCounted
## A bounded, reusable art test at the lab river. All collision remains in the lab.
static var _bridge: Texture2D
static var _river: Texture2D
static var _crank: Texture2D
static var _tree: Texture2D
static func prepare() -> void:
 if _bridge!=null: return
 _bridge=load("res://assets/art/meadow-kit-v3/timber-crossing.png")
 _river=load("res://assets/art/meadow-kit-v3/river-cascade.png")
 _crank=load("res://assets/art/meadow-system-v4/crank-parts.png")
 _tree=load("res://assets/art/meadow-kit-v3/meadow-tree.png")
static func river_bounds(stream: Rect2) -> Rect2:
 return Rect2(stream.position.x-72,stream.position.y-46,stream.size.x+144,159)
static func draw_river(canvas: CanvasItem, stream: Rect2) -> void:
 prepare()
 # Preserve the original river, rocks and waterfall composition.
 canvas.draw_texture_rect(_river,river_bounds(stream),false)
static func bridge_piles(stream: Rect2) -> Array[Rect2]:
 var scale_value=(stream.size.x+20)/2060.0
 var origin=Vector2(stream.position.x-10-30*scale_value,288-300*scale_value)
 var result: Array[Rect2]=[]
 for i in range(3):
  var source_x=[389.0,988.0,1581.0][i]
  # The downstream beam/pile moves sideways into open current, clear of rock.
  # The final pile stands beside the waterfall: its foot must reach the
  # lower pool, rather than stopping at the upstream surface mid-fall.
  var waterline=stream.position.y+(64.0 if i==2 else 32.0)
  var offset=14.0 if i==2 else 0.0
  result.append(Rect2(origin.x+source_x*scale_value+offset,origin.y+430*scale_value,145*scale_value,waterline+10-(origin.y+430*scale_value)))
 return result
static func draw_bridge(canvas: CanvasItem, stream: Rect2, elapsed=0.0, progress=1.0) -> void:
 prepare()
 var scale_value=(stream.size.x+20)/2060.0
 var origin=Vector2(stream.position.x-10-30*scale_value,288-300*scale_value)
 var revealed=_bridge.get_width()*progress
 var piles=bridge_piles(stream)
 for i in range(piles.size()):
  var source_x=[389.0,988.0,1581.0][i]
  if source_x+145>revealed:continue
  var post=piles[i]
  var waterline=post.end.y-10
  var contact=Vector2(post.get_center().x,waterline)
  WaterContactFoam.draw_back(canvas,contact,post.size.x*.5,elapsed,i*1.37)
  canvas.draw_texture_rect_region(_bridge,post,Rect2(source_x,440,145,100))
  var bounds=river_bounds(stream)
  # Actual river samples pass in front of the submerged foot, with a broken edge.
  var polygon=PackedVector2Array()
  var left=post.position.x-1
  var right=post.end.x+1
  for j in range(9):
   polygon.append(Vector2(lerpf(left,right,j/8.0),waterline+sin(j*1.7+i)*.7))
  polygon.append(Vector2(right,waterline+12))
  polygon.append(Vector2(left,waterline+12))
  var uv=PackedVector2Array()
  for point in polygon:uv.append((point-bounds.position)/bounds.size)
  canvas.draw_polygon(polygon,PackedColorArray([Color.WHITE]),uv,_river)
  WaterContactFoam.draw_front(canvas,contact,post.size.x*.5,elapsed,i*1.37)
 # The top deck stays exactly on the collision plane. Crossbeams and piles
 # are separate structural pieces, so the final pile can avoid a river rock.
 canvas.draw_texture_rect_region(_bridge,Rect2(origin,Vector2(revealed,360)*scale_value),Rect2(0,0,revealed,360))
 for i in range(3):
  var source_x=[345.0,950.0,1500.0][i]
  if source_x+245>revealed:continue
  var offset=14.0 if i==2 else 0.0
  canvas.draw_texture_rect_region(_bridge,Rect2(origin+Vector2(source_x*scale_value+offset,360*scale_value),Vector2(245,70)*scale_value),Rect2(source_x,360,245,70))
static func draw_framing(canvas: CanvasItem, ground: Array[Rect2], stream: Rect2, reserved: Array[Vector2]=[]) -> void:
 prepare()
 for x in [stream.position.x-82,stream.end.x+105]:
  if not ArtStyle.scenery_clear(x,120,reserved):continue
  var y=ArtStyle.root_support(ground,x,120)
  if y!=INF: canvas.draw_texture_rect_region(_tree,Rect2(x-60,y-144,120,151),Rect2(11,44,1069,1361))
static func draw_foreground(_canvas: CanvasItem, _stream: Rect2) -> void:
 # The river and cliff assets already supply fine foreground leaves/rocks.
 # Do not magnify the rejected low-detail shrub sprite over those layers.
 pass

static func draw_crank(canvas: CanvasItem, feet: Vector2, angle: float, padded=false, wheel_only=false) -> void:
 prepare()
 var density=0.066
 # Both authored pieces share the axle (473,372) on the support and
 # (1282,500) on the wheel. The support base stays planted at feet.
 var margin=20 if padded else 0
 if not wheel_only:
  canvas.draw_texture_rect_region(_crank,Rect2(feet+Vector2(157-margin-473,80-margin-800)*density,Vector2(624+margin*2,730+margin*2)*density),Rect2(157-margin,80-margin,624+margin*2,730+margin*2))
 canvas.draw_set_transform(feet+Vector2(0,372-800)*density,angle,Vector2.ONE*density)
 canvas.draw_texture_rect_region(_crank,Rect2(Vector2(1035-margin-1282,240-margin-500),Vector2(625+margin*2,510+margin*2)),Rect2(1035-margin,240-margin,625+margin*2,510+margin*2))
 canvas.draw_set_transform(Vector2.ZERO)

static func draw_return_gate(canvas: CanvasItem, feet: Vector2) -> void:
 prepare()
 for side in [-1.0,1.0]:
  canvas.draw_texture_rect_region(_bridge,Rect2(feet+Vector2(side*18-3,-43),Vector2(6,43)),Rect2(389,440,145,100))
 canvas.draw_texture_rect_region(_bridge,Rect2(feet+Vector2(-25,-47),Vector2(50,9)),Rect2(345,360,245,70))
 var arrow=PackedVector2Array([Vector2(-9,-31),Vector2(0,-37),Vector2(0,-33),Vector2(12,-33),Vector2(12,-29),Vector2(0,-29),Vector2(0,-25)])
 for i in range(arrow.size()):arrow[i]+=feet
 canvas.draw_colored_polygon(arrow,Color("fff1ba"))
