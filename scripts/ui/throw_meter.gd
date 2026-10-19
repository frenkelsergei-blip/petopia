class_name ThrowMeter
extends Control
## Aim bar (A49 kit): carved track, gold target band with soft edges, and the
## sun ball sliding along it as the marker. Shared by landscape and portrait.
const HEIGHT=40.0
var activity: BallGame
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.y=HEIGHT
func _process(_delta: float) -> void: queue_redraw()
## A57 (P52): the curved torn-paper power meter with its cream marker.
var paper32=false
func _draw() -> void:
	if paper32:
		draw_p52()
		return
	var ball=CareArt.icon("ball")
	var r=size.y*0.5
	var track=Rect2(r*0.6,size.y*0.22,maxf(1,size.x-r*1.2),size.y*0.56)
	draw_style_box(PetUI.kit_style("meter_track",track.size.y*0.5),track)
	# Gold band where Foxy can catch (same range the game checks).
	# The band follows Foxy (it wanders) and the child (walking changes reach).
	var b=activity.band() if is_instance_valid(activity) else Vector2(0.4,0.6)
	var left=clampf(b.x,0.0,1.0)
	var right=clampf(b.y,0.0,1.0)
	var inner=track.grow(-track.size.y*0.18)
	var zone=Rect2(inner.position.x+inner.size.x*left,inner.position.y,maxf(2.0,inner.size.x*(right-left)),inner.size.y)
	draw_style_box(PetUI.kit_style("meter_fill",zone.size.y*0.5,PetUI.GOLD),zone)
	var ready=is_instance_valid(activity) and not activity.in_flight and not activity.waiting and not activity.done
	var fraction=activity.aim_fraction() if is_instance_valid(activity) else 0.0
	var inside=fraction>=left and fraction<=right
	# Small stars mark the band edges so the target reads without colour.
	for x in [zone.position.x,zone.end.x]:
		draw_colored_polygon(PackedVector2Array([Vector2(x,track.position.y-5),Vector2(x+5,track.position.y-12),Vector2(x-5,track.position.y-12)]),Color("8a4b1c"))
	var center=Vector2(inner.position.x+inner.size.x*fraction,size.y*0.5)
	var d=size.y*(1.0 if ready and inside else 0.86)
	if ready and inside: draw_circle(center,d*0.62,Color(1,0.93,0.5,0.55))
	draw_texture_rect(ball,Rect2(center-Vector2(d,d)*0.5,Vector2(d,d)),false,Color(1,1,1,1.0 if ready else 0.55))

## The track's own shape: top and bottom of the paper at each column
## (measured once from meter.png), so the marker rides the real edge.
static var _edges: Array=[]
static func edges() -> Array:
	if _edges.is_empty():
		var img: Image=ConceptScreen.tex("ball-p32","meter").get_image()
		if img.is_compressed(): img.decompress()
		var w=img.get_width()
		var h=img.get_height()
		for i in 64:
			var x=int((i+0.5)/64.0*w)
			var top=-1
			var bot=-1
			for y in h:
				if img.get_pixel(x,y).a>0.5:
					if top<0: top=y
					bot=y
			_edges.append(Vector2(float(top)/h,float(bot)/h))
	return _edges
func edge_at(f: float) -> Vector2:
	var e=edges()
	var i=clampf(f,0.0,1.0)*(e.size()-1)
	var a: Vector2=e[int(floor(i))]
	var b: Vector2=e[mini(int(floor(i))+1,e.size()-1)]
	return a.lerp(b,i-floor(i))
func draw_p52() -> void:
	var track: Texture2D=ConceptScreen.tex("ball-p32","meter")
	var marker: Texture2D=ConceptScreen.tex("ball-p32","marker")
	var h=size.x*track.get_height()/track.get_width()
	var top=size.y-h
	var r=Rect2(0,top,size.x,h)
	draw_texture_rect(track,r,false)
	var b=activity.band() if is_instance_valid(activity) else Vector2(0.4,0.6)
	var ready=is_instance_valid(activity) and not activity.in_flight and not activity.waiting and not activity.done
	var fraction=activity.aim_fraction() if is_instance_valid(activity) else 0.0
	var inside=fraction>=b.x and fraction<=b.y
	# Usable span of the track (its rounded ends excluded).
	var lo=0.07
	var hi=0.93
	var fx=func(f: float) -> float: return lerpf(lo,hi,clampf(f,0.0,1.0))
	# Catch zone: the same paper, lit warm gold, clipped to the track's shape.
	var x0: float=fx.call(b.x)
	var x1: float=fx.call(b.y)
	var tw=track.get_width()
	var pulse=0.0 if (is_instance_valid(activity) and activity.child.reduced_motion) else sin(Time.get_ticks_msec()/250.0)*0.08
	# Catch zone: the bar's own paper, lit warm gold, with soft feathered
	# ends (no hard lines), and a gentle glow along it.
	var steps=10
	for i in steps:
		var f0=lerpf(x0,x1,float(i)/steps)
		var f1=lerpf(x0,x1,float(i+1)/steps)
		var edge=minf(float(i)+0.5,float(steps)-float(i)-0.5)/(steps*0.5)
		var lift=0.55+0.45*clampf(edge*2.0,0.0,1.0)+pulse
		draw_texture_rect_region(track,Rect2(r.position.x+r.size.x*f0,top,r.size.x*(f1-f0)+0.5,h),Rect2(tw*f0,0,tw*(f1-f0),track.get_height()),Color(1.0+0.35*lift,1.0+0.3*lift,1.0-0.05*lift,1.0))
	# One cream arrow standing on the paper's top edge, pointing down.
	var f2: float=fx.call(fraction)
	var e=edge_at(f2)
	# The arrow overlaps the bar's top edge and points into it (P52).
	var mw=h*0.36
	var mh=mw*marker.get_height()/marker.get_width()
	var tip=Vector2(r.size.x*f2,top+h*(e.x+e.y)*0.5)
	if ready and inside: draw_circle(tip+Vector2(0,-mh*0.45),mw*0.75,Color(1,0.92,0.45,0.45))
	draw_texture_rect(marker,Rect2(tip-Vector2(mw*0.5,mh),Vector2(mw,mh)),false,Color(1,1,1,1.0 if ready else 0.55))
