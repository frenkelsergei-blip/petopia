class_name TerrainSurface
extends Node2D
## One continuous material/edge system for every static ground shape.
## Authoring rectangles remain the physics source; shared edges disappear visually.
var ground: Array[Rect2]=[]
var contours: Array[PackedVector2Array]=[]
var top_edges: Array[Vector4]=[]
var grass: Texture2D
var rock: Texture2D
var surface_y=280.0
var grass_density=0.075
func _ready() -> void:
 z_index=1
 texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 rock=ArtTexture.load_texture("res://assets/art/meadow-system-v4/rock-material-v2.png")
 grass=ArtTexture.load_texture("res://assets/art/meadow-system-v4/grass-fringe.png")
 contours=union_rectangles(ground)
 var shader=Shader.new()
 shader.code="""shader_type canvas_item;
render_mode unshaded;
uniform sampler2D rock_tex : source_color, filter_linear;
varying vec2 world_point;
void vertex(){world_point=VERTEX;}
vec4 periodic(vec2 p){
 vec2 u=fract(p);
 // Feather only the seam margins. Preserve broad painted rock forms across
 // the rest of each period instead of blending four images over every pixel.
 vec2 edge=min(u,vec2(1.0)-u);
 vec2 w=0.5*(vec2(1.0)-smoothstep(vec2(0.0),vec2(0.065),edge));
 vec4 a=mix(texture(rock_tex,u),texture(rock_tex,vec2(1.0-u.x,u.y)),w.x);
 vec4 b=mix(texture(rock_tex,vec2(u.x,1.0-u.y)),texture(rock_tex,vec2(1.0)-u),w.x);
 return mix(a,b,w.y);
}
void fragment(){COLOR=periodic(world_point/180.0);}
"""
 var fill_material=ShaderMaterial.new()
 fill_material.shader=shader
 fill_material.set_shader_parameter("rock_tex",rock)
 for outline in contours:
  var shape=rounded(outline,9.0)
  shape=roughened(shape)
  var fill=Polygon2D.new()
  fill.name="ConnectedRockFace"
  fill.z_as_relative=false
  fill.z_index=0
  fill.polygon=shape
  fill.antialiased=true
  fill.material=fill_material
  add_child(fill)
  var border=Line2D.new()
  border.z_as_relative=false
  border.z_index=0
  border.points=shape
  border.closed=true
  border.width=0.9
  border.default_color=Color("58432d")
  border.antialiased=true
  add_child(border)
 for rect in ground:
  for edge in ArtStyle.exposed_segments(rect,ground):
   top_edges.append(Vector4(edge.x,rect.position.y,edge.y,rect.position.y))
 queue_redraw()
func _process(_delta: float) -> void: visible=ArtStyle.enabled
static func union_rectangles(rects: Array[Rect2]) -> Array[PackedVector2Array]:
 var polygons: Array[PackedVector2Array]=[]
 for rect in rects:
  if not rect.has_area(): continue
  var piece=PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
  var merged=true
  while merged:
   merged=false
   for index in range(polygons.size()):
    var combined=Geometry2D.merge_polygons(piece,polygons[index])
    if combined.size()==1:
     piece=combined[0]
     polygons.remove_at(index)
     merged=true
     break
  polygons.append(piece)
 return polygons
static func rounded(poly: PackedVector2Array, radius: float) -> PackedVector2Array:
 var result=PackedVector2Array()
 for i in range(poly.size()):
  var previous=poly[(i+poly.size()-1)%poly.size()]
  var point=poly[i]
  var next=poly[(i+1)%poly.size()]
  var r=minf(radius,minf(point.distance_to(previous),point.distance_to(next))*0.49)
  var a=point+(previous-point).normalized()*r
  var b=point+(next-point).normalized()*r
  for j in range(5):
   var t=j/4.0
   result.append(a.lerp(point,t).lerp(point.lerp(b,t),t))
 return result
static func roughened(poly: PackedVector2Array) -> PackedVector2Array:
 var result=PackedVector2Array()
 for i in range(poly.size()):
  var a=poly[i]
  var b=poly[(i+1)%poly.size()]
  result.append(a)
  if absf(a.x-b.x)<0.01 and absf(a.y-b.y)>9:
   var sections=int(ceil(absf(a.y-b.y)/7.0))
   for n in range(1,sections):
    var point=a.lerp(b,float(n)/sections)
    var envelope=sin(PI*float(n)/sections)
    point.x+=signf(b.y-a.y)*(2.0+1.4*sin(point.y*0.32+point.x*0.07))*envelope
    result.append(point)
 return result
func _draw() -> void:
 if grass==null: return
 var period=grass.get_width()*grass_density
 var height=grass.get_height()*grass_density
 for edge in top_edges:
  var start=edge.x-3
  var finish=edge.z+3
  var top=edge.y-surface_y*grass_density
  for tile in range(int(floor(start/period)),int(ceil(finish/period))):
   var x=maxf(start,tile*period)
   var end=minf(finish,(tile+1)*period)
   var phase=x-tile*period
   var width=end-x
   if width<0.01: continue
   # Sample in world coordinates so splitting/merging surfaces never resets phase.
   # Ends feather into the rounded contour rather than cutting a grass rectangle.
   var left_alpha=clampf((x-start)/3.0,0,1)
   var right_alpha=clampf((finish-x-width)/3.0,0,1)
   if width>6:
    draw_grass_quad(Rect2(x,top,3,height),Rect2(phase/period,0,3/period,1),left_alpha,1)
    draw_grass_quad(Rect2(x+3,top,width-6,height),Rect2((phase+3)/period,0,(width-6)/period,1),1,1)
    draw_grass_quad(Rect2(x+width-3,top,3,height),Rect2((phase+width-3)/period,0,3/period,1),1,right_alpha)
   else: draw_grass_quad(Rect2(x,top,width,height),Rect2(phase/period,0,width/period,1),left_alpha,right_alpha)
func draw_grass_quad(rect: Rect2, uv: Rect2, left_alpha: float, right_alpha: float) -> void:
 var points=PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
 var uvs=PackedVector2Array([uv.position,Vector2(uv.end.x,uv.position.y),uv.end,Vector2(uv.position.x,uv.end.y)])
 draw_polygon(points,PackedColorArray([Color(1,1,1,left_alpha),Color(1,1,1,right_alpha),Color(1,1,1,right_alpha),Color(1,1,1,left_alpha)]),uvs,grass)
