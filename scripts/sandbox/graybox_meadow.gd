class_name GrayboxMeadow
extends Meadow

var definition: LevelDefinition
var show_labels = true
var selected_target = ""
var lab = false
var player_point=Vector2.INF
var course_finished=false
var contextual_point=Vector2.ZERO
var companion_point = Vector2.INF
var marker: CheckpointMarker
var checkpoint_active=false
var cache_open=false
var cache_reward_available=true
var picnic_delivered=false
var focus: InteractionFocus
var terrain: TerrainSurface
var bridge_progress=0.0
var crank_turn=0.0
var crank_angle=0.0
var render_camera_x=0.0

func _ready() -> void:
	super._ready()
	ArtStyle.prepare()
	terrain=TerrainSurface.new()
	terrain.ground=ground
	add_child(terrain)
	marker=CheckpointMarker.new()
	if definition!=null: marker.position=definition.checkpoint+Vector2(28,0)
	marker.active=checkpoint_active
	marker.reduced_motion=reduced_motion
	add_child(marker)
	focus=InteractionFocus.new()
	focus.meadow=self
	add_child(focus)

func _process(delta: float) -> void:
	super._process(delta)
	crank_angle=move_toward(crank_angle,crank_turn,delta*TAU*2.5)
	bridge_progress=move_toward(bridge_progress,1.0 if bridge else 0.0,delta*2.5)
	if marker!=null and definition!=null: marker.nearby=player_point.distance_to(marker.position)<90
	material=null
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR if ArtStyle.enabled else CanvasItem.TEXTURE_FILTER_NEAREST

func text_at(text: String, xy: Vector2, color: Color = Color("435361"), font_size: int = 9) -> void:
	draw_string(ThemeDB.fallback_font,xy,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func _draw() -> void:
	if ArtStyle.enabled:
		# Camera2D publishes its interpolated canvas transform on the render clock.
		# Painting parallax from the physics camera position made it jump at60Hz.
		render_camera_x=get_viewport().canvas_transform.affine_inverse().origin.x
		var reserved: Array[Vector2]=[]
		if definition!=null: reserved=[definition.crank,definition.checkpoint,definition.discovery,definition.basket,definition.arrival,definition.return_gate]
		ArtStyle.draw_scenery(self,render_camera_x,ground,reserved)
		if lab: MeadowCrossingKit.draw_framing(self,ground,definition.stream,reserved)
	else:
		draw_rect(Rect2(camera_x-16,0,672,360),Color("d2dce2"))
		# Two quiet parallax layers; geometry stays visually dominant.
		for i in range(-1,8):
			var x = camera_x + fposmod(i*150.0-camera_x*0.16,1000)-150
			draw_polygon(PackedVector2Array([Vector2(x,245),Vector2(x+105,145+i%3*12),Vector2(x+230,245)]),PackedColorArray([Color("c3cfd6")]))
		for i in range(-1,10):
			var x = camera_x + fposmod(i*110.0-camera_x*0.32,950)-110
			draw_circle(Vector2(x+60,253),48,Color("b5c3cd"))
		for x in range(int(camera_x/16)*16,int(camera_x)+656,16):
			draw_line(Vector2(x,192),Vector2(x,360),Color(0.38,0.46,0.52,0.06))
		for y in range(192,361,16): draw_line(Vector2(camera_x,y),Vector2(camera_x+640,y),Color(0.38,0.46,0.52,0.06))
	if definition == null: return
	if ArtStyle.enabled:
		MeadowCrossingKit.draw_river(self,definition.stream)
	else:
		draw_rect(definition.stream,Color("91aeba"))
		for r in ground:
			draw_rect(r,Color("7e8b96"))
			draw_line(r.position,Vector2(r.end.x,r.position.y),Color("e5eced"),2)

	if lab and not ArtStyle.enabled:
		draw_rect(Rect2(660,288,56,100),Color("a6bcc5"))
		text_at("56 px gap",Vector2(661,330))
	if bridge or (ArtStyle.enabled and bridge_progress>0):
		if ArtStyle.enabled:
			MeadowCrossingKit.draw_bridge(self,definition.stream,elapsed,bridge_progress)
		else:
			for x in range(int(definition.stream.position.x),int(definition.stream.end.x),12):
				draw_rect(Rect2(x,288,11,8),Color("74a5a3"))
				draw_line(Vector2(x,288),Vector2(x+11,288),Color("c6e5df"),1)
	for i in range(definition.coin_positions.size()):
		if i in pickups: continue
		var p = definition.coin_positions[i] + Vector2(0,sin(elapsed*2+i)*1.5)
		if coin_texture != null: draw_texture_rect(coin_texture,Rect2(p-Vector2.ONE*(ArtStyle.COIN_SIZE/2 if ArtStyle.enabled else 7),Vector2.ONE*(ArtStyle.COIN_SIZE if ArtStyle.enabled else 14)),false)
	var c=definition.crank
	var cp=definition.checkpoint
	var d=definition.discovery
	if ArtStyle.enabled:
		MeadowCrossingKit.draw_crank(self,c,crank_angle)
		if secret: ArtStyle.draw_chest(self,d,cache_open,cache_reward_available)
		if lab: ArtStyle.draw_picnic(self,definition.basket,true)
		elif definition.level_id=="W01_L01":
			ArtStyle.draw_picnic(self,definition.arrival+Vector2(32,0),picnic_delivered)
			MeadowCrossingKit.draw_return_gate(self,definition.return_gate)
		if not basket and not lab: ArtStyle.draw_prop(self,"basket",definition.basket,Vector2(28,29))
	else:
		draw_rect(Rect2(c-Vector2(3,25),Vector2(6,25)),Color("547c83"))
		draw_arc(c-Vector2(0,24),9,0,TAU,16,Color("406875"),2)
		draw_line(c-Vector2(0,24),c+Vector2(8,-30),Color("f1d188"),3)
		draw_line(cp,cp-Vector2(0,38),Color("4d786b"),2)
		draw_rect(Rect2(cp-Vector2(0,38),Vector2(18,12)),Color("86b7a5"))
		draw_rect(Rect2(d-Vector2(17,5),Vector2(34,5)),Color("bca77b"))
		if secret:
			draw_rect(Rect2(d-Vector2(12,21),Vector2(24,17)),Color("b38d58"))
			draw_rect(Rect2(d-Vector2(2,17),Vector2(4,7)),Color("f1d188"))
		else:
			draw_arc(d-Vector2(0,12),9+sin(elapsed*3)*2,PI,TAU,12,Color("cfaa63"),1)
		if lab: ArtStyle.draw_picnic(self,definition.basket,true)
		elif definition.level_id=="W01_L01":
			ArtStyle.draw_picnic(self,definition.arrival+Vector2(32,0),picnic_delivered)
			MeadowCrossingKit.draw_return_gate(self,definition.return_gate)
		if not basket and not lab:
			var b=definition.basket
			draw_rect(Rect2(b-Vector2(12,18),Vector2(24,18)),Color("ae9270"))
			draw_arc(b-Vector2(0,18),8,PI,TAU,12,Color("695949"),2)
		if definition.level_id!="W01_L02": draw_rect(Rect2(definition.return_gate-Vector2(13,38),Vector2(26,38)),Color(0.45,0.55,0.55,0.3),false,2)
	if show_labels and not ArtStyle.enabled:
		text_at("CRANK [E]",c-Vector2(24,45))
		text_at("CHECKPOINT",cp+Vector2(-25,18))
		text_at("BURIED TREASURE [Q]" if not secret else "CACHE FOUND",d-Vector2(48,39))
		text_at("FINISH [E]" if lab else ("DELIVERY [E]" if definition.level_id=="W01_L02" else "BASKET [E]"),definition.basket-Vector2(30,45))
		if not lab:
			text_at("ARRIVAL" if definition.level_id=="W01_L02" else "PICNIC [E]",definition.arrival-Vector2(25,45))
			if definition.level_id!="W01_L02": text_at("RETURN GATE [E]",definition.return_gate+Vector2(-44,18))
		else:
			text_at("01  MOVE & JUMP",Vector2(130,218))
			text_at("02  GAP",Vector2(610,218))
			text_at("03  STEPS",Vector2(1260,218))
	if not selected_target.is_empty() and not ArtStyle.enabled:
		var pos = definition.crank
		match selected_target:
			"discovery": pos=definition.discovery
			"basket": pos=definition.basket
			"gate": pos=definition.return_gate
			"picnic": pos=definition.arrival
		draw_arc(pos-Vector2(0,14),26,0,TAU,32,Color("e8c57b"),1)
		if selected_target=="discovery" and companion_point!=Vector2.INF:
			var from=companion_point-Vector2(0,27)
			var to=definition.discovery-Vector2(0,8)
			for i in range(1,10): draw_circle(from.lerp(to,i/10.0),1.5,Color("bb8c3e"))
			text_at("!",from-Vector2(2,6),Color("9c6d22"),15)


