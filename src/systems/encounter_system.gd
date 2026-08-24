# EncounterSystem — pure overworld encounter logic (PRD issue #17). Advances
# the per-tile danger gauge and picks the monster that ambushes the player
# when it fires. No scene, no side effects; mirrors the DropSystem precedent
# (static methods, caller-supplied rng for deterministic tests).
class_name EncounterSystem
extends RefCounted

const GAUGE_THRESHOLD := 100.0
const DEFAULT_JITTER := 0.0

# Advances `gauge` by tier_params["gauge_rate"] plus a small bounded jitter
# (tier_params["jitter"], default 0). Returns {"gauge": float, "fired": bool}.
# When the advanced gauge reaches or exceeds GAUGE_THRESHOLD, fired is true
# and the returned gauge resets to 0.
#
# `dt` scales the advance so `gauge_rate`/`jitter` read as per-second values:
# the overworld calls this every physics frame and passes the frame delta, so
# a section fills over seconds of walking rather than instantly. Defaults to
# 1.0, which preserves the original per-tick semantics for existing callers
# and unit tests.
static func tick(tier_params: Dictionary, gauge: float, rng: RandomNumberGenerator, dt: float = 1.0) -> Dictionary:
	var rate: float = tier_params.get("gauge_rate", 0.0)
	var jitter: float = tier_params.get("jitter", DEFAULT_JITTER)
	var delta := rate
	if jitter > 0.0:
		delta += rng.randf_range(-jitter, jitter)
	delta = maxf(delta, 0.0) * dt

	var new_gauge := gauge + delta
	if new_gauge >= GAUGE_THRESHOLD:
		return {"gauge": 0.0, "fired": true}
	return {"gauge": new_gauge, "fired": false}

# Picks a monster id from `zone.monster_ids`, filtered to MonsterDef.level in
# [level_min, level_max] from tier_params, weighted-random via `rng`. Falls
# back to the nearest-level monster in the full roster when the band matches
# nothing rather than failing.
# Returns "" if the zone has no known monsters at all.
static func pick_monster(zone: ZoneDef, tier_params: Dictionary, monster_defs: Dictionary, rng: RandomNumberGenerator) -> String:
	var level_min: float = tier_params.get("level_min", -INF)
	var level_max: float = tier_params.get("level_max", INF)

	var roster: Array = []
	for monster_id in zone.monster_ids:
		if monster_defs.has(monster_id):
			roster.append(monster_defs[monster_id])
	if roster.is_empty():
		return ""

	var banded: Array = []
	for monster in roster:
		if monster.level >= level_min and monster.level <= level_max:
			banded.append(monster)

	if banded.is_empty():
		var target_level := level_min if level_min > -INF else level_max
		if target_level == INF or target_level == -INF:
			target_level = roster[0].level
		var nearest = roster[0]
		var nearest_dist := absf(nearest.level - target_level)
		for monster in roster:
			var dist := absf(monster.level - target_level)
			if dist < nearest_dist:
				nearest = monster
				nearest_dist = dist
		return nearest.id

	var total_weight := 0.0
	for monster in banded:
		total_weight += _monster_weight(monster)

	if total_weight <= 0.0:
		return banded[0].id

	var roll_point := rng.randf() * total_weight
	var cursor := 0.0
	for monster in banded:
		cursor += _monster_weight(monster)
		if roll_point < cursor:
			return monster.id

	return banded[-1].id # float rounding fallback

static func _monster_weight(monster: MonsterDef) -> float:
	return 1.0
