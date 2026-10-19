class_name BallInterface
extends Control
## Catch the Ball: a full-screen landscape garden like the adventure. In
## portrait it shows the shared turn-your-phone card and the game waits.
var app: Control
var signature=""
var content: Control
var feedback: Label
var score: Label
var meter: ThrowMeter
var turn_panel: Panel
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func layout(dimensions: Vector2, safe: Rect2) -> void:
	if signature==str([dimensions,safe]): return
	signature=str([dimensions,safe])
	if is_instance_valid(content):
		remove_child(content)
		content.queue_free()
	content=Control.new()
	content.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(content)
	turn_panel=null
	# The garden fills the whole screen. Wider than 16:9 shows the full
	# garden width and trims sky; narrower shows a slice the camera follows.
	app.viewport.get_parent().stretch=false
	var aspect=dimensions.x/maxf(1,dimensions.y)
	var world=Vector2(640,roundf(640/aspect)) if aspect>=640.0/360.0 else Vector2(roundf(360*aspect),360)
	WorldRender.configure(app.viewport,Vector2i(world))
	if is_instance_valid(app.active_ball): app.active_ball.view_height=world.y
	var image=TextureRect.new()
	image.name="GardenStage"
	image.texture=app.viewport.get_texture()
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.size=dimensions
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	content.add_child(image)
	if dimensions.x<dimensions.y:
		turn_panel=AdventureInterface.turn_card(content,app,dimensions,safe,app.game.state.settings.reduced_motion,"Catch the Ball is played sideways. Turn the phone to play.")
		return
	if ArtStyle.paper and ResourceLoader.exists("res://assets/ui/ball-p32/meter.png"):
		p52_layout(dimensions,safe)
		return
	var bar=46.0 if dimensions.y<450 else 56.0
	var back=CareArt.button(content,"My Pet",Rect2(safe.position.x,safe.position.y,150,bar),app.show_home,"paw")
	back.name="MyPetButton"
	CareArt.square(content,"gear",Rect2(safe.end.x-bar,safe.position.y,bar,bar),app.toggle_pause)
	# Score plank, centred at the top over the sky.
	var plank=CareArt.frame(content,Rect2(safe.get_center().x-160,safe.position.y,320,bar))
	plank.name="ScorePlank"
	PetUI.set_piece(plank,"hud_plank")
	PetUI.compose(plank,"Catch the Ball",CareArt.icon("ball"),"left",18 if bar<50 else 20)
	score=plank.get_node("Content/Caption")
	# Aim bar under it: the sun ball slides along; throw in the gold band.
	var meter_w=minf(460,safe.size.x*0.5)
	meter=ThrowMeter.new()
	meter.name="ThrowMeter"
	meter.activity=app.active_ball
	meter.position=Vector2(safe.get_center().x-meter_w/2,safe.position.y+bar+8)
	meter.size=Vector2(meter_w,ThrowMeter.HEIGHT)
	content.add_child(meter)
	# Short hint under the bar, sized to its words.
	feedback=Label.new()
	feedback.name="Feedback"
	feedback.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	feedback.add_theme_font_override("font",load(PetUI.MENU_FONT_PATH))
	feedback.add_theme_font_size_override("font_size",PetUI.F_TAG if bar<50 else 19)
	feedback.add_theme_color_override("font_color",Color.WHITE)
	feedback.add_theme_color_override("font_outline_color",Color("3b2412"))
	feedback.add_theme_constant_override("outline_size",6)
	feedback.position=Vector2(safe.position.x,meter.position.y+ThrowMeter.HEIGHT+4)
	feedback.size=Vector2(safe.size.x,30)
	feedback.mouse_filter=Control.MOUSE_FILTER_IGNORE
	content.add_child(feedback)
	# Big round Throw button at the bottom right, where the thumb rests.
	var size=clampf(dimensions.y*0.26,88,128)
	var throw=Button.new()
	throw.name="ThrowButton"
	throw.tooltip_text="Throw"
	throw.position=Vector2(safe.end.x-size,safe.end.y-size)
	throw.size=Vector2(size,size)
	PetUI.set_piece(throw,"action","action_pressed")
	throw.pressed.connect(func(): app.active_ball.throw_ball())
	content.add_child(throw)
	PetUI.compose(throw,"Throw",CareArt.icon("ball"),"round_label",PetUI.F_TAG)
	app.throw_button=throw

## A57 (P52): Catch the Ball from concept P52 (ball-p32 kit at the concept's
## coordinates): back, title, coins, catches card with ten paws, the curved
## power meter, the hint strip and the big gold Throw button.
var p52=false
var paws: Array[TextureRect]=[]
func p52_layout(dimensions: Vector2, safe: Rect2) -> void:
	p52=true
	paws.clear()
	var k=minf(dimensions.x/1672.0,dimensions.y/941.0)
	var R=func(x: float,y: float,w: float,h: float) -> Rect2:
		# Edge anchoring: left items to the left edge, right items to the right.
		var px=safe.position.x+x*k if x<600 else (safe.end.x-(1672-x)*k if x>1100 else dimensions.x*0.5+(x-836)*k)
		var py=safe.position.y+y*k if y<470 else safe.end.y-(941-y)*k
		return Rect2(px,py,w*k,h*k)
	var back=ConceptScreen.button(content,"MyPetButton","ball-p32","back",R.call(40,28,116,116),app.show_home)
	back.tooltip_text="My Pet"
	# Title, catches card and hint strip share the screen's centre line.
	var mid=dimensions.x*0.5
	var C=func(w: float,y: float,h: float) -> Rect2:
		var py=safe.position.y+y*k if y<470 else safe.end.y-(941-y)*k
		return Rect2(mid-w*k*0.5,py,w*k,h*k)
	var tr: Rect2=C.call(560,28,140)
	ConceptScreen.piece(content,"ball-p32","title",tr,false)
	# Words centred on the plaque's cream body (measured: 9%-91% x, 12%-80% y).
	ConceptScreen.words(content,"Catch the Ball",Rect2(tr.position.x+tr.size.x*0.12,tr.position.y+tr.size.y*0.12,tr.size.x*0.78,tr.size.y*0.68),int(76*k))
	# Coins, then Settings at the far right (as in the adventure HUD).
	var bh=92.0*k
	var gear=ConceptScreen.button(content,"Settings","hud-p32","btn_gear",Rect2(safe.end.x-bh,safe.position.y+30*k,bh,bh),app.toggle_pause)
	gear.tooltip_text="Settings"
	var cr=Rect2(gear.position.x-215*k-12*k,safe.position.y+30*k,215*k,bh)
	ConceptScreen.coin_pill(content,"ball-p32",cr,str(app.game.state.coins),int(46*k),PetUI.INK,0.44)
	var sr: Rect2=C.call(390,180,95)
	ConceptScreen.piece(content,"ball-p32","score",sr,false)
	score=ConceptScreen.words(content,"",Rect2(sr.position.x,sr.position.y+sr.size.y*0.06,sr.size.x,sr.size.y*0.46),int(34*k))
	score.name="Score"
	var pw=sr.size.x*0.082
	for i in 10:
		var paw=ConceptScreen.piece(content,"ball-p32","paw_off",Rect2(sr.position.x+sr.size.x*0.06+i*pw*1.07,sr.position.y+sr.size.y*0.54,pw,pw))
		paws.append(paw)
	meter=ThrowMeter.new()
	meter.name="ThrowMeter"
	meter.paper32=true
	meter.activity=app.active_ball
	var mr: Rect2=R.call(40,790,430,120)
	meter.position=mr.position
	meter.size=mr.size
	content.add_child(meter)
	var hr: Rect2=C.call(560,836,78)
	ConceptScreen.piece(content,"ball-p32","hint",hr,false)
	feedback=ConceptScreen.words(content,"",hr.grow_individual(-hr.size.x*0.12,0,-hr.size.x*0.12,0),int(30*k))
	feedback.clip_text=true
	feedback.name="Feedback"
	var size=maxf(110.0,250*k)
	var throw=ConceptScreen.button(content,"ThrowButton","ball-p32","throw",Rect2(safe.end.x-size-8,safe.end.y-size-6,size,size),func(): app.active_ball.throw_ball())
	throw.tooltip_text="Throw"
	ConceptScreen.piece(throw,"ball-p32","ic_ball",Rect2(size*0.31,size*0.17,size*0.38,size*0.38))
	ConceptScreen.words(throw,"Throw",Rect2(0,size*0.56,size,size*0.24),int(size*0.17))
	app.throw_button=throw

func _process(_delta: float) -> void:
	if not is_instance_valid(feedback) or not is_instance_valid(app.active_ball): return
	var b: BallGame=app.active_ball
	if p52:
		score.text="Practice throw" if b.practice else "Catches %d / 10"%b.catches
		for i in paws.size():
			var want=ConceptScreen.tex("ball-p32","paw_on" if i<b.catches else "paw_off")
			if paws[i].texture!=want: paws[i].texture=want
	else: score.text="Practice throw" if b.practice else "Throw %d of 10 · %d caught"%[clampi(b.throws+(0 if b.waiting or b.in_flight else 1),1,10),b.catches]
	var hint="Throw in the golden glow!" if p52 else "Tap Throw when the ball is in the gold band"
	if b.retry_save: hint="Saving needs another try: tap Throw"
	elif b.in_flight: hint="Foxy is chasing it!"
	elif b.waiting and b.bringing_back: hint="Foxy is bringing the ball back"
	elif b.waiting: hint="Foxy is getting ready"
	if feedback.text!=hint:
		feedback.text=hint
		# Longer lines shrink to stay inside the hint strip.
		if p52: PetUI.fit_points(feedback,feedback.size.x,int(feedback.size.y*0.5),11)
