# Tests for SkillSystem (src/systems/skill_system.gd, issue #9): skill point
# aggregation from equipped armor, set-bonus threshold activation, and
# conversion to the numeric effects profile CombatResolver/XpCurve consume.
extends "res://tests/test_case.gd"

const SkillSystem = preload("res://src/systems/skill_system.gd")
const ArmorDef = preload("res://src/models/armor_def.gd")
const ArmorSetDef = preload("res://src/models/armor_set_def.gd")

func _armor(id: String, skills: Array, set_id: String = "") -> ArmorDef:
	var def := ArmorDef.new()
	def.id = id
	def.name = id
	def.slot = "misc"
	def.base_defense = 1.0
	def.skills = skills
	def.recipe = {}
	def.set_id = set_id
	return def

func _armor_set(id: String, thresholds: Array) -> ArmorSetDef:
	var def := ArmorSetDef.new()
	def.id = id
	def.name = id
	def.thresholds = thresholds
	return def

func test_aggregate_sums_points_per_skill_instance() -> void:
	var equipped := [
		_armor("a", ["Crit"]),
		_armor("b", ["Crit", "Attack Boost"]),
	]
	var points := SkillSystem.aggregate_skill_points(equipped)
	assert_almost_eq(points["Crit"], 2.0)
	assert_almost_eq(points["Attack Boost"], 1.0)

func test_set_bonus_inactive_below_piece_threshold() -> void:
	var sets := {"ember": _armor_set("ember", [{"pieces": 2, "skill": "Fire Resist", "points": 2}])}
	var equipped := [_armor("helm", ["Fire Resist"], "ember")]
	var points := SkillSystem.aggregate_skill_points(equipped, sets)
	# only the piece's own point, no set bonus yet
	assert_almost_eq(points["Fire Resist"], 1.0)

func test_set_bonus_activates_at_piece_threshold() -> void:
	var sets := {"ember": _armor_set("ember", [{"pieces": 2, "skill": "Fire Resist", "points": 2}])}
	var equipped := [
		_armor("helm", ["Fire Resist"], "ember"),
		_armor("chest", ["Attack Boost"], "ember"),
	]
	var points := SkillSystem.aggregate_skill_points(equipped, sets)
	# 1 base point from the helm + 2 bonus points once the 2-piece threshold hits
	assert_almost_eq(points["Fire Resist"], 3.0)

func test_set_bonus_ignores_unequipped_pieces_of_other_sets() -> void:
	var sets := {
		"ember": _armor_set("ember", [{"pieces": 2, "skill": "Fire Resist", "points": 2}]),
		"glacier": _armor_set("glacier", [{"pieces": 2, "skill": "Ice Resist", "points": 2}]),
	}
	var equipped := [_armor("helm", ["Fire Resist"], "ember")]
	var points := SkillSystem.aggregate_skill_points(equipped, sets)
	assert_false(points.has("Ice Resist"))

func test_compute_effects_scales_by_per_point_and_caps() -> void:
	var points := {"Crit": 3.0} # 3 * 0.03 = 0.09, well under the 0.30 cap
	var effects := SkillSystem.compute_effects(points)
	assert_almost_eq(effects["crit_bonus_mult"], 0.09)

	var capped_points := {"Crit": 100.0}
	var capped_effects := SkillSystem.compute_effects(capped_points)
	assert_almost_eq(capped_effects["crit_bonus_mult"], 0.30)

func test_compute_effects_nests_resist_by_element() -> void:
	var points := {"Fire Resist": 2.0, "Ice Resist": 1.0}
	var effects := SkillSystem.compute_effects(points)
	assert_almost_eq(effects["resist"]["fire"], 0.10)
	assert_almost_eq(effects["resist"]["ice"], 0.05)

func test_build_profile_end_to_end_with_set_bonus() -> void:
	var sets := {"ember": _armor_set("ember", [
		{"pieces": 2, "skill": "Fire Resist", "points": 2},
		{"pieces": 4, "skill": "Attack Boost", "points": 3},
	])}
	var equipped := [
		_armor("helm", ["Fire Resist"], "ember"),
		_armor("chest", ["Attack Boost"], "ember"),
		_armor("gloves", ["Crit"], "ember"),
		_armor("boots", ["Evasion Boost"], "ember"),
	]
	var effects := SkillSystem.build_profile(equipped, sets)
	# 4 pieces equipped -> both thresholds active
	assert_almost_eq(effects["resist"]["fire"], 0.15) # (1 base + 2 bonus) * 0.05
	assert_almost_eq(effects["attack_mult_bonus"], 0.20) # (1 base + 3 bonus) * 0.05
