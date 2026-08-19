# CombatResolver — real-time dodge/attack HP-race as pure logic (design doc /
# PRD "Combat model"). The monster attacks back every round the player
# doesn't stun it; the player's HP drains. Dodge timing reduces most of a
# monster hit, but a chip floor proportional to the monster's power always
# lands, so a vastly stronger monster is unwinnable regardless of dodge
# skill. Weapon class modulates the player's own damage/meter behavior.
#
# Outcomes are deterministic given stats + a fixed sequence of per-round
# dodge-input timings, so this is unit-testable independent of rendering.
class_name CombatResolver
extends RefCounted

# Fraction of a monster hit's damage that is unavoidable regardless of dodge.
const CHIP_FLOOR_FRACTION := 0.35

# Dodge-input timing windows, in seconds of offset from the perfect instant.
const DODGE_PERFECT_WINDOW := 0.1
const DODGE_GOOD_WINDOW := 0.3
const DODGE_GOOD_REDUCTION := 0.5 # fraction of reducible damage removed on a "good" dodge

# Great Sword: slow hits, big charged burst every Nth attack.
const GREAT_SWORD_CHARGE_INTERVAL := 3
const GREAT_SWORD_CHARGE_MULT := 2.5
const GREAT_SWORD_NORMAL_MULT := 0.8

# Dual Blades: rapid weak hits that build a demon meter for a burst hit.
const DUAL_BLADES_HIT_MULT := 0.55
const DUAL_BLADES_METER_MAX := 4
const DUAL_BLADES_DEMON_MULT := 1.8

# Hammer: heavy hits that build a stagger bar; the staggering hit stuns the
# monster (it skips its next attack) and deals bonus damage.
const HAMMER_HIT_MULT := 1.3
const HAMMER_STAGGER_MAX := 3
const HAMMER_STUN_BONUS_MULT := 1.5

# Resolves one full HP-race exchange.
#
# player: {hp_max: float, power: float}
# monster: {hp_max: float, power: float, element: String}
# weapon: {weapon_class: String, element: String, base_damage: float}
# beats: Array of per-round Dictionaries, each optionally holding
#   "dodge_timing" (absolute seconds offset from the perfect-dodge instant
#   for that round's monster attack; omitted/large == a missed dodge).
#
# Returns {"won": bool, "rounds": int, "player_hp": float, "monster_hp": float}.
static func resolve(player: Dictionary, monster: Dictionary, weapon: Dictionary, beats: Array) -> Dictionary:
	var player_hp: float = player["hp_max"]
	var monster_hp: float = monster["hp_max"]
	var weapon_state := {"charge_count": 0, "demon_meter": 0, "stagger": 0}
	var monster_stunned := false
	var rounds := 0

	for beat in beats:
		rounds += 1
		if player_hp <= 0.0 or monster_hp <= 0.0:
			break

		var atk := _weapon_attack(weapon["weapon_class"], weapon["base_damage"], weapon_state)
		var elem_mult := Elements.multiplier(weapon["element"], monster["element"])
		monster_hp -= atk["damage"] * elem_mult
		if atk["stun"]:
			monster_stunned = true

		if monster_hp <= 0.0:
			break

		if monster_stunned:
			monster_stunned = false
			continue

		var timing: float = absf(beat.get("dodge_timing", INF))
		player_hp -= _monster_damage(monster["power"], timing)

	return {
		"won": monster_hp <= 0.0 and player_hp > 0.0,
		"rounds": rounds,
		"player_hp": maxf(player_hp, 0.0),
		"monster_hp": maxf(monster_hp, 0.0),
	}

static func _monster_damage(monster_power: float, dodge_timing: float) -> float:
	var raw := monster_power
	var chip := raw * CHIP_FLOOR_FRACTION
	var reducible := raw - chip
	var reduction := 0.0
	if dodge_timing <= DODGE_PERFECT_WINDOW:
		reduction = 1.0
	elif dodge_timing <= DODGE_GOOD_WINDOW:
		reduction = DODGE_GOOD_REDUCTION
	return chip + reducible * (1.0 - reduction)

static func _weapon_attack(weapon_class: String, base_damage: float, state: Dictionary) -> Dictionary:
	match weapon_class:
		"great_sword":
			return _great_sword_attack(base_damage, state)
		"dual_blades":
			return _dual_blades_attack(base_damage, state)
		"hammer":
			return _hammer_attack(base_damage, state)
		_:
			return {"damage": base_damage, "stun": false}

static func _great_sword_attack(base_damage: float, state: Dictionary) -> Dictionary:
	state["charge_count"] += 1
	if state["charge_count"] >= GREAT_SWORD_CHARGE_INTERVAL:
		state["charge_count"] = 0
		return {"damage": base_damage * GREAT_SWORD_CHARGE_MULT, "stun": false}
	return {"damage": base_damage * GREAT_SWORD_NORMAL_MULT, "stun": false}

static func _dual_blades_attack(base_damage: float, state: Dictionary) -> Dictionary:
	state["demon_meter"] += 1
	if state["demon_meter"] >= DUAL_BLADES_METER_MAX:
		state["demon_meter"] = 0
		return {"damage": base_damage * DUAL_BLADES_HIT_MULT * DUAL_BLADES_DEMON_MULT, "stun": false}
	return {"damage": base_damage * DUAL_BLADES_HIT_MULT, "stun": false}

static func _hammer_attack(base_damage: float, state: Dictionary) -> Dictionary:
	state["stagger"] += 1
	if state["stagger"] >= HAMMER_STAGGER_MAX:
		state["stagger"] = 0
		return {"damage": base_damage * HAMMER_HIT_MULT * HAMMER_STUN_BONUS_MULT, "stun": true}
	return {"damage": base_damage * HAMMER_HIT_MULT, "stun": false}
