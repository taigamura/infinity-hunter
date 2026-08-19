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

# XP required to advance from `level` to `level + 1`.
static func threshold(level: float) -> float:
	return BASE_THRESHOLD * pow(GROWTH_RATE, level - 1.0)

# Awards `xp_awarded` XP to a character at `level` with `xp_carry` XP already
# banked toward the next threshold. Crosses as many thresholds as the award
# allows in one call. Returns a Dictionary:
#   "level": the new level after all level-ups
#   "levels_gained": how many thresholds were crossed
#   "xp_carry": leftover XP toward the next threshold (< threshold(new level))
static func award_xp(level: float, xp_carry: float, xp_awarded: float) -> Dictionary:
	var new_level := level
	var carry := xp_carry + xp_awarded
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
