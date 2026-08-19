# SkillSystem — aggregates equipped ArmorDef pieces (and their ArmorSetDef
# set bonuses, issue #9) into a computed skill/stat profile that other
# systems (CombatResolver, XpCurve, ...) consume as build-defining bonuses.
# Each equipped piece grants POINTS_PER_SKILL_INSTANCE points to every skill
# name in its `skills` array; pieces sharing a non-empty ArmorDef.set_id also
# count toward that set's ArmorSetDef.thresholds, which grant extra points to
# a named skill once enough pieces of the set are equipped simultaneously.
# Raw skill points are then converted to numeric effects (SKILL_EFFECTS)
# expressing the power/survivability/farming tradeoff: Crit and Attack Boost
# raise damage output, Defense Boost/resistances and Evasion Boost raise
# survivability, XP Boost raises farming speed.
class_name SkillSystem
extends RefCounted

const POINTS_PER_SKILL_INSTANCE := 1.0

# skill name -> {stat: effects-dict key ("resist:<Element>" nests under
# "resist"), per_point: value added per skill point, cap: hard ceiling on
# the total bonus regardless of points invested}.
const SKILL_EFFECTS := {
	"Crit": {"stat": "crit_bonus_mult", "per_point": 0.03, "cap": 0.30},
	"Attack Boost": {"stat": "attack_mult_bonus", "per_point": 0.05, "cap": 0.50},
	"Defense Boost": {"stat": "defense_mult_bonus", "per_point": 0.05, "cap": 0.50},
	"Evasion Boost": {"stat": "evasion_bonus", "per_point": 0.04, "cap": 0.40},
	"XP Boost": {"stat": "xp_mult_bonus", "per_point": 0.05, "cap": 0.50},
	"Fire Resist": {"stat": "resist:fire", "per_point": 0.05, "cap": 0.50},
	"Ice Resist": {"stat": "resist:ice", "per_point": 0.05, "cap": 0.50},
}

# Sums POINTS_PER_SKILL_INSTANCE for every skill name across `equipped_armor`
# (Array[ArmorDef]), then adds each matching ArmorSetDef threshold bonus for
# sets that meet their piece-count requirement. `armor_sets` is id -> ArmorSetDef.
# Returns Dictionary[String, float] skill name -> raw points.
static func aggregate_skill_points(equipped_armor: Array, armor_sets: Dictionary = {}) -> Dictionary:
	var points: Dictionary = {}
	var set_counts: Dictionary = {}

	for armor_def in equipped_armor:
		for skill in armor_def.skills:
			points[skill] = float(points.get(skill, 0.0)) + POINTS_PER_SKILL_INSTANCE
		if armor_def.set_id != "":
			set_counts[armor_def.set_id] = int(set_counts.get(armor_def.set_id, 0)) + 1

	for set_id in set_counts:
		if not armor_sets.has(set_id):
			continue
		var set_def: ArmorSetDef = armor_sets[set_id]
		var count: int = set_counts[set_id]
		for threshold in set_def.thresholds:
			if count >= int(threshold["pieces"]):
				var skill: String = threshold["skill"]
				points[skill] = float(points.get(skill, 0.0)) + float(threshold["points"])

	return points

# Converts raw skill points (from aggregate_skill_points) into the numeric
# effects dictionary CombatResolver/XpCurve consume: top-level float bonuses
# plus a nested "resist" Dictionary[Element, float].
static func compute_effects(skill_points: Dictionary) -> Dictionary:
	var effects: Dictionary = {"resist": {}}
	for skill in SKILL_EFFECTS:
		var points: float = float(skill_points.get(skill, 0.0))
		if points <= 0.0:
			continue
		var def: Dictionary = SKILL_EFFECTS[skill]
		var value: float = minf(float(def["per_point"]) * points, float(def["cap"]))
		var stat: String = def["stat"]
		if stat.begins_with("resist:"):
			var element: String = stat.substr("resist:".length())
			effects["resist"][element] = value
		else:
			effects[stat] = value
	return effects

# Convenience: aggregates `equipped_armor` and converts straight to effects.
static func build_profile(equipped_armor: Array, armor_sets: Dictionary = {}) -> Dictionary:
	return compute_effects(aggregate_skill_points(equipped_armor, armor_sets))
