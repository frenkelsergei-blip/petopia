extends HomeArt

func _draw() -> void:
	if ArtStyle.enabled:
		draw_room_art()
		if is_instance_valid(state) and not state.state.is_empty():
			var slot=toy_preview if toy_preview>=0 else placed_toy_slot()
			# The paper room draws its own toys (draw_paper_toy / Tamagotchi ball).
			if slot>=0 and not ArtStyle.paper: ItemVisual.paint(self,"ball_sun",toy_position(slot),toy_preview>=0)
		return
	box(0,0,640,360,"d6dde1")
	box(0,265,640,95,"8c979f")
	for y in range(266,360,16): box(0,y,640,1,"9eabb3")
	for x in range(0,641,32): box(x,265,1,95,"9eabb3")
	# A window and two distant hills give context without disguising the test room.
	box(348,88,126,110,"8396a3");box(352,92,118,102,"c4d6dd")
	draw_polygon(PackedVector2Array([Vector2(352,194),Vector2(392,136),Vector2(446,194)]),PackedColorArray([Color("acc1c8")]))
	draw_polygon(PackedVector2Array([Vector2(398,194),Vector2(444,144),Vector2(470,194)]),PackedColorArray([Color("9cb4be")]))
	box(409,92,3,102,"8396a3")
	box(208,249,35,30,"b5c8cf")
	box(211,253,29,6,"d6eced")
	box(250,268,27,13,"98b3bc")
	box(253,266,21,7,"e1e5dc")
	box(475,245,82,21,"a2a6bb")
	box(479,242,74,14,"bfc5d4")
	var font=ThemeDB.fallback_font
	for entry in [["WASH",Vector2(211,240)],["BOWL",Vector2(250,258)],["BED",Vector2(500,230)]]:
		draw_string(font,entry[1],entry[0],HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("405363"))
	for i in range(3):
		var x=[330,415,530][i]
		draw_arc(Vector2(x,289),14,0,TAU,24,Color("c6d2d7"),1)
		draw_string(font,Vector2(x-8,315),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("405363"))
	if is_instance_valid(state) and not state.state.is_empty():
		var slot=toy_preview
		if slot == -1 and not state.state.room_layout.is_empty(): slot=int(state.state.room_layout[0].slot)
		if slot>=0:
			var at=Vector2([330,415,530][slot],282) if toy_preview>=0 else toy_position(slot)
			ItemVisual.paint(self,"ball_sun",at,toy_preview>=0)
			if toy_preview>=0:
				draw_arc(at,12,0,TAU,24,Color("fff3d9"),2)
				draw_string(font,at+Vector2(20,3),"PREVIEW",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("405363"))
			elif toy_play_time>0:
				draw_string(font,at+Vector2(-16,-19),"PLAY!",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("416b72"))
	if reaction>0 and is_instance_valid(pet_art):
		var p=pet_art.position-Vector2(17,48)
		var text={"feed":"FOOD +","clean":"CLEAN +","pet":"HAPPY +","water":"HEALTH +","sleep":"REST"}.get(last_action,"TOGETHER")
		draw_string(font,p,text,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("416b72"))
		if last_action=="clean":
			for i in range(4): draw_arc(pet_art.position+Vector2(i*7-10,-20-i*5),4,0,TAU,12,Color("d9edf2"),1)
