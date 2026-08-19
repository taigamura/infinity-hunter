extends "res://tests/test_case.gd"

const CombatResolver = preload("res://src/systems/combat_resolver.gd")

func _weapon(weapon_class: String, element: String = "neutral", base_damage: float = 100.0) -> Dictionary:
	return {"weapon_class": weapon_class, "element": element, "base_damage": base_damage}

func _perfect_dodges(count: int) -> Array:
	var beats: Array = []
	for i in count:
		beats.append({"dodge_timing": 0.0})
	return beats

func test_equal_power_is_winnable_with_perfect_dodge() -> void:
	var player := {"hp_max": 1000.0, "power": 100.0}
	var monster := {"hp_max": 1000.0, "power": 100.0, "element": "neutral"}
	var result := CombatResolver.resolve(player, monster, _weapon("test_sword"), _perfect_dodges(20))
	assert_true(result["won"], "equal power + perfect dodge should win")
	assert_gt(result["player_hp"], 0.0)

func test_monster_3x_power_is_unwinnable_even_with_perfect_dodge() -> void:
	var player := {"hp_max": 1000.0, "power": 100.0}
	var monster := {"hp_max": 3000.0, "power": 300.0, "element": "neutral"}
	var result := CombatResolver.resolve(player, monster, _weapon("test_sword"), _perfect_dodges(40))
	assert_false(result["won"], "chip floor from a 3x power monster should be lethal despite perfect dodging")
	assert_eq(result["player_hp"], 0.0)

func test_missed_dodge_takes_full_damage() -> void:
	var player := {"hp_max": 10000.0, "power": 100.0}
	var monster := {"hp_max": 10000.0, "power": 100.0, "element": "neutral"}
	var result := CombatResolver.resolve(player, monster, _weapon("test_sword"), [{}])
	# one round: monster power 100, no reduction -> full 100 damage taken
	assert_almost_eq(result["player_hp"], 10000.0 - 100.0)

func test_perfect_dodge_only_takes_chip_floor() -> void:
	var player := {"hp_max": 10000.0, "power": 100.0}
	var monster := {"hp_max": 10000.0, "power": 100.0, "element": "neutral"}
	var result := CombatResolver.resolve(player, monster, _weapon("test_sword"), [{"dodge_timing": 0.0}])
	assert_almost_eq(result["player_hp"], 10000.0 - (100.0 * CombatResolver.CHIP_FLOOR_FRACTION))

func test_good_dodge_partially_reduces_damage() -> void:
	var player := {"hp_max": 10000.0, "power": 100.0}
	var monster := {"hp_max": 10000.0, "power": 100.0, "element": "neutral"}
	var result := CombatResolver.resolve(player, monster, _weapon("test_sword"), [{"dodge_timing": 0.2}])
	var chip := 100.0 * CombatResolver.CHIP_FLOOR_FRACTION
	var reducible := 100.0 - chip
	var expected_damage := chip + reducible * (1.0 - CombatResolver.DODGE_GOOD_REDUCTION)
	assert_almost_eq(result["player_hp"], 10000.0 - expected_damage)

func test_great_sword_charges_burst_every_third_hit() -> void:
	var player := {"hp_max": 100000.0, "power": 1.0}
	var monster := {"hp_max": 100000.0, "power": 1.0, "element": "neutral"}
	# use only stunless, undodgeable-irrelevant rounds; inspect monster_hp deltas
	var w := _weapon("great_sword", "neutral", 100.0)
	var r1 := CombatResolver.resolve(player, monster, w, _perfect_dodges(1))
	var r2 := CombatResolver.resolve(player, monster, w, _perfect_dodges(2))
	var r3 := CombatResolver.resolve(player, monster, w, _perfect_dodges(3))
	var dmg1: float = 100000.0 - r1["monster_hp"]
	var dmg2: float = (100000.0 - r2["monster_hp"]) - dmg1
	var dmg3: float = (100000.0 - r3["monster_hp"]) - dmg1 - dmg2
	assert_almost_eq(dmg1, 100.0 * CombatResolver.GREAT_SWORD_NORMAL_MULT)
	assert_almost_eq(dmg2, 100.0 * CombatResolver.GREAT_SWORD_NORMAL_MULT)
	assert_almost_eq(dmg3, 100.0 * CombatResolver.GREAT_SWORD_CHARGE_MULT)

func test_dual_blades_demon_meter_bursts_on_fourth_hit() -> void:
	var player := {"hp_max": 100000.0, "power": 1.0}
	var monster := {"hp_max": 100000.0, "power": 1.0, "element": "neutral"}
	var w := _weapon("dual_blades", "neutral", 100.0)
	var r3 := CombatResolver.resolve(player, monster, w, _perfect_dodges(3))
	var r4 := CombatResolver.resolve(player, monster, w, _perfect_dodges(4))
	var dmg3_total: float = 100000.0 - r3["monster_hp"]
	var dmg4_total: float = 100000.0 - r4["monster_hp"]
	var fourth_hit_dmg: float = dmg4_total - dmg3_total
	assert_almost_eq(dmg3_total, 3.0 * (100.0 * CombatResolver.DUAL_BLADES_HIT_MULT))
	assert_almost_eq(fourth_hit_dmg, 100.0 * CombatResolver.DUAL_BLADES_HIT_MULT * CombatResolver.DUAL_BLADES_DEMON_MULT)

func test_hammer_stuns_on_third_hit_and_skips_monster_attack() -> void:
	var player := {"hp_max": 10000.0, "power": 500.0}
	var monster := {"hp_max": 100000.0, "power": 500.0, "element": "neutral"}
	var w := _weapon("hammer", "neutral", 100.0)
	# 3 rounds, all missed dodges; the 3rd round should stun the monster and
	# skip its attack, so only 2 monster hits of full (undoged) damage land.
	var result := CombatResolver.resolve(player, monster, w, [{}, {}, {}])
	var full_hit := 500.0 # power, undoged, full damage
	assert_almost_eq(result["player_hp"], 10000.0 - full_hit * 2.0)
	var dmg3_total: float = 100000.0 - result["monster_hp"]
	var expected_total := 2.0 * (100.0 * CombatResolver.HAMMER_HIT_MULT) + (100.0 * CombatResolver.HAMMER_HIT_MULT * CombatResolver.HAMMER_STUN_BONUS_MULT)
	assert_almost_eq(dmg3_total, expected_total)

func test_elemental_multiplier_applies_to_player_damage() -> void:
	var player := {"hp_max": 10000.0, "power": 1.0}
	var monster := {"hp_max": 100000.0, "power": 1.0, "element": "water"}
	var fire_weapon := _weapon("test_sword", "fire", 100.0)
	var result := CombatResolver.resolve(player, monster, fire_weapon, _perfect_dodges(1))
	assert_almost_eq(100000.0 - result["monster_hp"], 100.0 * 1.5, 0.001, "fire is weak into water")
