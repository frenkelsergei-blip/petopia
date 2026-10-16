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
func run() -> void:
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
