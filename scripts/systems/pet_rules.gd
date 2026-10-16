class_name PetRules
extends RefCounted
## Pure rules: elapsed age is independent of recoverable, capped need decay.

const DAY = 86400.0
const STAGES = ["baby", "child", "teen", "adult"]
const THRESHOLDS = [0.0, 7.0 * DAY, 30.0 * DAY, 60.0 * DAY]
const DECAY = {"fullness": 3.0, "happiness": 2.0, "energy": 1.0, "cleanliness": 2.0}

static func apply_elapsed(pet: Dictionary, seconds: float, offline: bool) -> void:
	seconds = maxf(seconds, 0.0)
	pet.elapsed_age_seconds += seconds
	var hours = minf(seconds, 12.0 * 3600.0) / 3600.0 if offline else seconds / 3600.0
	for key in DECAY:
		if key=="energy" and pet.get("sleeping",false): continue
		var floor_value = minf(float(pet.needs[key]), 30.0) if offline else 0.0
		pet.needs[key] = maxf(floor_value, float(pet.needs[key]) - DECAY[key] * hours)
	if pet.get("sleeping", false):
		pet.needs.energy = minf(100.0, pet.needs.energy + minf(seconds, 3600.0) / 30.0)
	var stage = 0
	for i in range(THRESHOLDS.size()):
		if pet.elapsed_age_seconds >= THRESHOLDS[i]: stage = i
	pet.growth_stage = STAGES[maxi(stage, STAGES.find(pet.growth_stage))]

static func reconcile(state: Dictionary, utc: float) -> void:
	var elapsed = maxf(utc - float(state.last_reconciled_utc), 0.0)
	for pet in state.pets: apply_elapsed(pet, elapsed, true)
	state.last_reconciled_utc = maxf(utc, float(state.last_reconciled_utc))

static func fresh(name_value: String, utc: float) -> Dictionary:
	return {
		"schema_version": 1, "save_revision": 0, "last_reconciled_utc": utc,
		"coins": 0, "active_pet_id": "pet_001", "child_appearance": "meadow",
		"pets": [{"pet_id": "pet_001", "species_id": "foxy", "name": name_value,
			"adopted_at_utc": utc, "elapsed_age_seconds": 0.0, "growth_stage": "baby",
			"care_xp": 0, "bond_xp": 0, "training": {}, "equipped_items": {},
			"sleeping": false, "care_awards": {},
			"needs": {"fullness": 80.0, "happiness": 85.0, "energy": 80.0, "cleanliness": 90.0, "health": 100.0}}],
		"inventory": {}, "completed_levels": [], "discovered_ids": [], "claimed_event_ids": [],
		"room_layout": [], "quest_state": {}, "pending_run": {},
		"settings": {"reduced_motion": false, "sound": true}}
