extends SceneTree
## A48 layout lint: every composed control on every screen and size must show
## its full text, keep icon and text on one centre line, keep tile content
## centred, stay inside its frame, and share one text size with same-row
## siblings. Screens are the real ones, built through main.gd.
var checks=0
var failures: Array[String]=[]
var main: Control
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures.append(message);push_error(message)
func settle() -> void:
	for i in range(10): await physics_frame
func text_width(label: Label) -> float:
	return label.get_theme_font("font").get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.get_theme_font_size("font_size")).x
func lint(screen: String) -> void:
	await settle()
	var problems: Array[String]=[]
	var rows: Dictionary={}
	var seen=0
	for c in main.find_children("*","Control",true,false):
		if not c.is_visible_in_tree() or not c.has_meta("compose"): continue
		var spec: Dictionary=c.get_meta("compose")
		seen+=1
		var box: Rect2=c.get_global_rect()
		var glyph: Control=c.get_node_or_null("Content/Symbol")
		if glyph==null: glyph=c.get_node_or_null("Content/CoinIcon")
		var caption: Label=c.get_node_or_null("Content/Caption")
		if caption==null: caption=c.get_node_or_null("Content/Total")
		var sub: Label=c.get_node_or_null("Content/Subcaption")
		var id="%s '%s'"%[c.name,caption.text if caption else ""]
		for label in [caption,sub]:
			if label and label.visible and not label.text.strip_edges().is_empty() and text_width(label)>label.size.x+1.0:
				problems.append(id+" text clipped (%.0f > %.0f)"%[text_width(label),label.size.x])
		for part in [glyph,caption]:
			if part and part.visible and not box.grow(0.5).encloses(part.get_global_rect()):
				problems.append(id+" "+str(part.name)+" outside its frame")
		var holder: Node=c.get_parent()
		while holder!=null and not holder is ScrollContainer: holder=holder.get_parent()
		if holder!=null:
			var visible_area: Rect2=(holder as Control).get_global_rect()
			var bar: ScrollBar=(holder as ScrollContainer).get_v_scroll_bar()
			if bar.visible: visible_area.size.x-=bar.size.x
			if box.position.x<visible_area.position.x-0.5 or box.end.x>visible_area.end.x+0.5:
				problems.append(id+" cut off at the side of its scrolling area")
		var single=caption and caption.visible and not caption.text.strip_edges().is_empty() and (sub==null or not sub.visible)
		if spec.layout in ["row","left"] and glyph and single:
			var dy=absf(glyph.get_global_rect().get_center().y-caption.get_global_rect().get_center().y)
			if dy>1.0: problems.append(id+" icon and text off-centre by %.1f px"%dy)
		if spec.layout=="tile":
			if glyph and absf(glyph.get_global_rect().get_center().x-box.get_center().x)>1.0: problems.append(id+" tile icon off-centre")
			if caption and absf(caption.get_global_rect().get_center().x-box.get_center().x)>1.0: problems.append(id+" tile label off-centre")
		if c is Button and caption and caption.visible and spec.layout!="icon":
			var key="%s|%d|%d|%s"%[c.get_parent().get_instance_id(),roundi(box.size.y),roundi(box.position.y),spec.layout]
			if not rows.has(key): rows[key]=[]
			rows[key].append(caption.get_theme_font_size("font_size"))
	for key in rows:
		var sizes: Array=rows[key]
		if sizes.max()!=sizes.min(): problems.append("same-row buttons use different text sizes %s"%str(sizes))
	# Known exceptions: the portrait adventure shows only the rotate notice;
	# landscape details is still the fixed V06 reference layout (open item).
	var minimum=0 if screen.begins_with("details (") and not screen.begins_with("details (390") else (2 if screen.begins_with("adventure (390") or screen.begins_with("adventure (768") else 3)
	# A55 paper home screens are built from concept P26 (ConceptScreen pieces,
	# not PetUI.compose); their buttons are counted by their concept face.
	if ArtStyle.paper:
		for c in root.find_children("*","Button",true,false):
			if c.is_visible_in_tree() and c.has_node("Face"): seen+=1
		# P26's quiet room has exactly two buttons: Menu and Care.
		if screen.begins_with("home ("): minimum=2
		# P47 portrait details: My Pet and Care are its two buttons.
		if screen.begins_with("details (390"): minimum=2
		# P53: the portrait adventure shows only the rotate card (Back to My Pet).
		if screen.begins_with("adventure (390") or screen.begins_with("adventure (768"): minimum=1
	check(seen>=minimum,screen+": lint found %d composed controls"%seen)
	check(problems.is_empty(),screen+": "+("ok" if problems.is_empty() else "; ".join(problems)))
func fresh(size_value: Vector2i) -> void:
	if is_instance_valid(main):
		paused=false
		main.free()
		await process_frame
	root.size=size_value
	main=load("res://scenes/main/main.tscn").instantiate()
	main.automation_mode=true
	main.save_directory="user://ui-layout/"+str(Time.get_ticks_usec())
	root.add_child(main)
func run() -> void:
	for size_value in [Vector2i(390,844),Vector2i(844,390),Vector2i(768,1024),Vector2i(1280,720)]:
		var tag=" "+str(size_value)
		await fresh(size_value)
		await lint("menu"+tag)
		main.show_home(); await lint("adoption"+tag)
		main.game.adopt("Foxy"); main.show_home(); await lint("home"+tag)
		main.care_ui.toggle_overlay("care"); await lint("care drawer"+tag)
		main.care_ui.toggle_overlay("menu"); await lint("menu overlay"+tag)
		main.show_map(); await lint("map"+tag)
		main.show_home(); main.care_ui.open("details"); await lint("details"+tag)
		main.show_adventure("W01_L01"); await lint("adventure"+tag)
		main.toggle_pause(); await lint("pause"+tag)
		main.toggle_pause()
		var run_state=main.game.state.pending_run.duplicate(true)
		run_state.basket=true
		main.game.finish_run(run_state)
		main.show_adventure_result("W01_L01"); await lint("result"+tag)
	paused=false
	main.free()
	await process_frame
	print("PETOPIA UI LAYOUT TESTS: %d checks; %d failures"%[checks,failures.size()])
	quit(1 if failures.size() else 0)
