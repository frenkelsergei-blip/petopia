class_name GameState
extends Node

signal changed
signal feedback(message: String)

var store: SaveStore
var state: Dictionary = {}
var clock_utc: Callable = func(): return Time.get_unix_time_from_system()
var _last_tick = 0.0
var clock_monotonic: Callable = func(): return Time.get_ticks_msec()/1000.0:
	set(value):
		clock_monotonic = value
		_last_tick = float(value.call())
var save_timer = 0.0
var suspended = false
var _save_thread: Thread
var _pending_snapshot: Dictionary = {}
var _save_retry = 0.0
var background_save_error = ""
# Web builds have no worker threads. Keep the same single latest-snapshot queue
# and serialize its writer on an idle callback instead of invoking Thread.start.
var threaded_saves=not OS.has_feature("web")
var _idle_save_scheduled=false
var initial_settings: Dictionary = SaveStore.DEFAULT_PREFERENCES.duplicate(true)

func preferences() -> Dictionary:
	var result=initial_settings.duplicate(true)
	if not state.is_empty(): result.merge(state.settings,true)
	return result

func set_preference(key: String, value: Variant) -> bool:
	var candidate=preferences()
	if not candidate.has(key): return false
	candidate[key]=value
	if not store.valid_preferences(candidate): return false
	# An explicit settings transaction uses the same ordering as profile transactions.
	_join_save()
	if not state.is_empty():
		var next=state.duplicate(true)
		next.settings=candidate
		return commit(next)
	if not store.write_preferences(candidate):
		feedback.emit("Settings could not be saved. Please try again.")
		return false
	initial_settings=candidate
	changed.emit()
	return true

func _join_save() -> bool:
	if _save_thread==null: return true
	var okay=bool(_save_thread.wait_to_finish())
	_save_thread=null
	return okay

func _start_save() -> void:
	if _save_thread!=null or _pending_snapshot.is_empty() or _save_retry>0: return
	if not threaded_saves:
		if not _idle_save_scheduled:
			_idle_save_scheduled=true
			call_deferred("_write_idle_snapshot")
		return
	var snapshot=_pending_snapshot
	_pending_snapshot={}
	_save_thread=Thread.new()
	var error=_save_thread.start(store.write.bind(snapshot))
	if error!=OK:
		_save_thread=null
		_pending_snapshot=snapshot
		background_save_error="Saving needs another try. Your current progress is still here."
		_save_retry=3
		feedback.emit(background_save_error)

func _write_idle_snapshot() -> void:
	_idle_save_scheduled=false
	if _pending_snapshot.is_empty() or _save_retry>0: return
	var snapshot=_pending_snapshot
	_pending_snapshot={}
	if store.write(snapshot): background_save_error=""
	else:
		_pending_snapshot=snapshot
		background_save_error=store.last_error
		_save_retry=3
		feedback.emit(background_save_error)

func _poll_save(elapsed: float) -> void:
	_save_retry=maxf(0,_save_retry-elapsed)
	if _save_thread!=null and not _save_thread.is_alive():
		if _join_save(): background_save_error=""
		else:
			background_save_error=store.last_error
			if _pending_snapshot.is_empty(): _pending_snapshot=state.duplicate(true)
			_save_retry=3
			feedback.emit(background_save_error)
	_start_save()

func queue_save() -> bool:
	if state.is_empty(): return false
	# Only one write and one newest snapshot can exist. Pickup bursts cannot stack jobs.
	state.save_revision+=1
	_pending_snapshot=state.duplicate(true)
	_start_save()
	return true

func queue_checkpoint(run: Dictionary) -> bool:
	if state.is_empty(): return false
	state.pending_run=run.duplicate(true)
	changed.emit()
	return queue_save()

func pending_save_count() -> int:
	return (1 if _save_thread!=null else 0)+(0 if _pending_snapshot.is_empty() else 1)

func _exit_tree() -> void:
	var okay=_join_save()
	if not state.is_empty() and (not okay or not _pending_snapshot.is_empty()):
		store.write(state.duplicate(true))
	_pending_snapshot={}

func _init(folder: String = "user://profile") -> void:
	store = SaveStore.new(folder)

func _ready() -> void:
	load_game()
	_last_tick = float(clock_monotonic.call())

func load_game() -> void:
	if pending_save_count()>0 and not save(): return
	state = store.load_state()
	initial_settings=store.load_preferences()
	if not state.is_empty():
		PetRules.reconcile(state, clock_utc.call())
		commit(state.duplicate(true))

func _process(_delta: float) -> void:
	var tick = float(clock_monotonic.call())
	var elapsed = maxf(0.0,tick-_last_tick)
	_last_tick = tick
	_poll_save(elapsed)
	if state.is_empty() or suspended: return
	PetRules.apply_elapsed(pet(), elapsed, false)
	# Persist a monotonic time high-water mark, even during a wall-clock rollback.
	state.last_reconciled_utc = maxf(state.last_reconciled_utc + elapsed, clock_utc.call())
	save_timer += elapsed
	if save_timer >= 30.0:
		save_timer = 0.0
		queue_save()

func pet() -> Dictionary:
	return state.pets[0] if not state.is_empty() else {}

func adopt(name_value: String) -> bool:
	if store.blocked or not state.is_empty(): return false
	name_value = name_value.strip_edges().left(20)
	var candidate=PetRules.fresh(name_value if not name_value.is_empty() else "Foxy", clock_utc.call())
	candidate.settings=initial_settings.duplicate(true)
	return commit(candidate)

func commit(candidate: Dictionary) -> bool:
	# Transactions and explicit shutdown are ordered behind the single background writer.
	_join_save()
	candidate.save_revision=maxi(int(candidate.save_revision),int(state.get("save_revision",0)))+1
	if not store.write(candidate):
		feedback.emit(store.last_error)
		return false
	state = candidate
	_pending_snapshot={}
	background_save_error=""
	_save_retry=0
	changed.emit()
	return true

func save() -> bool:
	return commit(state.duplicate(true)) if not state.is_empty() else false

func suspend() -> void:
	if suspended: return
	suspended = true
	if not state.is_empty(): save()

func resume_from_background() -> void:
	if not suspended: return
	suspended = false
	_last_tick = float(clock_monotonic.call())
	if state.is_empty(): return
	var candidate = state.duplicate(true)
	PetRules.reconcile(candidate,clock_utc.call())
	commit(candidate)

func rename_pet(name_value: String) -> bool:
	name_value = name_value.strip_edges().left(20)
	if name_value.is_empty(): return false
	var candidate = state.duplicate(true)
	candidate.pets[0].name = name_value
	return commit(candidate)

func care(action: String) -> bool:
	if state.is_empty(): return false
	var s = state.duplicate(true)
	var p: Dictionary = s.pets[0]
	var message = ""
	match action:
		"feed":
			p.needs.fullness = minf(100.0, p.needs.fullness + 35.0)
			p.sleeping = false
			message = "%s loved that meal!" % p.name
		"clean":
			p.needs.cleanliness = minf(100.0, p.needs.cleanliness + 35.0)
			message = "Bubbles, a rinse, and a fluffy finish."
		"pet":
			p.needs.happiness = minf(100.0, p.needs.happiness + 15.0)
			message = "A little moment together."
		"water":
			p.needs.health = minf(100.0, p.needs.health + 20.0)
			message = "Fresh water. Feeling better!"
		"sleep":
			p.sleeping = not p.sleeping
			message = "Sweet dreams. You can keep exploring the menus." if p.sleeping else "Ready for a new day!"
		_:
			return false
	var now = float(clock_utc.call())
	if now - float(p.care_awards.get(action, -1000.0)) >= 30.0:
		p.bond_xp += 5
		p.care_xp += 5
		p.care_awards[action] = now
	if not commit(s): return false
	feedback.emit(message)
	return true

func purchase(item_id: String, transaction: String) -> bool:
	var item = ItemCatalog.find(item_id)
	if state.is_empty() or item == null: return false
	if transaction in state.claimed_event_ids: return false
	if state.coins < item.price:
		feedback.emit("A few more coins will get you there. Free care is always here.")
		return false
	if item.permanent and state.inventory.get(item_id, 0) > 0: return false
	var s = state.duplicate(true)
	s.coins -= item.price
	s.inventory[item_id] = int(s.inventory.get(item_id, 0)) + 1
	s.claimed_event_ids.append(transaction)
	if not commit(s): return false
	feedback.emit("A new little joy for your home!")
	return true

## --- A51 foods --------------------------------------------------------------
static var _foods: Dictionary={}
static func foods() -> Dictionary:
	if _foods.is_empty(): _foods=JSON.parse_string(FileAccess.get_file_as_string("res://data/foods.json"))
	return _foods
func food_count(id: String) -> int:
	return 999 if id=="kibble" else int(state.get("inventory",{}).get(id,0))
## "like", "dislike" or "".
func food_taste(id: String) -> String:
	var species: String=pet().species_id
	if id in foods().likes.get(species,[]): return "like"
	if id in foods().dislikes.get(species,[]): return "dislike"
	return ""
func buy_food(id: String) -> bool:
	var f: Dictionary=foods().foods.get(id,{})
	if f.is_empty() or int(f.price)<=0 or state.is_empty(): return false
	if state.coins<int(f.price):
		feedback.emit("A few more coins will get you there. Kibble is always free.")
		return false
	var s=state.duplicate(true)
	s.coins-=int(f.price)
	s.inventory[id]=int(s.inventory.get(id,0))+1
	return commit(s)
## Durable meal: uses one (kibble is free), applies effects and taste.
func feed_food(id: String) -> bool:
	var f: Dictionary=foods().foods.get(id,{})
	if f.is_empty() or state.is_empty() or food_count(id)<1: return false
	var s=state.duplicate(true)
	var p: Dictionary=s.pets[0]
	if id!="kibble": s.inventory[id]=int(s.inventory[id])-1
	var taste=food_taste(id)
	var happy=float(f.happiness)+(10.0 if taste=="like" else (-5.0 if taste=="dislike" else 0.0))
	p.needs.fullness=minf(100.0,p.needs.fullness+float(f.fullness))
	p.needs.happiness=clampf(p.needs.happiness+happy,0.0,100.0)
	p.needs.energy=minf(100.0,p.needs.energy+float(f.energy))
	p.sleeping=false
	var now=float(clock_utc.call())
	if now-float(p.care_awards.get("feed",-1000.0))>=30.0:
		p.bond_xp+=5+(3 if taste=="like" else 0)
		p.care_xp+=5
		p.care_awards["feed"]=now
	return commit(s)

func use_berries() -> bool:
	if state.inventory.get("berry_bowl", 0) < 1: return false
	var s = state.duplicate(true)
	s.inventory.berry_bowl -= 1
	s.pets[0].needs.fullness = minf(100.0, s.pets[0].needs.fullness + 35.0)
	s.pets[0].needs.happiness = minf(100.0, s.pets[0].needs.happiness + 10.0)
	return commit(s)

func place_toy(slot: int) -> bool:
	if slot not in [-1, 0, 1, 2] or state.inventory.get("ball_sun", 0) < 1: return false
	var s = state.duplicate(true)
	s.room_layout = [] if slot == -1 else [{"item_id": "ball_sun", "slot": slot}]
	return commit(s)

func equip_collar() -> bool:
	if state.inventory.get("blue_collar", 0) < 1: return false
	var s = state.duplicate(true)
	if s.pets[0].equipped_items.has("collar"):
		s.pets[0].equipped_items.erase("collar")
	else:
		s.pets[0].equipped_items.collar = "blue_collar"
	return commit(s)

func crate_counts(level_id: String) -> Dictionary:
	return state.get("quest_state",{}).get("crate_layouts",{}).get(level_id,{})

func crate_positions(level_id: String) -> Array[Vector2]:
	var points=TrailTools.legacy_positions(level_id,crate_counts(level_id))
	for point in state.get("quest_state",{}).get("free_crates",{}).get(level_id,[]):
		points.append(Vector2(point.x,point.y))
	return points

func available_crates() -> int:
	if state.is_empty(): return 0
	var placed=0
	for layout in state.quest_state.get("crate_layouts",{}).values():
		for count in layout.values(): placed+=int(count)
	for layout in state.quest_state.get("free_crates",{}).values(): placed+=layout.size()
	return int(state.inventory.get("trail_crate",0))-placed

func collect_trail_crates() -> bool:
	if "windmill_crates" in state.discovered_ids: return false
	state.inventory.trail_crate=3
	state.discovered_ids.append("windmill_crates")
	queue_save()
	feedback.emit("Three reusable crates in your bag! Open Bag to choose where to place them.")
	return true

func place_trail_crate_at(level_id: String, point: Vector2) -> bool:
	if available_crates()<=0:
		feedback.emit("No free crates. Pack placed crates to use them again.")
		return false
	var points=crate_positions(level_id)
	points.append(point)
	if not TrailTools.valid_positions(level_id,points):
		feedback.emit("The crate needs solid support and room around it.")
		return false
	var layouts=state.quest_state.get("free_crates",{}).duplicate(true)
	var positions=layouts.get(level_id,[]).duplicate(true)
	positions.append({"x":point.x,"y":point.y})
	layouts[level_id]=positions
	state.quest_state.free_crates=layouts
	queue_save()
	feedback.emit("Crate placed. Try jumping on it; you can pack it and try elsewhere.")
	return true

func pack_trail_crates() -> bool:
	if state.is_empty(): return false
	state.quest_state.crate_layouts={}
	state.quest_state.free_crates={}
	queue_save()
	feedback.emit("Placed crates packed safely back into your bag.")
	return true

func start_run(level_id: String = "W01_L01") -> Dictionary:
	if level_id not in ["W01_L01","W01_L02"]: return {}
	if not state.pending_run.is_empty() and state.pending_run.get("level_id","W01_L01")==level_id: return state.pending_run.duplicate(true)
	var s=state.duplicate(true)
	if not s.quest_state.has("level_runs"): s.quest_state.level_runs={}
	if not s.pending_run.is_empty(): s.quest_state.level_runs[s.pending_run.get("level_id","W01_L01")]=s.pending_run.duplicate(true)
	if s.quest_state.level_runs.has(level_id):
		s.pending_run=s.quest_state.level_runs[level_id].duplicate(true)
		s.quest_state.level_runs.erase(level_id)
	else:
		s.pending_run={"id":event_id(level_id),"level_id":level_id,"checkpoint":0,"pickups":[],"basket":false,"bridge":false,"secret":false,"cache_open":false,"gathered":[]}
	return s.pending_run.duplicate(true) if commit(s) else {}

func checkpoint(run: Dictionary) -> bool:
	var s = state.duplicate(true)
	s.pending_run = run.duplicate(true)
	return commit(s)

func finish_run(run: Dictionary) -> int:
	if state.pending_run.is_empty() or run.id != state.pending_run.id or not run.basket: return -1
	if run.id in state.claimed_event_ids: return -1
	var s = state.duplicate(true)
	var level_id=run.get("level_id","W01_L01")
	var coins = 50 + mini(run.pickups.size(), 20)
	var secret_id="windmill_secret" if level_id=="W01_L02" else "picnic_secret"
	var meals=2 if level_id=="W01_L02" else 1
	var discovery_coins=0
	if run.secret and run.get("cache_open",true) and not secret_id in s.discovered_ids:
		coins += 10
		discovery_coins=10
		s.discovered_ids.append(secret_id)
		if level_id=="W01_L02": meals+=1
	var keepsake="windmill_badge" if level_id=="W01_L02" else "picnic_sticker"
	var new_keepsake=not keepsake in s.discovered_ids
	if new_keepsake: s.discovered_ids.append(keepsake)
	if not level_id in s.completed_levels: s.completed_levels.append(level_id)
	s.inventory.berry_bowl=int(s.inventory.get("berry_bowl",0))+meals
	s.coins += coins
	s.pets[0].bond_xp += 15
	s.pets[0].needs.cleanliness = maxf(0.0, s.pets[0].needs.cleanliness - 10.0)
	s.claimed_event_ids.append(run.id)
	s.pending_run = {}
	s.quest_state.last_completion={"run_id":run.id,"level_id":level_id,"base_coins":50,"pickup_coins":mini(run.pickups.size(),20),"discovery_coins":discovery_coins,"total_coins":coins,"meals":meals,"bond":15,"keepsake":keepsake,"new_keepsake":new_keepsake,"wallet_after":s.coins}
	return coins if commit(s) else -1

## --- V2 connected world (Green Meadows). Progress lives in quest_state.world:
## {room, spawn, visited[], opened[], abilities[], coins[], parts{part_id:count}}.
const WORLD_FILE="res://data/world/green_meadows.json"
static var _world_data: Dictionary={}
static func world_data() -> Dictionary:
	if _world_data.is_empty(): _world_data=JSON.parse_string(FileAccess.get_file_as_string(WORLD_FILE))
	return _world_data
func world() -> Dictionary:
	var w: Dictionary=state.get("quest_state",{}).get("world",{})
	return {"room":w.get("room",world_data().start[0]),"spawn":w.get("spawn",world_data().start[1]),"visited":w.get("visited",[]),"opened":w.get("opened",[]),"abilities":w.get("abilities",[]),"coins":w.get("coins",[]),"parts":w.get("parts",{}),"dug":w.get("dug",[]),"crates":int(w.get("crates",0)),"placed":w.get("placed",{}),"lit":w.get("lit",[]),"checkpoint":w.get("checkpoint",{}),"carrots":int(w.get("carrots",0))}
## A one-time world switch (lever pulled, wall opened). Durable.
func world_flag(id: String) -> bool:
	var w=world()
	if id in w.opened: return false
	var s=state.duplicate(true)
	w=w.duplicate(true)
	w.opened.append(id)
	s.quest_state.world=w
	return commit(s)
## A51: exploring makes Foxy hungrier and more tired (per minute of play).
const WORLD_HUNGER_PER_MIN=1.0
const WORLD_TIRE_PER_MIN=1.4
const TIRED_AT=15.0
const HUNGRY_AT=15.0
var _world_save_timer=0.0
func world_tick(delta: float) -> void:
	if state.is_empty(): return
	var needs: Dictionary=state.pets[0].needs
	needs.fullness=maxf(0.0,needs.fullness-WORLD_HUNGER_PER_MIN*delta/60.0)
	needs.energy=maxf(0.0,needs.energy-WORLD_TIRE_PER_MIN*delta/60.0)
	_world_save_timer+=delta
	if _world_save_timer>10.0:
		_world_save_timer=0.0
		queue_save()
## Why Foxy can't help right now ("" when Foxy is fine).
func pet_too_weak() -> String:
	if state.is_empty(): return ""
	var needs: Dictionary=pet().needs
	if needs.fullness<HUNGRY_AT: return "hungry"
	if needs.energy<TIRED_AT: return "tired"
	return ""
## Before an adventure: a very hungry or tired Foxy stays home.
func pet_ready_for_adventure() -> String:
	if state.is_empty(): return ""
	var needs: Dictionary=pet().needs
	if pet().get("sleeping",false): return "sleeping"
	if needs.fullness<20.0: return "hungry"
	if needs.energy<20.0: return "tired"
	return ""
func world_feed(food: float, energy: float) -> void:
	if state.is_empty(): return
	var needs: Dictionary=state.pets[0].needs
	needs.fullness=minf(100.0,needs.fullness+food)
	needs.energy=minf(100.0,needs.energy+energy)
	queue_save()
	changed.emit()
func world_rest(amount: float) -> void:
	if state.is_empty(): return
	state.pets[0].needs.energy=minf(100.0,state.pets[0].needs.energy+amount)
	queue_save()
	changed.emit()

## Picnic quest finale: one durable reward (coins, a meal for the pet, bond).
func world_finish_picnic() -> bool:
	var w=world()
	if "picnic_done" in w.opened or not "picnic_basket" in w.opened: return false
	var s=state.duplicate(true)
	w=w.duplicate(true)
	w.opened.append("picnic_done")
	s.quest_state.world=w
	s.coins+=25
	s.inventory.berry_bowl=int(s.inventory.get("berry_bowl",0))+1
	s.pets[0].bond_xp+=10
	return commit(s)
func world_unflag(id: String) -> bool:
	var w=world()
	if not id in w.opened: return false
	var s=state.duplicate(true)
	w=w.duplicate(true)
	w.opened.erase(id)
	s.quest_state.world=w
	return commit(s)
## Start Green Meadows again: clears adventure progress only (pet, coins,
## inventory and settings stay).
func world_reset() -> bool:
	if state.is_empty(): return false
	var s=state.duplicate(true)
	s.quest_state.erase("world")
	return commit(s)
## Touching a lantern lights it and makes it the return point.
func world_light(room: String, index: int, point: Vector2) -> bool:
	var id="%s:%d"%[room,index]
	var w=world()
	if not id in w.lit: w.lit.append(id)
	w.checkpoint={"room":room,"x":roundf(point.x),"y":roundf(point.y)}
	state.quest_state.world=w
	queue_save()
	changed.emit()
	return true
const MAX_CRATES=3
## Crates carried in the bag (found by Foxy) minus those standing in rooms.
func world_crates_free() -> int:
	var w=world()
	var placed=0
	for room in w.placed: placed+=w.placed[room].size()
	return w.crates-placed
## Foxy digs up a hidden spot once: a crate for the bag or a few coins.
func world_dig(id: String, item: String) -> bool:
	var w=world()
	if id in w.dug: return false
	var s=state.duplicate(true)
	w=w.duplicate(true)
	w.dug.append(id)
	if item=="crate": w.crates=mini(MAX_CRATES,w.crates+1)
	else: s.coins+=5
	s.quest_state.world=w
	return commit(s)
func world_place_crate(room: String, point: Vector2) -> bool:
	if world_crates_free()<=0: return false
	var w=world().duplicate(true)
	if not w.placed.has(room): w.placed[room]=[]
	w.placed[room].append([roundf(point.x),roundf(point.y)])
	var s=state.duplicate(true)
	s.quest_state.world=w
	return commit(s)
func world_pick_crate(room: String, index: int) -> bool:
	var w=world().duplicate(true)
	if not w.placed.has(room) or index<0 or index>=w.placed[room].size(): return false
	w.placed[room].remove_at(index)
	if w.placed[room].is_empty(): w.placed.erase(room)
	var s=state.duplicate(true)
	s.quest_state.world=w
	return commit(s)
## Found food goes into the bag (apples and fish are bag snacks). Durable, once.
func world_pick_food(flag: String, food: String) -> bool:
	var w=world()
	if flag in w.opened: return false
	w=w.duplicate(true)
	w.opened.append(flag)
	var s=state.duplicate(true)
	s.inventory[food]=int(s.inventory.get(food,0))+1
	s.quest_state.world=w
	return commit(s)
## Jump carrots wait in the bag until you choose to eat one for a big jump.
const MAX_CARROTS=3
func world_add_carrot() -> bool:
	var w=world()
	if w.carrots>=MAX_CARROTS: return false
	w=w.duplicate(true)
	w.carrots+=1
	var s=state.duplicate(true)
	s.quest_state.world=w
	return commit(s)
func world_use_carrot() -> bool:
	var w=world()
	if w.carrots<=0: return false
	w=w.duplicate(true)
	w.carrots-=1
	var s=state.duplicate(true)
	s.quest_state.world=w
	return commit(s)
## Leaving a room: crates you placed come back into the bag, except ones
## holding a pressure plate down (keep lists their indices). Returns how many.
func world_collect_crates(room: String, keep: Array) -> int:
	var w=world().duplicate(true)
	var placed: Array=w.placed.get(room,[])
	if placed.is_empty(): return 0
	var stay=[]
	for i in placed.size():
		if i in keep: stay.append(placed[i])
	var back=placed.size()-stay.size()
	if back==0: return 0
	if stay.is_empty(): w.placed.erase(room)
	else: w.placed[room]=stay
	var s=state.duplicate(true)
	s.quest_state.world=w
	return back if commit(s) else 0
func has_ability(id: String) -> bool: return id in world().abilities
## Routine progress (room entry, coin pickup) goes through the background writer.
func world_enter(room: String, spawn: String) -> bool:
	if state.is_empty() or not world_data().rooms.has(room): return false
	var w=world()
	w.room=room
	w.spawn=spawn
	if not room in w.visited: w.visited.append(room)
	state.quest_state.world=w
	queue_save()
	changed.emit()
	return true
func world_collect_coin(room: String, index: int) -> bool:
	var id="%s:%d"%[room,index]
	var w=world()
	if id in w.coins: return false
	w.coins.append(id)
	state.quest_state.world=w
	state.coins+=1
	queue_save()
	changed.emit()
	return true
## Chests and abilities are durable transactions (never granted twice).
func world_open_chest(id: String, part: String) -> bool:
	var w=world()
	if id in w.opened or not world_data().parts.has(part): return false
	var s=state.duplicate(true)
	w=w.duplicate(true)
	w.opened.append(id)
	w.parts[part]=int(w.parts.get(part,0))+1
	s.quest_state.world=w
	s.coins+=10
	return commit(s)
func world_learn(ability: String) -> bool:
	var w=world()
	if ability in w.abilities or not world_data().abilities.has(ability): return false
	var s=state.duplicate(true)
	w=w.duplicate(true)
	w.abilities.append(ability)
	s.quest_state.world=w
	s.pets[0].bond_xp+=10
	return commit(s)

func minigame_result(session: String, catches: int, throws: int) -> bool:
	if throws < 3 or throws > 10 or catches < 0 or catches > throws or session in state.claimed_event_ids: return false
	var s = state.duplicate(true)
	s.pets[0].needs.happiness = minf(100.0, s.pets[0].needs.happiness + 10.0)
	s.pets[0].bond_xp += 5 + mini(catches, 5)
	s.claimed_event_ids.append(session)
	return commit(s)

static func event_id(prefix: String) -> String:
	return "%s_%s_%s" % [prefix, str(Time.get_unix_time_from_system()), str(Time.get_ticks_usec())]
