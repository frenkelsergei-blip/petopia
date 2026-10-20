extends SceneTree
class RecordingStore:
	extends SaveStore
	var writes=0
	var fail_next=false
	func write(value: Dictionary) -> bool:
		writes+=1
		if fail_next:
			fail_next=false
			last_error="Injected browser-writer failure"
			return false
		return super.write(value)
var checks=0
var failures: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures.append(message);push_error(message)
func frames(n=3) -> void:
	for i in range(n): await process_frame
func adventure_art_reference() -> WeakRef:
	# Own scope: no temporary in run() keeps the texture alive.
	ArtStyle.prepare()
	return weakref(ArtStyle._background)
func run() -> void:
	var exports=ConfigFile.new()
	check(exports.load("res://export_presets.cfg")==OK,"Release preset is readable")
	var files=exports.get_value("preset.0","export_files",PackedStringArray())
	check(files.has("res://scenes/main/main.tscn") and files.has("res://scripts/ui/care_interface.gd") and files.has("res://scripts/ui/modal_blur.gdshader"),"Curated Web package includes boot scene, native care scripts and blur shader")
	# A Uint8Array handed to preloadFile becomes a 41-million-number string key
	# inside the engine (config.fileSizes[file]); that string crashed phones.
	var shell=FileAccess.get_file_as_string("res://web/shell.html")
	check(shell.contains("engine.preloadFile(pack.buffer,") and not shell.contains("engine.preloadFile(pack,"),"Web loader hands the engine the raw pack buffer, never a byte view")
	check(shell.contains(".body.getReader()") and not shell.contains("arrayBuffer())"),"Web loader streams each pack part into the one pack buffer")
	var plan=ArtTexture.plan()
	var shipped=func(source: String) -> bool: return files.has(plan[source].runtime if plan.has(source) else source)
	check(shipped.call(("res://assets/ui/room-p43/plate.png" if ResourceLoader.exists("res://assets/ui/room-p43/plate.png") else "res://assets/ui/room-paper/plate.png") if ArtStyle.paper else "res://assets/art/home-flow-v1/room-portrait.png") and files.has("res://assets/art/home-flow-v1/idle-actors.json") and files.has("res://assets/ui/home-flow-v1/icons.json"),"Web includes dynamic selected-flow art and frame metadata")
	check(files.has(ArtTexture.MANIFEST) and files.has("res://scripts/art/art_texture.gd") and not plan.is_empty(),"Web ships the shared image loader and its runtime-size manifest")
	var swapped=true
	var coordinates=true
	var held_bytes=0
	for source in plan:
		var entry=plan[source]
		swapped=swapped and files.has(entry.runtime) and not files.has(source)
		var image: Image=ResourceLoader.load(entry.runtime,"Image",ResourceLoader.CACHE_MODE_IGNORE)
		coordinates=coordinates and image.get_size()==Vector2i(entry.runtime_size[0],entry.runtime_size[1]) and image.get_width()<=entry.source[0] and image.get_height()<=entry.source[1]
		coordinates=coordinates and ArtTexture.load_texture(source).get_size()==Vector2(entry.source[0],entry.source[1])
	# A60: painted room set pieces (meadow-p31/set_*) load per room and are
	# released on leaving it; they are measured per room, not in the total.
	var set_bytes={}
	var sets_meta=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/meadow-p31/sets.json")) if FileAccess.file_exists("res://assets/art/meadow-p31/sets.json") else {}
	for path in files:
		if path.ends_with(".png"):
			var image=ResourceLoader.load(path,"Image",ResourceLoader.CACHE_MODE_IGNORE) if path.begins_with("res://assets/runtime/") else load(path)
			# A62: a room's own building-block kit (mf_ = Meadow Fields) loads
			# only in that room, like its set pieces.
			if path.get_file().begins_with("mf_"):
				set_bytes["@mf"]=int(set_bytes.get("@mf",0))+image.get_width()*image.get_height()*4
				continue
			if path.get_file().begins_with("set_"):
				set_bytes[path.get_file().trim_prefix("set_").trim_suffix(".png")]=image.get_width()*image.get_height()*4
				continue
			held_bytes+=image.get_width()*image.get_height()*4
	var worst_room=0
	for rid in GameState.world_data().rooms:
		var sum=0
		for sp in GameState.world_data().rooms[rid].get("sets",[]): sum+=int(set_bytes.get(String(sp.name),0))
		if GameState.world_data().rooms[rid].get("kit","")=="meadow": sum+=int(set_bytes.get("@mf",0))
		worst_room=maxi(worst_room,sum)
	check(worst_room<=48*1048576,"One room's painted set pieces stay within 48 MiB decoded (largest %.1f MiB)"%(worst_room/1048576.0))
	check(swapped,"Web exports each measured runtime copy instead of its full-size source image")
	check(coordinates,"Runtime copies report source size, so atlas regions, pivots and layouts keep source coordinates")
	# Ceiling reviewed in A50: the V2 Green Meadows world adds ~15 MiB on top of
	# the A46 total while V1 level art is still shipped. Grow only with review.
	check(held_bytes<=220*1048576,"All shipped images together stay within the reviewed 220 MiB decoded ceiling (now %.1f MiB)"%(held_bytes/1048576.0))
	check(ArtTexture.load_texture(PetUI.COIN_PATH)==ArtTexture.load_texture(PetUI.COIN_PATH),"An image in use is shared, not decoded twice")
	var adventure_art=adventure_art_reference()
	ArtStyle.release()
	check(adventure_art.get_ref()==null,"Leaving a screen releases adventure art nothing still draws")
	var folder="user://web-writer-tests/"+str(Time.get_ticks_usec())
	var game=GameState.new(folder)
	game.threaded_saves=false
	root.add_child(game)
	game.store=RecordingStore.new(folder)
	var store=game.store
	check(game.adopt("Web Fox"),"Threadless adoption commits through the existing validated transaction")
	var before=store.writes
	for i in range(40):
		game.state.coins=i
		game.queue_save()
	check(game.pending_save_count()==1 and store.writes==before,"Web pickup bursts keep one latest snapshot and one scheduled writer")
	await frames()
	check(store.writes==before+1 and SaveStore.new(folder).load_state().coins==39,"One idle write persists the newest full browser snapshot")
	game.state.coins=40
	game.queue_save()
	var candidate=game.state.duplicate(true)
	candidate.coins=90
	check(game.commit(candidate),"Explicit transaction safely supersedes a pending idle save")
	await frames()
	check(SaveStore.new(folder).load_state().coins==90,"A delayed callback cannot restore the older balance after a transaction")
	store.fail_next=true
	game.state.coins=91
	game.queue_save()
	await frames()
	check(game.pending_save_count()==1 and not game.background_save_error.is_empty() and SaveStore.new(folder).load_state().coins==90,"Failed browser write retains latest snapshot and known-good durable state")
	game._save_retry=0
	game._poll_save(0)
	await frames()
	check(SaveStore.new(folder).load_state().coins==91 and game.background_save_error.is_empty(),"Browser writer retries its one pending snapshot")
	check(game.minigame_result("web-round",4,10) and not game.minigame_result("web-round",4,10),"Threadless reward transaction remains durable and duplicate-safe")
	game.state.coins=92
	game.queue_save()
	game.free()
	await frames()
	check(SaveStore.new(folder).load_state().coins==92,"Shutdown flushes a pending threadless snapshot")
	var file=FileAccess.open("res://test-results/web.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Native forced threadless writer: coalescing, stale callback ordering, failure/retry, duplicate reward and shutdown. Browser IndexedDB reload is verified separately; physical phones remain pending."},"\t"));file.close()
	print("PETOPIA WEB TESTS: ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
