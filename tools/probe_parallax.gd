extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 Engine.physics_ticks_per_second=10
 root.size=Vector2i(1280,720)
 root.content_scale_size=Vector2i(1280,720)
 var main=load("res://scenes/main/main.tscn").instantiate()
 main.automation_mode=true
 main.save_directory="user://parallax-probe/"+str(Time.get_ticks_usec())
 root.add_child(main)
 main.show_river_art_test()
 var lab=main.active_lab
 lab.player.reset_to(Vector2(2040,288))
 lab.companion.position=Vector2(2000,288)
 lab.camera.snap_to_target()
 for i in range(30): await RenderingServer.frame_post_draw
 Input.action_press("move_right")
 var positions=[]
 var rendered={};var physical={}
 for index in range(90):
  await RenderingServer.frame_post_draw
  var row=[index,lab.meadow.camera_x,lab.meadow.render_camera_x]
  positions.append(row)
  if index>15:
   rendered[snappedf(row[2],0.01)]=true
   physical[snappedf(row[1],0.01)]=true
 TouchControls.release_actions()
 var okay=rendered.size()>physical.size()*3
 var report={"status":"pass" if okay else "fail","scope":"Actual rendered meadow at exaggerated10Hz physics / fixed120Hz rendering; source physics camera held between ticks while rendered parallax origin must advance with interpolated canvas transform.","unique_render_origins":rendered.size(),"unique_physics_origins":physical.size(),"frames":positions}
 var f=FileAccess.open("res://test-results/parallax-clock.json",FileAccess.WRITE)
 f.store_string(JSON.stringify(report,"\t"))
 print("PETOPIA PARALLAX CLOCK: ",report.status,"; render origins ",rendered.size(),"; physics origins ",physical.size())
 main.free()
 await process_frame
 quit(0 if okay else 1)
