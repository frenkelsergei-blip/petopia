extends Node2D
var activity: BallGame
func _process(_delta: float) -> void: queue_redraw()
func _draw() -> void:
	if not is_instance_valid(activity): return
	if ArtStyle.enabled:
		if not activity.in_flight and not activity.waiting and not activity.done:
			draw_arc(Vector2(activity.target_x(),288),11,PI,TAU,20,Color("cfa956"),2)
		if not activity.done and (not activity.waiting or activity.bringing_back or activity.returned) and not activity.ball_carried_in_art():
			# Held in the mouth the ball reads a little smaller, like a real bite.
			ItemVisual.paint(self,"ball_sun",activity.ball_position(),false,0.8 if activity.ball_carried() else 1.0)
		return
	var font=ThemeDB.fallback_font
	var ready=not activity.in_flight and not activity.waiting and not activity.done
	var left=(BallGame.PLAY_LEFT-330)/260.0
	var right=(BallGame.PLAY_RIGHT-330)/260.0
	draw_rect(Rect2(105,174,190,12),Color("8c9aa5"))
	draw_rect(Rect2(105+left*190,174,(right-left)*190,12),Color("edc66d"))
	var marker=105+activity.aim_fraction()*190
	draw_line(Vector2(marker,170),Vector2(marker,191),Color("233d52"),3)
	draw_string(font,Vector2(105,163),"THROW IN THE GOLD BAND" if ready else "FOXY PLAYS FETCH",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("425869"))
	draw_rect(Rect2(BallGame.PLAY_LEFT,285,BallGame.PLAY_RIGHT-BallGame.PLAY_LEFT,3),Color("ddbd75"))
	draw_string(font,Vector2(364,225),"PET CATCHES AUTOMATICALLY",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("425869"))
	draw_string(font,activity.child.position+Vector2(-33,28),"YOU · THROW",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("425869"))
	if ready:
		var target=Vector2(activity.target_x(),282)
		draw_arc(target,10,PI,TAU,16,Color("bd923c") if activity.in_throw_zone() else Color("748694"),2)
		draw_string(font,target+Vector2(-13,-16),"AIM",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("425869"))
	if activity.throw_animation>0:
		var hand=activity.child.position+Vector2(18,-28)
		draw_line(activity.child.position+Vector2(3,-24),hand,Color("4c7180"),4)
	if not activity.done and not (activity.waiting and not activity.bringing_back):
		ItemVisual.paint(self,"ball_sun",activity.ball_position())
