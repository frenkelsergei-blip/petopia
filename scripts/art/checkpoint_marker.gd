class_name CheckpointMarker
extends Node2D
var active=false
var activation_time=0.0
var nearby=false
var reduced_motion=false
func activate() -> void:
 if active:return
 active=true
 activation_time=1.25
func _process(delta: float) -> void:
 activation_time=maxf(0,activation_time-delta)
 visible=ArtStyle.enabled
 queue_redraw()
func _draw() -> void:
 var tex=ArtStyle.prop_texture("checkpoint") as AtlasTexture
 if tex==null:return
 var size_value=Vector2(25,40)
 var factor=size_value/tex.region.size
 var origin=-Vector2(size_value.x*.5,size_value.y)
 # Keep the pole fixed; flutter just the cloth on checkpoint arrival.
 var strength=sin(activation_time*PI/1.25)*1.2 if not reduced_motion else 0.0
 var cut=tex.region.size.x*.29
 draw_texture_rect_region(tex.atlas,Rect2(origin,Vector2(cut*factor.x,40)),Rect2(tex.region.position,Vector2(cut,tex.region.size.y)))
 for row in range(0,int(tex.region.size.y),4):
  var h=minf(4,tex.region.size.y-row)
  var shift=sin(row*.07+activation_time*17)*strength
  var destination=Rect2(origin+Vector2(cut*factor.x+shift,row*factor.y),Vector2((tex.region.size.x-cut)*factor.x,h*factor.y))
  draw_texture_rect_region(tex.atlas,destination,Rect2(tex.region.position+Vector2(cut,row),Vector2(tex.region.size.x-cut,h)))
 if active:
  draw_line(Vector2(-9,-44),Vector2(-7,-42),Color("fff2a1"),1.3)
  draw_line(Vector2(-7,-42),Vector2(-3,-47),Color("fff2a1"),1.3)
 if activation_time>0 and not reduced_motion:
  var progress=1.0-activation_time/1.25
  for i in range(7):
   var angle=TAU*i/7.0
   var point=Vector2(1,-24)+Vector2(cos(angle)*18,sin(angle)*27)*(0.5+progress)
   var c=Color(1,.91,.48,1-progress)
   draw_line(point-Vector2(2,0),point+Vector2(2,0),c,1)
   draw_line(point-Vector2(0,2),point+Vector2(0,2),c,1)
