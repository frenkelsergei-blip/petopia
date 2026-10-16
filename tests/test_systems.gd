extends SceneTree

var checks = 0
var failures: Array[String] = []
var utc = 1000000.0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		push_error(description)

func run() -> void:
	var folder="user://test-runs/"+str(Time.get_ticks_usec())
	var game=GameState.new(folder)
	game.clock_utc=func(): return utc
	root.add_child(game)
	game.set_process(false)
	check(game.adopt("Pip"),"Adoption persists")
	check(game.pet().name=="Pip","Chosen name retained")
	check(not game.adopt("Another"),"Cannot adopt twice over existing save")
	var loaded=SaveStore.new(folder).load_state()
	check(loaded.pets[0].pet_id==game.pet().pet_id and loaded.pets[0].name=="Pip","Identity survives reloading")
	check(game.state.coins==0,"Begin at zero coins")
	for action in ["feed","clean","pet","water","sleep"]:
		check(game.care(action),"Free care at zero coins: "+action)
	check(game.pet().needs.fullness==100 and game.pet().needs.cleanliness==100 and game.pet().sleeping,"Care changes intended state")
	var bond=game.pet().bond_xp
	game.care("feed")
	check(game.pet().bond_xp==bond,"Repeated care restores without farming XP")
	for boundary in [7,30,60]:
		var s=PetRules.fresh("Foxy",utc)
		PetRules.apply_elapsed(s.pets[0],boundary*PetRules.DAY-1,false)
		var expected_before={7:"baby",30:"child",60:"teen"}[boundary]
		var expected_after={7:"child",30:"teen",60:"adult"}[boundary]
		check(s.pets[0].growth_stage==expected_before,"Before growth boundary "+str(boundary))
		PetRules.apply_elapsed(s.pets[0],1,false)
		check(s.pets[0].growth_stage==expected_after,"At growth boundary "+str(boundary))
	var absence=PetRules.fresh("Foxy",utc)
	absence.pets[0].bond_xp=123
	PetRules.reconcile(absence,utc+90*PetRules.DAY)
	check(absence.pets[0].growth_stage=="adult","90 days advances age")
	check(absence.pets[0].needs.fullness==44 and absence.pets[0].needs.health==100,"Offline decay capped at 12 hours; health preserved")
	check(absence.pets[0].bond_xp==123,"Absence preserves bond")
	var age=absence.pets[0].elapsed_age_seconds
	var food=absence.pets[0].needs.fullness
	PetRules.reconcile(absence,utc+90*PetRules.DAY)
	PetRules.reconcile(absence,utc-500)
	check(absence.pets[0].elapsed_age_seconds==age and absence.pets[0].needs.fullness==food,"Repeated load and backward clock do not reapply elapsed time")
	check(absence.pets[0].growth_stage=="adult","No stage regression")
	var too_hungry=PetRules.fresh("Foxy",utc)
	too_hungry.pets[0].needs.fullness=5.0
	PetRules.apply_elapsed(too_hungry.pets[0],90*PetRules.DAY,true)
	check(too_hungry.pets[0].needs.fullness==5,"Offline floor never raises preexisting low need")
	check(not game.purchase("ball_sun","cant_afford") and game.state.coins==0,"Unaffordable purchase changes nothing")
	var s=game.state.duplicate(true)
	s.coins=350
	check(game.commit(s),"Seed isolated economy test")
	check(game.purchase("ball_sun","purchase_1"),"Buy affordable toy")
	check(not game.purchase("ball_sun","purchase_1"),"Duplicate purchase rejected")
	check(game.state.coins==250 and game.state.inventory.ball_sun==1,"Debit and item grant once")
	check(game.place_toy(1),"Toy placement")
	check(SaveStore.new(folder).load_state().room_layout[0].slot==1,"Placement survives reload")
	check(not game.place_toy(8),"Invalid placement rejected")
	check(game.place_toy(-1) and game.state.inventory.ball_sun==1,"Remove toy returns ownership")
	var run_state=game.start_run()
	run_state.basket=true
	run_state.secret=true
	run_state.cache_open=true
	run_state.pickups=[0,1,2]
	check(game.checkpoint(run_state),"Checkpoint persists")
	check(game.finish_run(run_state)==63,"Completion, pickups and first discovery reward")
	var receipt=game.state.quest_state.last_completion
	check(receipt.total_coins==63 and receipt.base_coins==50 and receipt.pickup_coins==3 and receipt.discovery_coins==10 and receipt.meals==1,"Durable result receipt explains exactly the rewards that were granted")
	check(SaveStore.new(game.store.directory).load_state().quest_state.last_completion.run_id==run_state.id,"Completion receipt survives JSON save and reload")
	var balance=game.state.coins
	check(game.finish_run(run_state)==-1 and game.state.coins==balance,"Duplicate result rejected")
	var replay=game.start_run()
	replay.basket=true
	replay.secret=true
	replay.cache_open=true
	game.checkpoint(replay)
	check(game.finish_run(replay)==50,"Replay completion paid; discovery unique")
	check(not game.minigame_result("quit",0,0),"Immediate exit grants no activity rewards")
	check(game.minigame_result("played",4,10),"Meaningful activity grants result")
	check(not game.minigame_result("played",4,10),"Activity session pays once")
	var before=game.state.duplicate(true)
	var invalid=game.state.duplicate(true)
	invalid.coins=-1
	check(not game.commit(invalid) and game.state==before,"Invalid transaction preserves state")
	invalid=game.state.duplicate(true)
	invalid.settings.reduced_motion="bad"
	check(not game.store.validate(invalid),"Wrong settings type rejected")
	invalid=game.state.duplicate(true)
	invalid.pets[0].needs.fullness="bad"
	check(not game.store.validate(invalid),"Wrong need type rejected")
	# A torn temporary file must not affect the active snapshot.
	var f=FileAccess.open(folder.path_join("save.tmp"),FileAccess.WRITE)
	f.store_string("{unfinished");f.close()
	check(not SaveStore.new(folder).load_state().is_empty(),"Interrupted temp write leaves active save intact")
	game.save()
	var backup=SaveStore.new(folder)._read(folder.path_join("save.backup.json"))
	f=FileAccess.open(folder.path_join("save.json"),FileAccess.WRITE)
	f.store_string("not valid json");f.close()
	var recovery=SaveStore.new(folder)
	var restored=recovery.load_state()
	check(recovery.recovered and restored==backup,"Corrupt primary recovers exact known-good backup")
	f=FileAccess.open(folder.path_join("save.backup.json"),FileAccess.WRITE)
	f.store_string("also broken");f.close()
	var blocked_store=SaveStore.new(folder)
	check(blocked_store.load_state().is_empty() and blocked_store.blocked,"Both corrupt files block silent new game")
	# Failed destination write cannot publish a purchase.
	game.store=SaveStore.new(folder)
	game.store.directory="/dev/null/petopia-test"
	var stable=game.state.duplicate(true)
	check(not game.purchase("berry_bowl","failed_write") and game.state==stable,"Write failure rolls back purchase")
	game.free()
	var report={"engine":Engine.get_version_info().string,"checks":checks,"failures":failures,"profile":folder,"scope":"System boundaries only; no device certification or full playthrough."}
	DirAccess.make_dir_recursive_absolute("res://test-results")
	f=FileAccess.open("res://test-results/systems.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"\t"));f.close()
	print("PETOPIA SYSTEM TESTS: ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
