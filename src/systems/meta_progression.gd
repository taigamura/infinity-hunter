# MetaProgression — essence economy and permanent upgrades that persist
# across runs (via SaveManager, see #5).
#
# Essence is earned as a function of the peak level reached during a run
# (design pillar: "push or cash out"). It is forfeited entirely on death and
# banked only when a run ends by retreat or hunt exhaustion — callers pass
# the run's final `status` ("dead" | "banked") straight from RunState.
#
# Upgrades are purchased with banked essence and apply a small, capped bonus
# to the *next* run (get_run_modifiers). Caps are deliberately modest so gear
# stays the primary power lever; see UPGRADES below for documented ceilings.
class_name MetaProgression
extends RefCounted

# Essence award curve: essence_for_peak_level(1) == ESSENCE_BASE, growing
# exponentially with peak level reached, mirroring XpCurve's shape.
const ESSENCE_BASE := 5.0
const ESSENCE_GROWTH := 1.15

# upgrade_id -> {
#   max_level: highest purchasable level,
#   cost_base / cost_growth: essence cost of level (current_level -> current_level+1),
#   effect_per_level: raw per-level bonus before capping,
#   cap: hard ceiling on the total bonus (bounded so upgrades never dominate gear),
# }
const UPGRADES := {
	"starting_level": {"max_level": 5, "cost_base": 50.0, "cost_growth": 1.6, "effect_per_level": 1.0, "cap": 5.0},
	"xp_multiplier": {"max_level": 5, "cost_base": 40.0, "cost_growth": 1.6, "effect_per_level": 0.05, "cap": 0.25},
	"hunt_count": {"max_level": 5, "cost_base": 60.0, "cost_growth": 1.6, "effect_per_level": 1.0, "cap": 5.0},
	"crit_chance": {"max_level": 5, "cost_base": 80.0, "cost_growth": 1.7, "effect_per_level": 0.01, "cap": 0.05},
	"drop_rate": {"max_level": 5, "cost_base": 50.0, "cost_growth": 1.6, "effect_per_level": 0.02, "cap": 0.10},
	"capture_chance": {"max_level": 5, "cost_base": 50.0, "cost_growth": 1.6, "effect_per_level": 0.02, "cap": 0.10},
	"companion_effectiveness": {"max_level": 5, "cost_base": 50.0, "cost_growth": 1.6, "effect_per_level": 0.02, "cap": 0.10},
}

# ---- essence award ----------------------------------------------------------

# Raw essence a peak level would award, ignoring run outcome.
static func essence_for_peak_level(peak_level: float) -> float:
	return round(ESSENCE_BASE * pow(ESSENCE_GROWTH, peak_level - 1.0))

# Essence actually banked for a finished run: 0 on death (forfeited), the
# peak-level award on any other end status (retreat / hunt_exhaustion).
static func essence_for_run(peak_level: float, run_status: String) -> float:
	if run_status == "dead":
		return 0.0
	return essence_for_peak_level(peak_level)

# ---- upgrades -----------------------------------------------------------------

static func upgrade_level(save_state: Dictionary, upgrade_id: String) -> int:
	return int(save_state.get("upgrades", {}).get(upgrade_id, 0))

# Essence cost to advance `upgrade_id` from its current level to the next.
static func upgrade_cost(save_state: Dictionary, upgrade_id: String) -> float:
	var def: Dictionary = UPGRADES[upgrade_id]
	var current_level := upgrade_level(save_state, upgrade_id)
	return def["cost_base"] * pow(def["cost_growth"], current_level)

static func can_purchase(save_state: Dictionary, upgrade_id: String) -> bool:
	if not UPGRADES.has(upgrade_id):
		return false
	var def: Dictionary = UPGRADES[upgrade_id]
	var current_level := upgrade_level(save_state, upgrade_id)
	if current_level >= int(def["max_level"]):
		return false
	return float(save_state.get("essence", 0.0)) >= upgrade_cost(save_state, upgrade_id)

# Attempts to spend essence to advance `upgrade_id` by one level. Mutates
# `save_state` in place (essence debited, upgrades level incremented) and
# returns true on success; returns false (no mutation) if the upgrade is
# maxed out or unaffordable.
static func purchase_upgrade(save_state: Dictionary, upgrade_id: String) -> bool:
	if not can_purchase(save_state, upgrade_id):
		return false
	var cost := upgrade_cost(save_state, upgrade_id)
	save_state["essence"] = float(save_state.get("essence", 0.0)) - cost
	if not save_state.has("upgrades"):
		save_state["upgrades"] = {}
	var upgrades: Dictionary = save_state["upgrades"]
	upgrades[upgrade_id] = upgrade_level(save_state, upgrade_id) + 1
	return true

# Total bonus currently granted by `upgrade_id`, capped at its documented
# ceiling regardless of level (defense in depth alongside max_level).
static func upgrade_effect(save_state: Dictionary, upgrade_id: String) -> float:
	var def: Dictionary = UPGRADES[upgrade_id]
	var level := upgrade_level(save_state, upgrade_id)
	return minf(def["effect_per_level"] * level, def["cap"])

# The full set of bonuses purchased upgrades grant, shaped for a run to
# consume directly (e.g. RunState.start's optional modifiers argument).
static func get_run_modifiers(save_state: Dictionary) -> Dictionary:
	return {
		"starting_level_bonus": upgrade_effect(save_state, "starting_level"),
		"xp_multiplier_bonus": upgrade_effect(save_state, "xp_multiplier"),
		"hunt_count_bonus": upgrade_effect(save_state, "hunt_count"),
		"crit_chance_bonus": upgrade_effect(save_state, "crit_chance"),
		"drop_rate_bonus": upgrade_effect(save_state, "drop_rate"),
		"capture_chance_bonus": upgrade_effect(save_state, "capture_chance"),
		"companion_effectiveness_bonus": upgrade_effect(save_state, "companion_effectiveness"),
	}

# ---- run settlement -----------------------------------------------------------

# Banks (or forfeits) the essence earned by a finished run straight into a
# SaveManager-shaped `save_state` (see SaveManager.default_state). Mutates
# `save_state["essence"]` and returns the amount actually banked (0 on death).
static func settle_run(save_state: Dictionary, peak_level: float, run_status: String) -> float:
	var awarded := essence_for_run(peak_level, run_status)
	save_state["essence"] = float(save_state.get("essence", 0.0)) + awarded
	return awarded
