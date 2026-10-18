class_name SaveStore
extends RefCounted
## Atomic snapshots. GameState serializes background and transaction writers.

var directory: String
var last_error = ""
var recovered = false
var blocked = false

const DEFAULT_PREFERENCES = {"reduced_motion":false,"sound":true,"music":true,"touch_size":60,"touch_spacing":12,"touch_raise":0}

func valid_preferences(value: Variant) -> bool:
	if not value is Dictionary or value.size()!=DEFAULT_PREFERENCES.size(): return false
	for key in DEFAULT_PREFERENCES:
		if not value.has(key): return false
	if not value.reduced_motion is bool or not value.sound is bool or not value.music is bool: return false
	for key in ["touch_size","touch_spacing","touch_raise"]:
		if not _number(value[key]) or value[key]!=floor(value[key]): return false
	return int(value.touch_size) in [52,60,68] and int(value.touch_spacing) in [0,12,24] and int(value.touch_raise) in [0,16,32]

func load_preferences() -> Dictionary:
	var path=directory.path_join("preferences.json")
	if FileAccess.file_exists(path):
		var value=JSON.parse_string(FileAccess.get_file_as_string(path))
		# Settings saved before the Music option keep working.
		if value is Dictionary and not value.has("music"): value.music=true
		if valid_preferences(value): return value
	return DEFAULT_PREFERENCES.duplicate(true)

func write_preferences(value: Dictionary) -> bool:
	if not valid_preferences(value): return false
	var temporary=directory.path_join("preferences.tmp")
	var file=FileAccess.open(temporary,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(value))
	file.flush()
	var okay=file.get_error()==OK
	file.close()
	if not okay or not valid_preferences(JSON.parse_string(FileAccess.get_file_as_string(temporary))): return false
	return DirAccess.rename_absolute(temporary,directory.path_join("preferences.json"))==OK

func _init(folder: String = "user://profile") -> void:
	directory = folder
	DirAccess.make_dir_recursive_absolute(directory)

func validate(value: Variant) -> bool:
	if not value is Dictionary: return false
	var s: Dictionary = value
	for key in ["schema_version", "save_revision", "last_reconciled_utc", "coins", "active_pet_id", "pets", "inventory", "completed_levels", "discovered_ids", "claimed_event_ids", "room_layout", "settings", "pending_run", "quest_state"]:
		if not s.has(key): return false
	if s.schema_version != 1 or not _number(s.coins) or s.coins < 0 or s.coins != floor(s.coins): return false
	if not _number(s.save_revision) or s.save_revision < 0 or not _number(s.last_reconciled_utc): return false
	if not s.pets is Array or s.pets.size() != 1 or not s.pets[0] is Dictionary: return false
	var p: Dictionary = s.pets[0]
	for key in ["pet_id", "species_id", "name", "growth_stage", "elapsed_age_seconds", "adopted_at_utc", "needs", "bond_xp", "care_xp", "sleeping", "care_awards", "training", "equipped_items"]:
		if not p.has(key): return false
	if p.pet_id != s.active_pet_id or p.species_id != "foxy" or not p.name is String or p.name.length() < 1 or p.name.length() > 20: return false
	if not p.growth_stage in PetRules.STAGES or not _number(p.elapsed_age_seconds) or p.elapsed_age_seconds < 0: return false
	if not _number(p.adopted_at_utc) or not _number(p.bond_xp) or p.bond_xp < 0 or not _number(p.care_xp) or p.care_xp < 0: return false
	if not p.needs is Dictionary or not p.care_awards is Dictionary or not p.training is Dictionary or not p.equipped_items is Dictionary or not p.sleeping is bool: return false
	for key in ["fullness", "happiness", "energy", "cleanliness", "health"]:
		if not p.needs.has(key) or not _number(p.needs[key]) or p.needs[key] < 0 or p.needs[key] > 100: return false
	for key in ["inventory", "pending_run", "quest_state", "settings"]:
		if not s[key] is Dictionary: return false
	for key in ["reduced_motion", "sound"]:
		if not s.settings.get(key) is bool: return false
	if s.settings.has("music") and not s.settings.music is bool: return false
	for key in ["touch_size","touch_spacing","touch_raise"]:
		if s.settings.has(key):
			var options=[52,60,68] if key=="touch_size" else ([0,12,24] if key=="touch_spacing" else [0,16,32])
			if not _number(s.settings[key]) or s.settings[key]!=int(s.settings[key]) or not int(s.settings[key]) in options: return false
	for key in p.care_awards:
		if not _number(p.care_awards[key]): return false
	for key in ["completed_levels", "discovered_ids", "claimed_event_ids", "room_layout"]:
		if not s[key] is Array: return false
	for key in s.inventory:
		if not key in ["ball_sun", "berry_bowl", "blue_collar", "trail_crate", "apple", "fish_treat", "honey_cookie", "carrot"] or not _number(s.inventory[key]) or s.inventory[key] < 0: return false
	for key in ["completed_levels", "discovered_ids", "claimed_event_ids"]:
		for entry in s[key]:
			if not entry is String: return false
	for entry in s.room_layout:
		if not entry is Dictionary or entry.get("item_id") != "ball_sun": return false
		var slot: Variant = entry.get("slot", -1)
		if not _number(slot) or slot != floor(slot) or slot < 0 or slot > 2: return false
	var layouts=s.quest_state.get("crate_layouts",{})
	if not layouts is Dictionary: return false
	var placed=0
	for level_id in layouts:
		if level_id not in ["W01_L01","W01_L02"] or not layouts[level_id] is Dictionary: return false
		for slot in layouts[level_id]:
			var count=layouts[level_id][slot]
			if slot not in ["0","1"] or not _number(count) or count!=floor(count) or count<0 or count>2: return false
			placed+=int(count)
	var free_layouts=s.quest_state.get("free_crates",{})
	if not free_layouts is Dictionary:return false
	for level_id in free_layouts:
		if level_id not in ["W01_L01","W01_L02"] or not free_layouts[level_id] is Array or free_layouts[level_id].size()>3:return false
		var positions=TrailTools.legacy_positions(level_id,layouts.get(level_id,{}))
		for point in free_layouts[level_id]:
			if not point is Dictionary or not _number(point.get("x")) or not _number(point.get("y")):return false
			positions.append(Vector2(point.x,point.y))
		if not TrailTools.valid_positions(level_id,positions):return false
		placed+=free_layouts[level_id].size()
	var owned=s.inventory.get("trail_crate",0)
	if owned!=floor(owned) or owned>3 or placed>owned: return false
	if s.quest_state.has("last_completion"):
		var reward=s.quest_state.last_completion
		if not reward is Dictionary:return false
		for key in ["run_id","level_id","keepsake"]:
			if not reward.get(key) is String:return false
		if not reward.run_id in s.claimed_event_ids or not reward.level_id in s.completed_levels:return false
		for key in ["base_coins","pickup_coins","discovery_coins","total_coins","meals","bond","wallet_after"]:
			if not _number(reward.get(key)) or reward[key]!=floor(reward[key]) or reward[key]<0:return false
		if reward.base_coins!=50 or reward.pickup_coins>20 or not int(reward.discovery_coins) in [0,10] or reward.total_coins!=50+reward.pickup_coins+reward.discovery_coins:return false
		if reward.meals<1 or reward.meals>3 or reward.bond!=15 or not reward.get("new_keepsake") is bool:return false
		if not reward.keepsake in ["picnic_sticker","windmill_badge"]:return false
	if s.quest_state.has("world") and not _valid_world(s.quest_state.world): return false
	if not _valid_run(s.pending_run): return false
	var archived=s.quest_state.get("level_runs",{})
	if not archived is Dictionary: return false
	for level_id in archived:
		if level_id not in ["W01_L01","W01_L02"] or not _valid_run(archived[level_id]): return false
		if archived[level_id].get("level_id","W01_L01")!=level_id: return false
	return true

func _valid_world(w: Variant) -> bool:
	if not w is Dictionary: return false
	var data: Dictionary=GameState.world_data()
	if not w.get("room") is String or not data.rooms.has(w.room) or not w.get("spawn") is String: return false
	for key in ["visited","opened","abilities","coins"]:
		if not w.get(key) is Array: return false
		for entry in w[key]:
			if not entry is String: return false
	for room in w.visited:
		if not data.rooms.has(room): return false
	for ability in w.abilities:
		if not data.abilities.has(ability): return false
	if w.has("lit"):
		if not w.lit is Array: return false
		for entry in w.lit:
			if not entry is String: return false
	if w.has("checkpoint"):
		var c=w.checkpoint
		if not c is Dictionary: return false
		if not c.is_empty() and (not c.get("room") is String or not data.rooms.has(c.room) or not _number(c.get("x")) or not _number(c.get("y"))): return false
	if w.has("dug"):
		if not w.dug is Array: return false
		for entry in w.dug:
			if not entry is String: return false
	var carrots=w.get("carrots",0)
	if not _number(carrots) or carrots!=floor(carrots) or carrots<0 or carrots>GameState.MAX_CARROTS: return false
	var crates=w.get("crates",0)
	if not _number(crates) or crates!=floor(crates) or crates<0 or crates>GameState.MAX_CRATES: return false
	var placed=w.get("placed",{})
	if not placed is Dictionary: return false
	var standing=0
	for room in placed:
		if not data.rooms.has(room) or not placed[room] is Array: return false
		for point in placed[room]:
			if not point is Array or point.size()!=2 or not _number(point[0]) or not _number(point[1]): return false
			standing+=1
	if standing>crates: return false
	if not w.get("parts") is Dictionary: return false
	for part in w.parts:
		if not data.parts.has(part) or not _number(w.parts[part]) or w.parts[part]!=floor(w.parts[part]) or w.parts[part]<0: return false
	return true

func _valid_run(value: Variant) -> bool:
	if not value is Dictionary: return false
	if value.is_empty(): return true
	for key in ["id","checkpoint","pickups","basket","bridge","secret"]:
		if not value.has(key): return false
	if value.has("cache_open") and not value.cache_open is bool:return false
	var level_id=value.get("level_id","W01_L01")
	if level_id not in ["W01_L01","W01_L02"]: return false
	var gathered=value.get("gathered",[])
	if not gathered is Array or gathered.size()>3: return false
	var unique=[]
	for index in gathered:
		if not _number(index) or index!=floor(index) or index<0 or index>2 or index in unique: return false
		unique.append(index)
	if not value.id is String or not value.pickups is Array: return false
	var checkpoint: Variant=value.checkpoint
	if not _number(checkpoint) or checkpoint!=floor(checkpoint) or checkpoint<0 or checkpoint>(2 if level_id=="W01_L02" else 1): return false
	for key in ["basket","bridge","secret"]:
		if not value[key] is bool: return false
	for id in value.pickups:
		if not _number(id) or id!=floor(id) or id<0 or id>19: return false
	return true

func _normalize_run(value: Dictionary) -> void:
	if value.is_empty(): return
	value.checkpoint=int(value.checkpoint)
	value.pickups=value.pickups.map(func(id): return int(id))
	if value.has("gathered"): value.gathered=value.gathered.map(func(id): return int(id))

func _number(v: Variant) -> bool:
	return (v is int or v is float) and is_finite(float(v))

func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null: return {}
	var parser = JSON.new()
	if parser.parse(f.get_as_text()) != OK: return {}
	var parsed: Variant = parser.data
	if not validate(parsed): return {}
	# JSON numbers decode as floats. Stable discrete IDs need integer normalization.
	parsed.coins = int(parsed.coins)
	parsed.save_revision = int(parsed.save_revision)
	for key in parsed.inventory: parsed.inventory[key] = int(parsed.inventory[key])
	for entry in parsed.room_layout: entry.slot = int(entry.slot)
	_normalize_run(parsed.pending_run)
	for run in parsed.quest_state.get("level_runs",{}).values(): _normalize_run(run)
	return parsed

func load_state() -> Dictionary:
	last_error = ""
	var primary = directory.path_join("save.json")
	var state = _read(primary)
	if not state.is_empty(): return state
	var backup = _read(directory.path_join("save.backup.json"))
	if not backup.is_empty():
		recovered = true
		if FileAccess.file_exists(primary):
			DirAccess.copy_absolute(primary, primary + ".unreadable-" + str(Time.get_ticks_usec()))
		return backup
	blocked = FileAccess.file_exists(primary) or FileAccess.file_exists(directory.path_join("save.backup.json"))
	if blocked: last_error = "Your save needs attention. Your files are safe. Retry loading to continue."
	return {}

func write(state: Dictionary) -> bool:
	last_error = ""
	if not validate(state):
		last_error = "Progress could not be validated. The last saved moment is safe."
		return false
	var primary = directory.path_join("save.json")
	var temp = directory.path_join("save.tmp")
	var f = FileAccess.open(temp, FileAccess.WRITE)
	if f == null:
		last_error = "We couldn't save. Check available storage and try again."
		return false
	f.store_string(JSON.stringify(state, "\t"))
	f.flush()
	var write_error = f.get_error()
	f.close()
	if write_error != OK or _read(temp).is_empty():
		last_error = "The save could not be verified. Please try again."
		return false
	if not _read(primary).is_empty():
		if DirAccess.copy_absolute(primary, directory.path_join("save.backup.json")) != OK:
			last_error = "Backup failed. Please try again."
			return false
	if DirAccess.rename_absolute(temp, primary) != OK:
		last_error = "Could not finish saving. The previous save is safe."
		return false
	blocked = false
	return true
