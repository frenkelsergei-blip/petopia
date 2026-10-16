class_name BallInterface
extends Control
var app: Control
var signature=""
var content: Control
var feedback: Label
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
	var portrait=dimensions.x<dimensions.y
	var backdrop=ModalBackdrop.new()
	content.add_child(backdrop)
	backdrop.configure(app.viewport.get_texture(),dimensions)
	var stage=Rect2(safe.position.x,safe.position.y+78,safe.size.x,safe.size.x*360/440)
	if not portrait:
		var height=maxf(120,safe.size.y-198)
		var width=minf(safe.size.x,height*640/360)
		stage=Rect2(safe.get_center().x-width/2,safe.position.y+78,width,height)
	app.viewport.get_parent().stretch=false
	WorldRender.configure(app.viewport,Vector2i(440 if portrait else 640,360))
	CareArt.frame(content,stage.grow(6))
	var image=TextureRect.new()
	image.name="GardenStage"
	image.texture=app.viewport.get_texture()
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.position=stage.position
	image.size=stage.size
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	content.add_child(image)
	CareArt.button(content,"My Pet",Rect2(safe.position.x,safe.position.y,150,56),app.show_home,"paw")
	CareArt.button(content,"",Rect2(safe.end.x-56,safe.position.y,56,56),app.toggle_pause,"gear")
	var bottom=safe.end.y
	var width=minf(420 if portrait else 900,safe.size.x)
	var x=safe.get_center().x-width/2
	var height=268 if portrait else 112
	var panel=CareArt.frame(content,Rect2(x,bottom-height,width,height))
	CareArt.title(panel,"Catch the Ball",Rect2(18,10,width-36,32),25)
	feedback=CareArt.title(panel,"Tap Throw in the gold band. Foxy catches and brings the ball back.",Rect2(18,47,width-36,68),18)
	feedback.visible=portrait
	var meter=ThrowMeter.new()
	meter.activity=app.active_ball
	meter.position=Vector2(18,126 if portrait else 40)
	meter.size=Vector2(width-36 if portrait else width*.66-24,64)
	panel.add_child(meter)
	app.throw_button=CareArt.button(panel,"Throw",Rect2(18 if portrait else width*.66,200 if portrait else 48,width-36 if portrait else width*.34-18,56),func(): app.active_ball.throw_ball(),"play",true)

func _process(_delta: float) -> void:
	if is_instance_valid(feedback) and app.toast_time>0: feedback.text=app.toast_label.text.replace("Space / E","Throw").replace("Space","Throw")
