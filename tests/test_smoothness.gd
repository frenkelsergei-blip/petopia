extends SceneTree
## Verify background writes with a deliberately slow disk and real character physics.
class SlowStore extends SaveStore:
	var writes=0
	var fail_next=false
	func write(candidate: Dictionary) -> bool:
		OS.delay_msec(180)
		writes+=1
		if fail_next:
			fail_next=false
			last_error="Simulated disk write failed."
			return false
		return super.write(candidate)
var checks=0
var failures: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok: bool, note: String) -> void:
	checks+=1
	if not ok:
		failures.append(note)
		push_error(note)
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func run() -> void:
	var main=load("res://scenes/main/main.tscn").instantiate()
	main.save_directory="user://smoothness-tests/"+str(Time.get_ticks_usec())
	root.add_child(main)
	main.game.adopt("Smooth Fox")
	var run_state=main.game.start_run()
	main.show_lab()
	await frames(4)
	var slow=SlowStore.new(main.save_directory)
	main.game.store=slow
	var started=Time.get_ticks_usec()
	for i in range(40):
		run_state.pickups=range(i%21)
		main.game.queue_checkpoint(run_state)
	var enqueue_ms=(Time.get_ticks_usec()-started)/1000.0
	check(enqueue_ms<100,"Forty checkpoint requests do not wait for slow disk writes")
	check(main.game.pending_save_count()<=2,"Pickup bursts retain at most one active write and one newest snapshot")
	var x=main.active_lab.player.position.x
	Input.action_press("move_right")
	await frames(20)
	Input.action_release("move_right")
	check(main.active_lab.player.position.x>x+25,"Player physics keeps advancing while persistence is pending")
	check(main.game.save(),"Explicit save flushes ordered background state")
	var loaded=SaveStore.new(main.save_directory).load_state()
	check(loaded.pending_run.pickups==range(18),"Coalescing preserves the latest full pickup list")
	check(slow.writes<=3,"Forty pickup requests do not create forty disk writes")
	var coins=main.game.state.coins
	var award=main.game.state.duplicate(true)
	award.coins=150
	main.game.commit(award)
	main.game.queue_save()
	check(main.game.purchase("ball_sun","slow-purchase"),"Purchase orders behind an active background write")
	loaded=SaveStore.new(main.save_directory).load_state()
	check(loaded.coins==50 and loaded.inventory.ball_sun==1,"Background snapshots cannot overwrite a completed purchase")
	check(not main.game.purchase("ball_sun","slow-purchase") and main.game.state.coins==50,"Duplicate purchase stays idempotent after background saving")
	# A failed background write must be visible and retained for retry.
	slow.fail_next=true
	main.game.queue_save()
	while main.game._save_thread!=null and main.game._save_thread.is_alive(): await process_frame
	main.game._poll_save(0)
	check(not main.game.background_save_error.is_empty() and main.game.pending_save_count()==1,"Background failure reports an error and retains a retry snapshot")
	check(main.game.save() and main.game.background_save_error.is_empty(),"Explicit retry recovers the latest state")
	check(ProjectSettings.get_setting("physics/common/physics_interpolation",false),"Physics interpolation is enabled for smooth rendering")
	check(main.active_lab.camera.process_callback==Camera2D.CAMERA2D_PROCESS_PHYSICS and main.active_lab.camera.process_physics_priority>main.active_lab.player.process_physics_priority,"Camera follows on the physics clock after the player")
	main.active_lab.player.reset_to(Vector2(1012.5,288))
	await frames(2)
	check(absf(main.active_lab.camera.position.x-main.active_lab.player.position.x)<0.01,"Camera follows fractional positions without integer stepping")
	main.active_lab.reset_checkpoint()
	check(is_equal_approx(main.active_lab.camera.position.x,main.viewport.get_visible_rect().size.x/2.0/main.active_lab.camera.zoom.x),"Checkpoint reset snaps camera instead of sweeping across the level")
	main.game.queue_save()
	main.game.queue_save()
	main.free()
	await frames(2)
	check(not SaveStore.new(main.save_directory if is_instance_valid(main) else slow.directory).load_state().is_empty(),"Scene shutdown joins the writer and preserves a valid save")
	var f=FileAccess.open("res://test-results/smoothness.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"enqueue_ms":enqueue_ms,"scope":"Artificial 180 ms disk delay; bounded coalescing, live movement, purchase ordering, failure/retry, shutdown flush, camera clock and checkpoint reset."},"\t"))
	f.close()
	print("PETOPIA SMOOTHNESS TESTS: ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
