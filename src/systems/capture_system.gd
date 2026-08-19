# CaptureSystem — trading a kill's XP for a live capture (PRD "Capture +
# companion passives", issue #10). Below a monster's capture_hp_threshold
# (MonsterDef, fraction of base_hp), spending a Trap consumable can capture
# it instead of finishing it off: grants a companion + material haul (reusing
# DropSystem's weighted table, plus any capture-only bonus materials) but
# awards ZERO XP. Captured species persist in the SaveManager state (#5) so a
# pre-run companion pick can apply its passive_skill for that run.
class_name CaptureSystem
extends RefCounted

const DEFAULT_TRAP_ID := "trap"

# True once `current_hp` has dropped to or below `monster`'s capture
# threshold (a fraction of its max HP). Non-capturable monsters never gate open.
static func is_capturable(monster: MonsterDef, current_hp: float, hp_max: float) -> bool:
	if not monster.capturable or hp_max <= 0.0:
		return false
	return current_hp / hp_max <= monster.capture_hp_threshold

# Attempts to capture `monster`. Consumes one `trap_id` from `inventory` on
# success only. Returns {"ok": bool, "error": String, "xp_awarded": float,
# "materials": Array, "monster_id": String}. `xp_awarded` is always 0.0 on
# success — capturing forfeits the kill's XP burst by design.
static func attempt_capture(monster: MonsterDef, current_hp: float, hp_max: float, inventory: Inventory, rng: RandomNumberGenerator, broken_parts: Array = [], trap_id: String = DEFAULT_TRAP_ID) -> Dictionary:
	if not is_capturable(monster, current_hp, hp_max):
		return {"ok": false, "error": "monster is above its capture HP threshold", "xp_awarded": 0.0, "materials": [], "monster_id": monster.id}

	if not inventory.remove_consumable(trap_id, 1):
		return {"ok": false, "error": "no trap available", "xp_awarded": 0.0, "materials": [], "monster_id": monster.id}

	var materials := DropSystem.roll(monster, broken_parts, rng)
	materials.append_array(monster.capture_only_materials)

	return {"ok": true, "error": "", "xp_awarded": 0.0, "materials": materials, "monster_id": monster.id}

# Records `monster_id` as a permanently captured species in a SaveManager
# state Dictionary (mutates and returns it). No-op if already recorded.
static func record_capture(state: Dictionary, monster_id: String) -> Dictionary:
	if not state.has("captures"):
		state["captures"] = []
	if not has_captured(state, monster_id):
		state["captures"].append({"monster_id": monster_id})
	return state

static func has_captured(state: Dictionary, monster_id: String) -> bool:
	for entry in state.get("captures", []):
		if entry.get("monster_id", "") == monster_id:
			return true
	return false

# Selects `companion`'s species as the pre-run companion (mutates and returns
# `state`). Rejects (no state change) if that species hasn't been captured.
static func select_companion(state: Dictionary, companion: CompanionDef) -> Dictionary:
	if not has_captured(state, companion.source_monster_id):
		return {"ok": false, "error": "species not captured"}
	state["selected_companion_id"] = companion.id
	return {"ok": true, "error": ""}

# Applies `companion`'s passive to `base_value` (e.g. an XP or drop amount).
# Unrecognized passive_skill ids pass the value through unchanged.
static func apply_passive(companion: CompanionDef, base_value: float) -> float:
	match companion.passive_skill:
		"xp_boost":
			return base_value * (1.0 + companion.passive_value)
		_:
			return base_value
