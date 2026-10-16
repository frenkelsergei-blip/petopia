extends SceneTree
## Headed frame-time sample using isolated progress; never captures the desktop.
class MeasuredStore extends SaveStore:
	var durations: Array[float]=[]
	func write(candidate: Dictionary) -> bool:
		var started=Time.get_ticks_usec()
		var okay=super.write(candidate)
		durations.append((Time.get_ticks_usec()-started)/1000.0)
		return okay
var walls: Array[float]=[]
var cpu: Array[float]=[]
var physics: Array[float]=[]
var draws: Array[float]=[]
var label="sample"
func _initialize() -> void: call_deferred("run")
func stats(values: Array[float]) -> Dictionary:
	if values.is_empty(): return {"samples":0}
	var ordered=values.duplicate()
	ordered.sort()
	var total=0.0
	var long_frames=0
	for v in values:
		total+=v
		if v>25: long_frames+=1
	return {"samples":values.size(),"mean":total/values.size(),"p50":ordered[int((ordered.size()-1)*0.5)],"p95":ordered[int((ordered.size()-1)*0.95)],"p99":ordered[int((ordered.size()-1)*0.99)],"worst":ordered[-1],"over_25":long_frames}
func run() -> void:
	var args=OS.get_cmdline_user_args()
	if not args.is_empty(): label=args[0]
	ArtStyle.enabled=label not in ["before","after"]
	Engine.max_fps=120
	root.size=Vector2i(390,844) if label in ["portrait","concept-fidelity","hires-portrait","river-kit","world-rebuild","interaction-story","water-foam"] else Vector2i(1280,720)
	root.content_scale_size=Vector2i(1280,720)
	var main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory="user://performance/"+str(Time.get_ticks_usec())
	root.add_child(main)
	main.game.adopt("Profile Fox")
	var measured=MeasuredStore.new(main.save_directory)
	main.game.store=measured
	var nodes: Array[int]=[]
	for cycle in range(12):
		main.show_home()
		await process_frame
		if label in ["river-kit","world-rebuild","interaction-story","water-foam"]: main.show_river_art_test()
		else: main.show_adventure("W01_L02")
		await process_frame
		await process_frame
		nodes.append(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	var level: Node2D=main.active_lab if label in ["river-kit","world-rebuild","interaction-story","water-foam"] else main.active_adventure
	if label in ["river-kit","world-rebuild","interaction-story","water-foam"]: level.interact()
	level.player.reset_to(Vector2(1698,288) if label in ["river-kit","world-rebuild","interaction-story","water-foam"] else Vector2(800,288))
	level.companion.position=Vector2(1656,288) if label in ["river-kit","world-rebuild","interaction-story","water-foam"] else Vector2(760,288)
	# A normal autosave occurs during the sample, alongside pickups and puzzle commits.
	main.game.save_timer=28
	var last=Time.get_ticks_usec()
	var jumped=false
	var direction=1
	for tick in range(1600):
		if label in ["river-kit","world-rebuild","interaction-story","water-foam"]:
			if level.player.position.x>1930: direction=-1
			if level.player.position.x<1705:
				direction=1
				jumped=false
			Input.action_release("move_left" if direction>0 else "move_right")
		Input.action_press("move_right" if direction>0 else "move_left")
		if not jumped and level.player.position.x>(1800 if label in ["river-kit","world-rebuild","interaction-story","water-foam"] else 1354) and level.player.is_on_floor():
			Input.action_press("jump")
			jumped=true
		if level.player.velocity.y>0: Input.action_release("jump")
		if label not in ["river-kit","world-rebuild","interaction-story","water-foam"] and absf(level.player.position.x-950)<30 and not level.run.bridge: level.interact()
		await process_frame
		var now=Time.get_ticks_usec()
		if tick>30:
			walls.append((now-last)/1000.0)
			cpu.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000.0)
			physics.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0)
			draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		last=now
	TouchControls.release_actions()
	var report={"label":label,"window":str(root.size),"engine":Engine.get_version_info().string,"rendered":DisplayServer.get_name()!="headless","fps_cap":Engine.max_fps,"frame_ms":stats(walls),"process_ms":stats(cpu),"physics_ms":stats(physics),"save_ms":stats(measured.durations),"draw_calls":stats(draws),"nodes_after_scene_cycles":nodes,"end_position":str(level.player.position),"interpolation":ProjectSettings.get_setting("physics/common/physics_interpolation",false),"scope":"Single-machine headed run, isolated profile. Startup/warmup excluded. Includes pickups, an autosave and repeated scene changes; not a device certification."}
	DirAccess.make_dir_recursive_absolute("res://test-results")
	var f=FileAccess.open("res://test-results/performance-"+label+".json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"\t"))
	f.close()
	print("PETOPIA PROFILE ",JSON.stringify(report))
	main.free()
	await process_frame
	quit()
