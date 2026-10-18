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

func _process(_delta: float) -> void:
	if not is_instance_valid(feedback) or not is_instance_valid(app.active_ball): return
	var b: BallGame=app.active_ball
	score.text="Practice throw" if b.practice else "Throw %d of 10 · %d caught"%[clampi(b.throws+(0 if b.waiting or b.in_flight else 1),1,10),b.catches]
	var hint="Tap Throw when the ball is in the gold band"
	if b.retry_save: hint="Saving needs another try: tap Throw"
	elif b.in_flight: hint="Foxy is chasing it!"
	elif b.waiting and b.bringing_back: hint="Foxy is bringing the ball back"
	elif b.waiting: hint="Foxy is getting ready"
	feedback.text=hint
