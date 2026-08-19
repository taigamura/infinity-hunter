# DropSystem — weighted material drop tables per monster (PRD "DropSystem").
# Breaking a monster part sharply boosts (via `break_boost`) or guarantees
# (via `guaranteed_on_break`) that part's tied material. One material is
# always drawn from the remaining weighted pool, in addition to any
# guaranteed drops from broken parts.
class_name DropSystem
extends RefCounted

const DEFAULT_BREAK_BOOST := 5.0

# Rolls `monster`'s drop_table given the parts broken during the fight.
# `rng` is caller-supplied (RandomNumberGenerator) so rolls are deterministic
# and statistically verifiable in tests.
static func roll(monster: MonsterDef, broken_parts: Array, rng: RandomNumberGenerator) -> Array:
	return roll_table(monster.drop_table, broken_parts, rng)

# Rolls a raw drop_table Array of Dictionaries:
#   {material_id: String, weight: float, part: String (optional),
#    break_boost: float (optional, default DEFAULT_BREAK_BOOST),
#    guaranteed_on_break: bool (optional)}
# Returns Array[String] of material ids granted. May contain a duplicate if a
# guaranteed part-break drop and the weighted roll pick the same material.
static func roll_table(drop_table: Array, broken_parts: Array, rng: RandomNumberGenerator) -> Array:
	var results: Array = []
	var pool: Array = [] # {material_id, weight}
	var total_weight := 0.0

	for entry in drop_table:
		var part: String = entry.get("part", "")
		var part_broken: bool = part != "" and broken_parts.has(part)

		if part_broken and entry.get("guaranteed_on_break", false):
			results.append(entry["material_id"])
			continue

		var weight: float = entry["weight"]
		if part_broken:
			weight *= entry.get("break_boost", DEFAULT_BREAK_BOOST)
		if weight <= 0.0:
			continue
		pool.append({"material_id": entry["material_id"], "weight": weight})
		total_weight += weight

	if pool.is_empty():
		return results

	var roll_point := rng.randf() * total_weight
	var cursor := 0.0
	for item in pool:
		cursor += item["weight"]
		if roll_point < cursor:
			results.append(item["material_id"])
			return results

	results.append(pool[-1]["material_id"]) # float rounding fallback
	return results
