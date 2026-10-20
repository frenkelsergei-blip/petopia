extends SceneTree
## A60 climb check: the boy climbs the Meadow Fields ladder, Foxy follows,
## then both climb down. Frames every few ticks -> test-results/climb/.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(844,390)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-results/climb/"))
	var main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory="user://climb/"+str(Time.get_ticks_usec())
	root.add_child(main)
	for i in 10: await physics_frame
	main.game.adopt("Foxy")
	main.show_world()
	for i in 20: await physics_frame
	var w=main.active_world
	var p=w.player
	p.global_position=Vector2(1330,606)
	w.companion.global_position=Vector2(1300,606)
	main.ui.visible=false
	for n in main.find_children("*","CanvasLayer",true,false): n.visible=false
	Input.action_press("move_right")
	for i in 40:
		await physics_frame
		if p.position.x>=1398: break
	Input.action_release("move_right")
	for i in 20: await physics_frame
	var k=0
	var log=[]
	Input.action_press("move_up")
	for i in 150:
		await physics_frame
		if i%6==0:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://test-results/climb/up_%03d.png"%k)
			log.append("%d boy y=%.1f climb=%s frame=%s | fox y=%.1f climb=%s frame=%s"%[k,p.position.y,p.is_climbing(),p.art.puppet.cur_frame.get("file",""),w.companion.position.y,w.companion.climbing.size.y>0,w.companion.art.puppet.cur_frame.get("file","")])
			k+=1
	Input.action_release("move_up")
	for i in 90:
		await physics_frame
		if i%6==0:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://test-results/climb/up_%03d.png"%k)
			log.append("%d WAIT boy x=%.1f y=%.1f | fox y=%.1f climb=%s frame=%s"%[k,p.position.x,p.position.y,w.companion.position.y,w.companion.climbing.size.y>0,w.companion.art.puppet.cur_frame.get("file","")])
			k+=1
	Input.action_press("move_down")
	for i in 150:
		await physics_frame
		if i%6==0:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://test-results/climb/up_%03d.png"%k)
			log.append("%d DOWN boy y=%.1f climb=%s frame=%s | fox y=%.1f climb=%s"%[k,p.position.y,p.is_climbing(),p.art.puppet.cur_frame.get("file",""),w.companion.position.y,w.companion.climbing.size.y>0])
			k+=1
	Input.action_release("move_down")
	# Step aside: Foxy finishes climbing down.
	Input.action_press("move_left")
	for i in 70:
		await physics_frame
		if i%6==0:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://test-results/climb/up_%03d.png"%k)
			log.append("%d ASIDE boy x=%.1f | fox y=%.1f climb=%s"%[k,p.position.x,w.companion.position.y,w.companion.climbing.size.y>0])
			k+=1
	Input.action_release("move_left")
	for l in log: print(l)
	quit()
