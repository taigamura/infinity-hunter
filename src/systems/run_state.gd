# RunState — drives one expedition: start at Lv.1 in a chosen zone with
# equipped gear, resolve fights from encounters (spending hunts, awarding
# XP), and end the run by banking (retreat / hunt exhaustion) or dying
# (forfeit unbanked haul; crafted/equipped gear is never touched here since
# it isn't part of the run's haul state).
#
# Win/loss here is authoritative from the caller-supplied `combat_outcome`
# (the reflex-phase HP-race result from the combat screen) when present;
# it falls back to a level-power comparison (power_scaling) when no outcome
# is supplied, e.g. headless/test callers that skip the reflex minigame.
class_name RunState
extends RefCounted

const DEFAULT_HUNTS := 10.0
# Stub haul rule: essence earned per XP awarded this run. Tunable.
const ESSENCE_PER_XP := 0.5

var level: float = 1.0 # Big
var xp_carry: float = 0.0 # Big
var hunts_max: float = DEFAULT_HUNTS # Big
var hunts_remaining: float = DEFAULT_HUNTS # Big
var zone_id: String = ""
var equipped_weapon_id: String = ""
var equipped_armor_ids: Dictionary = {} # slot -> armor id
var unlocked_zone_ids: Array = []

var status: String = "active" # active | banked | dead
var end_reason: String = "" # "" | retreat | hunt_exhaustion | death

var essence_unbanked: float = 0.0 # Big
var essence_banked: float = 0.0 # Big
var materials_unbanked: Dictionary = {} # material_id -> int count
var materials_banked: Dictionary = {} # material_id -> int count

static func start(zone_id: String, equipped_weapon_id: String = "", equipped_armor_ids: Dictionary = {}, hunts_max: float = DEFAULT_HUNTS) -> RunState:
	var run := RunState.new()
	run.level = 1.0
	run.xp_carry = 0.0
	run.hunts_max = hunts_max
	run.hunts_remaining = hunts_max
	run.zone_id = zone_id
	run.equipped_weapon_id = equipped_weapon_id
	run.equipped_armor_ids = equipped_armor_ids
	run.unlocked_zone_ids = [zone_id]
	run.status = "active"
	return run

# Resolves a fight against `monster`. Spends 1 hunt. On win, awards XP
# (possibly crossing several level thresholds), rolls `monster`'s drop table
# (boosted/guaranteed per `broken_parts`, see DropSystem) and adds the
# result to the unbanked haul. On loss the run ends in death and the
# unbanked haul (including any materials from this call) is forfeited.
# Auto-banks on hunt exhaustion. Returns a result Dictionary.
#
# `rng` is caller-supplied for deterministic drop rolls in tests; defaults to
# a fresh RandomNumberGenerator (unseeded, real randomness) otherwise.
# `armor_skill_profile` is an optional SkillSystem.build_profile() effects
# Dictionary from the run's equipped armor (issue #9); its "xp_mult_bonus"
# scales the XP awarded on a win.
func resolve_fight(monster: MonsterDef, broken_parts: Array = [], rng: RandomNumberGenerator = null, armor_skill_profile: Dictionary = {}, combat_outcome: Dictionary = {}) -> Dictionary:
	assert(status == "active", "cannot fight after the run has ended")
	hunts_remaining -= 1.0
	var won: bool
	if combat_outcome.has("won"):
		won = combat_outcome["won"]
	else:
		var player_power := XpCurve.power_scaling(level)
		var monster_power := XpCurve.power_scaling(monster.level)
		won = player_power >= monster_power
	var result := {"won": won, "died": false, "levels_gained": 0, "xp_awarded": 0.0, "materials_dropped": []}

	if not won:
		_end_run("death")
		result["died"] = true
		return result

	var level_before := level
	var carry_before := xp_carry
	var xp_mult_bonus: float = armor_skill_profile.get("xp_mult_bonus", 0.0)
	var scaled_reward := XpCurve.gap_scaled_reward(monster.xp_reward, level, monster.level)
	var xp_result := XpCurve.award_xp(level, xp_carry, scaled_reward, xp_mult_bonus)
	level = xp_result["level"]
	xp_carry = xp_result["xp_carry"]
	result["levels_gained"] = xp_result["levels_gained"]
	result["xp_awarded"] = scaled_reward
	result["level_before"] = level_before
	result["xp_carry_before"] = carry_before
	result["level_after"] = level
	result["xp_carry_after"] = xp_carry
	essence_unbanked += monster.xp_reward * ESSENCE_PER_XP

	var roll_rng := rng if rng != null else RandomNumberGenerator.new()
	var drops := DropSystem.roll(monster, broken_parts, roll_rng)
	for material_id in drops:
		add_material_haul(material_id, 1)
	result["materials_dropped"] = drops

	if hunts_remaining <= 0.0:
		_end_run("hunt_exhaustion")
	return result

# Adds `count` of `material_id` to this run's unbanked haul (capture/loot
# systems call this; kept generic since drop tables aren't this issue's scope).
func add_material_haul(material_id: String, count: int) -> void:
	materials_unbanked[material_id] = materials_unbanked.get(material_id, 0) + count

func retreat() -> void:
	assert(status == "active", "cannot retreat after the run has ended")
	_end_run("retreat")

# Marks `target_zone_id` unlocked as a future launch option and moves the
# run there (travel-deeper node resolution).
func unlock_zone(target_zone_id: String) -> void:
	if not unlocked_zone_ids.has(target_zone_id):
		unlocked_zone_ids.append(target_zone_id)
	zone_id = target_zone_id

func _end_run(reason: String) -> void:
	end_reason = reason
	if reason == "death":
		status = "dead"
		essence_unbanked = 0.0
		materials_unbanked.clear()
		return
	status = "banked"
	essence_banked += essence_unbanked
	essence_unbanked = 0.0
	for material_id in materials_unbanked:
		materials_banked[material_id] = materials_banked.get(material_id, 0) + materials_unbanked[material_id]
	materials_unbanked.clear()
