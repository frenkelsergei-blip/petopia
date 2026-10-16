extends SceneTree
var main: Control
var samples: Array[float]=[]
var args: PackedStringArray
func _initialize() -> void: call_deferred("run")
func run() -> void:
 args=OS.get_cmdline_user_args()
 Engine.max_fps=120
 root.size=Vector2i(500,920)
 var app=load("res://scenes/main/main.tscn").instantiate()
 main=app
 main.automation_mode=true
 main.save_directory="user://motion-profile/"+str(Time.get_ticks_usec())
 root.add_child(main)
 main.show_river_art_test()
 main.active_lab.interact()
 main.active_lab.player.reset_to(Vector2(1960,288))
 main.active_lab.companion.position=Vector2(1920,288)
 var last=Time.get_ticks_usec()
 for index in range(1100):
  if main.active_lab.player.position.x>2440: Input.action_release("move_right");Input.action_press("move_left")
  elif main.active_lab.player.position.x<1970: Input.action_release("move_left");Input.action_press("move_right")
  await process_frame
  var now=Time.get_ticks_usec()
  if index>100:samples.append((now-last)/1000.0)
  last=now
 TouchControls.release_actions()
 var ordered=samples.duplicate();ordered.sort()
 var total=0.0;var long_frames=0
 for n in samples:
  total+=n
  if n>25:long_frames+=1
 var label=args[0] if args.size()>0 else "sample"
 var output={"scope":"Headed 500x920, actual continuous run left/right over same lab ground, vsync default, cap120, separate save; existing user game/editor remain open. Warmup100frames excluded.","samples":samples.size(),"mean_ms":total/samples.size(),"p95_ms":ordered[int(ordered.size()*.95)],"p99_ms":ordered[int(ordered.size()*.99)],"worst_ms":ordered[-1],"over25ms":long_frames,"fps_reported":Engine.get_frames_per_second(),"vsync":DisplayServer.window_get_vsync_mode(),"refresh_hz":DisplayServer.screen_get_refresh_rate()}
 var file=FileAccess.open("res://test-results/motion-"+label+".json",FileAccess.WRITE)
 file.store_string(JSON.stringify(output,"\t"))
 print("PETOPIA MOTION ",JSON.stringify(output))
 main.free()
 await process_frame
 quit()
