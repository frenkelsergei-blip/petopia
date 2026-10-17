extends SceneTree
## Graphics memory held on each public screen, at phone portrait size.
## Needs a real renderer (not --headless). Writes test-results/texture-memory.json.
const BUDGET_MB=80.0
var main: Control
var rows: Array=[]
func _initialize() -> void: call_deferred("run")
func measure(label: String) -> void:
	for i in range(20): await process_frame
	await RenderingServer.frame_post_draw
	var texture_mb=Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)/1048576.0
	var video_mb=Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576.0
	rows.append({"screen":label,"texture_mb":snappedf(texture_mb,0.1),"video_mb":snappedf(video_mb,0.1),"within_budget":texture_mb<=BUDGET_MB})
	print(label,": textures ",snappedf(texture_mb,0.1)," MB, video ",snappedf(video_mb,0.1)," MB")
func run() -> void:
	root.size=Vector2i(390,844)
	main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory="user://texture-memory/"+str(Time.get_ticks_usec())
	root.add_child(main)
	await measure("menu")
	main.show_adoption()
	await measure("adoption")
	main.game.adopt("Foxy")
	main.show_home()
	await measure("home")
	main.care_ui.toggle_overlay("care")
	await measure("home-care")
	main.show_details()
	await measure("details")
	main.show_map()
	await measure("map")
	main.show_shop()
	await measure("shop")
	root.size=Vector2i(844,390)
	main.show_adventure()
	await measure("picnic")
	main.show_adventure("W01_L02")
	await measure("windmill")
	main.show_ball()
	await measure("fetch")
	main.show_menu()
	await measure("menu-again")
	main.free()
	await process_frame
	var file=FileAccess.open("res://test-results/texture-memory.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"budget_mb":BUDGET_MB,"renderer":RenderingServer.get_video_adapter_name(),"screens":rows},"\t"))
	file.close()
	print("PETOPIA TEXTURE MEMORY: ",rows.size()," screens")
	quit()
