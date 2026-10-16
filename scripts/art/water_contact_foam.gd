class_name WaterContactFoam
extends RefCounted
## Small water-surface wakes at pile contact, in world space. Not an object glow.
static func ribbon(center: Vector2, span: float, depth: float, start: float, finish: float, phase: float) -> PackedVector2Array:
 var points=PackedVector2Array()
 for i in range(13):
  var angle=lerpf(start,finish,i/12.0)
  var p=center+Vector2(cos(angle)*span,sin(angle)*depth)
  p.y+=sin(angle*7+phase)*.25
  points.append((p*2).round()*.5)
 return points
static func draw_back(canvas: CanvasItem, center: Vector2, half_width: float, elapsed: float, seed: float) -> void:
 var phase=elapsed*2.6+seed
 var bow=ribbon(center,half_width+2.5,1.6,PI+.12,TAU-.12,phase)
 canvas.draw_polyline(bow,Color(.39,.88,.98,.82),1.7)
 for arc in [Vector2(PI+.13,PI+1.05),Vector2(PI+1.4,TAU-.14)]:
  canvas.draw_polyline(ribbon(center,half_width+2.2,1.5,arc.x,arc.y,phase),Color(.94,1,1,.93),.9)
static func draw_front(canvas: CanvasItem, center: Vector2, half_width: float, elapsed: float, seed: float) -> void:
 var phase=elapsed*2.6+seed
 # Cyan undercurl and three broken white crests wrap the foot on the surface.
 canvas.draw_polyline(ribbon(center,half_width+2.8,2.4,.04,PI-.04,phase),Color(.35,.86,.98,.85),2)
 for arc in [Vector2(.04,.82),Vector2(1.0,1.94),Vector2(2.12,PI-.04)]:
  canvas.draw_polyline(ribbon(center,half_width+2.7,2.2,arc.x,arc.y,phase),Color(.97,1,1,.98),1.1)
 # Short fragments flow away and dissolve. Each pile has its own phase.
 for i in range(2):
  var age=fposmod(elapsed*.7+seed*.19+i*.5,1.0)
  var wake=center+Vector2(sin(seed+i)*1.3,1.4+age*3.5)
  var start=.18+i*.37
  var finish=PI-.25-i*.5
  canvas.draw_polyline(ribbon(wake,half_width+3+age*3,1.3,start,finish,phase),Color(.89,.99,1,(1-age)*.63),.8)
 # A few small edge splashes rise where current strikes the timber sides.
 for side in [-1.0,1.0]:
  var age=fposmod(elapsed*.95+seed*.31+(0.45 if side<0 else 0.0),1.0)
  var point=center+Vector2(side*(half_width+1.2+age*3),-.5-sin(age*PI)*2+age*1.5)
  point=(point*2).round()*.5
  canvas.draw_rect(Rect2(point,Vector2(1.0 if age>.4 else 1.5,.7)),Color(.96,1,1,(1-age)*.9))
