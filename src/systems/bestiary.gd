# Bestiary — per-monster encounter tracking (PRD "Bestiary", issue #12).
# Records seen/kill/capture counts, discovered drops, broken parts, and the
# monster's element/weakness as they're learned through play. Mutates a
# SaveManager state Dictionary's "bestiary" field (state["bestiary"][id]),
# the same pattern CaptureSystem uses for "captures" (#10), so it persists
# via #5 without a bespoke save path.
class_name Bestiary
extends RefCounted

# Returns `monster_id`'s entry in `state["bestiary"]`, creating it (and the
# "bestiary" Dictionary itself) with defaults if absent. Mutates and returns
# a reference into `state`, not a copy.
static func _entry(state: Dictionary, monster_id: String) -> Dictionary:
	if not state.has("bestiary"):
		state["bestiary"] = {}
	var bestiary: Dictionary = state["bestiary"]
	if not bestiary.has(monster_id):
		bestiary[monster_id] = {
			"seen": false,
			"kills": 0,
			"captures": 0,
			"defeated": false,
			"discovered_drops": [],
			"broken_parts": [],
			"element": "",
			"weakness": "",
		}
	return bestiary[monster_id]

# Read-only lookup. Returns a fresh default entry (not written to `state`) if
# `monster_id` has never been recorded.
static func get_entry(state: Dictionary, monster_id: String) -> Dictionary:
	var bestiary: Dictionary = state.get("bestiary", {})
	if bestiary.has(monster_id):
		return bestiary[monster_id]
	return {
		"seen": false, "kills": 0, "captures": 0, "defeated": false,
		"discovered_drops": [], "broken_parts": [], "element": "", "weakness": "",
	}

# Marks `monster` seen and records its element/weakness. Called on every
# encounter (win, loss, or capture) so element/weakness are learned even if
# the fight is never won.
static func record_encounter(state: Dictionary, monster: MonsterDef) -> Dictionary:
	var entry := _entry(state, monster.id)
	entry["seen"] = true
	entry["element"] = monster.element
	entry["weakness"] = Elements.weakness_of(monster.element)
	return entry

# Records a kill (win without capture): increments the kill counter.
static func record_kill(state: Dictionary, monster: MonsterDef) -> Dictionary:
	var entry := record_encounter(state, monster)
	entry["kills"] += 1
	entry["defeated"] = true
	return entry

# Records a successful capture: increments the capture counter. Captures are
# tracked separately from kills since CaptureSystem awards zero XP and takes
# the monster alive rather than defeating it.
static func record_capture(state: Dictionary, monster: MonsterDef) -> Dictionary:
	var entry := record_encounter(state, monster)
	entry["captures"] += 1
	return entry

# Adds any newly-seen material ids from `material_ids` to the entry's
# discovered-drops list (deduplicated, order of first discovery preserved).
static func record_drops(state: Dictionary, monster_id: String, material_ids: Array) -> Dictionary:
	var entry := _entry(state, monster_id)
	var discovered: Array = entry["discovered_drops"]
	for material_id in material_ids:
		if not discovered.has(material_id):
			discovered.append(material_id)
	return entry

# Adds any newly-broken part names from `parts` to the entry's broken-parts
# list (deduplicated).
static func record_broken_parts(state: Dictionary, monster_id: String, parts: Array) -> Dictionary:
	var entry := _entry(state, monster_id)
	var broken: Array = entry["broken_parts"]
	for part in parts:
		if not broken.has(part):
			broken.append(part)
	return entry
