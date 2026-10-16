extends SceneTree
## Actual headed frame-time sample; isolated save, no desktop capture.
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in range(n): await process_frame
func stats(values: Array) -> Dictionary:
	values.sort()
	var total=0.0
	var over=0
	for value in values:
		total+=value
		if value>25: over+=1
	return {"samples":values.size(),"mean_ms":total/values.size(),"p99_ms":values[int((values.size()-1)*.99)],"worst_ms":values[-1],"over25ms":over}
func run() -> void:
	Engine.max_fps=120
	var main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory="user://care-profile/"+str(Time.get_ticks_usec())
	root.add_child(main)
	main.game.adopt("Foxy")
	var report={"engine":Engine.get_version_info().string,"samples":[],"scope":"Headed Apple M4 Pro compatibility renderer. Isolated saves; no phone certification. World plus two half-resolution blur passes; warmup excluded."}
	for dimensions in [Vector2i(390,844),Vector2i(844,390),Vector2i(1280,720)]:
		root.size=dimensions
		for state in ["quiet","care","details"]:
			main.show_home()
			if state=="details": main.show_details()
			elif state=="care": main.care_ui.toggle_overlay("care")
			await frames(45)
			var times=[]
			var last=Time.get_ticks_usec()
			for tick in range(240):
				await process_frame
				var now=Time.get_ticks_usec()
				times.append((now-last)/1000.0)
				last=now
			report.samples.append({"window":[dimensions.x,dimensions.y],"mode":state,"frame_time":stats(times)})
	var nodes=[]
	for i in range(12):
		main.show_home()
		main.show_details()
		await frames(4)
		nodes.append(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	report.nodes_after_modal_cycles=nodes
	main.free()
	await frames(3)
	var file=FileAccess.open("res://test-results/performance-care.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"));file.close()
	print("PETOPIA CARE PROFILE: nine headed samples, 12 modal cycles")
	quit()
