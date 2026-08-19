# Elements — 6-element matchup model (design doc / PRD §"Elemental matchups").
#
# Fire/Water/Earth/Thunder/Ice form a ring: each element beats the next
# element in the ring (weak x1.5) and is resisted by the previous one
# (resist x0.66). Neutral is always x1.0 both ways. Dragon is a rare
# element that hits everything for x1.5 and has no ring weakness itself.
class_name Elements
extends RefCounted

const RING := ["fire", "water", "earth", "thunder", "ice"]

const WEAK_MULT := 1.5
const RESIST_MULT := 0.66
const NEUTRAL_MULT := 1.0
const DRAGON_MULT := 1.5

# Damage multiplier for an attack of `attacker_element` landing on a
# defender of `defender_element`.
static func multiplier(attacker_element: String, defender_element: String) -> float:
	if attacker_element == "dragon":
		return DRAGON_MULT
	if attacker_element == "neutral" or defender_element == "neutral" or defender_element == "dragon":
		return NEUTRAL_MULT

	var attacker_index := RING.find(attacker_element)
	var defender_index := RING.find(defender_element)
	if attacker_index == -1 or defender_index == -1:
		return NEUTRAL_MULT
	if defender_index == (attacker_index + 1) % RING.size():
		return WEAK_MULT
	if defender_index == (attacker_index - 1 + RING.size()) % RING.size():
		return RESIST_MULT
	return NEUTRAL_MULT
