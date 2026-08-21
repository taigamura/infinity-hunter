# XpCurve — exponential level thresholds and level->power scaling.
#
# All quantities are `Big` (float-backed, see src/core/big.gd). Levels are
# whole numbers stored as float per the Big convention.
#
# Killing a monster far above the player's level can dump enough XP to cross
# many level thresholds in one call (design pillar: explosive gambles), so
# `award_xp` loops threshold-by-threshold rather than assuming a single
# level-up per award.
class_name XpCurve
extends RefCounted

# XP required to go from level 1 to level 2. Tunable, playtest-balanced.
const BASE_THRESHOLD := 100.0
# Per-level exponential growth rate of the XP threshold. Tunable.
const GROWTH_RATE := 1.12

# Level->power scaling: base power at level 1 and per-level growth rate.
# Used by combat for damage/HP scaling. Tunable.
const POWER_BASE := 10.0
const POWER_GROWTH := 1.08

# Level-gap XP scaling: punching above your level pays off exponentially.
const XP_GAP_GROWTH := 1.4      # each level the monster is above you multiplies XP by this
const XP_GAP_MULT_CAP := 1.0e6  # clamp so pathological gaps (e.g. the Voidmaw stat-wall) can't overflow

# XP required to advance from `level` to `level + 1`.
static func threshold(level: float) -> float:
	return BASE_THRESHOLD * pow(GROWTH_RATE, level - 1.0)

# Multiplier applied to a kill's base XP for punching above your level.
# gap <= 0 (same/lower level) earns the flat base (mult 1.0); a positive gap
# grows the reward exponentially so a brave over-level kill vaults many levels.
static func gap_multiplier(player_level: float, monster_level: float) -> float:
	var gap := monster_level - player_level
	if gap <= 0.0:
		return 1.0
	return minf(pow(XP_GAP_GROWTH, gap), XP_GAP_MULT_CAP)

# Convenience: base reward scaled by the level gap.
static func gap_scaled_reward(base_reward: float, player_level: float, monster_level: float) -> float:
	return base_reward * gap_multiplier(player_level, monster_level)

# Awards `xp_awarded` XP to a character at `level` with `xp_carry` XP already
# banked toward the next threshold. `xp_mult_bonus` (e.g. SkillSystem's
# "xp_mult_bonus" effect from an XP Boost armor build, issue #9) scales the
# award before it's applied. Crosses as many thresholds as the award allows
# in one call. Returns a Dictionary:
#   "level": the new level after all level-ups
#   "levels_gained": how many thresholds were crossed
#   "xp_carry": leftover XP toward the next threshold (< threshold(new level))
static func award_xp(level: float, xp_carry: float, xp_awarded: float, xp_mult_bonus: float = 0.0) -> Dictionary:
	var new_level := level
	var carry := xp_carry + xp_awarded * (1.0 + xp_mult_bonus)
	var levels_gained := 0
	while carry >= threshold(new_level):
		carry -= threshold(new_level)
		new_level += 1.0
		levels_gained += 1
	return {
		"level": new_level,
		"levels_gained": levels_gained,
		"xp_carry": carry,
	}

# Monotonically increasing power value for a given level, usable by combat
# for damage/HP scaling. power_scaling(1) == POWER_BASE.
static func power_scaling(level: float) -> float:
	return POWER_BASE * pow(POWER_GROWTH, level - 1.0)

# Ordered gauge-fill steps to animate an XP award, from (level_before, carry_before)
# to (level_after, carry_after). Each step is one level's bar filling:
#   {"level": int, "from": float (0..1), "to": float (0..1), "levels_up": bool}
# A single-level award yields one step (levels_up=false). A multi-level award
# yields: the starting level filling to 1.0 (levels_up=true), each fully-crossed
# intermediate level 0.0->1.0 (levels_up=true), then the final level filling
# 0.0->carry_after fraction (levels_up=false). The count of levels_up=true steps
# equals level_after - level_before.
static func fill_segments(level_before: float, carry_before: float, level_after: float, carry_after: float) -> Array:
	var steps: Array = []
	var lb := int(level_before)
	var la := int(level_after)
	if la <= lb:
		steps.append({"level": lb, "from": carry_before / maxf(threshold(float(lb)), 1.0), "to": carry_after / maxf(threshold(float(lb)), 1.0), "levels_up": false})
		return steps
	# starting level fills from current carry to full
	steps.append({"level": lb, "from": carry_before / maxf(threshold(float(lb)), 1.0), "to": 1.0, "levels_up": true})
	# each fully-crossed intermediate level
	for l in range(lb + 1, la):
		steps.append({"level": l, "from": 0.0, "to": 1.0, "levels_up": true})
	# final level fills from empty to the leftover carry
	steps.append({"level": la, "from": 0.0, "to": carry_after / maxf(threshold(float(la)), 1.0), "levels_up": false})
	return steps
