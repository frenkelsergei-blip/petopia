extends SceneTree
## Inventories every framed control (buttons, chips, panels) on each screen and
## size, with its height and caption font size, to expose inconsistencies.
## Output: test-results/ui-audit.json
var main: Control
var rows: Array=[]
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for i in range(12): await physics_frame
func collect(screen: String, size_name: String) -> void:
	await settle()
	var scope: Node=main
	for c in scope.find_children("*","Control",true,false):
		if not c.is_visible_in_tree(): continue
		var framed=c is Button or (c is Panel and c.get_theme_stylebox("panel")!=null and c.get_theme_stylebox("panel").get_script()!=null)
		if not framed: continue
		var caption: Label=c.get_node_or_null("Content/Caption")
		var text=(c.text if c is Button else "") if caption==null else caption.text
		var style=c.get_theme_stylebox("normal" if c is Button else "panel")
		var kind="flat" if style is StyleBoxFlat else ("empty" if style is StyleBoxEmpty else ("frame" if style!=null and style.get_script()!=null else "other"))
		rows.append({"screen":screen,"size":size_name,"name":str(c.name),"class":c.get_class(),"text":text,"w":roundi(c.size.x),"h":roundi(c.size.y),"font":caption.get_theme_font_size("font_size") if caption else (c.get_theme_font_size("font_size") if c is Button else 0),"layout":c.get_meta("compose",{}).get("layout","none"),"style":kind})
func run() -> void:
	for entry in [[Vector2i(390,844),"phone"],[Vector2i(844,390),"landscape"]]:
		root.size=entry[0]
		if is_instance_valid(main): main.free()
		main=load("res://scenes/main/main.tscn").instantiate()
		main.automation_mode=true
		main.save_directory="user://ui-audit/"+str(Time.get_ticks_usec())
		root.add_child(main)
		await collect("menu",entry[1])
		main.show_home(); await collect("adoption",entry[1])
		main.game.adopt("Foxy"); main.show_home(); await collect("home",entry[1])
		main.care_ui.toggle_overlay("care"); await collect("care",entry[1])
		main.care_ui.toggle_overlay("menu"); await collect("menu-overlay",entry[1])
		main.show_map(); await collect("map",entry[1])
		main.show_home(); main.care_ui.open("details"); await collect("details",entry[1])
		main.show_adventure("W01_L01"); await collect("adventure",entry[1])
		main.toggle_pause(); await collect("pause",entry[1])
		main.toggle_pause()
	main.free()
	var f=FileAccess.open("res://test-results/ui-audit.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(rows,"\t"))
	f.close()
	print("PETOPIA UI AUDIT: %d controls"%rows.size())
	quit()
