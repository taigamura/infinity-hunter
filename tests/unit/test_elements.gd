extends "res://tests/test_case.gd"

const Elements = preload("res://src/systems/elements.gd")

func test_ring_weak_matchup_is_1_5x() -> void:
	assert_almost_eq(Elements.multiplier("fire", "water"), 1.5)
	assert_almost_eq(Elements.multiplier("water", "earth"), 1.5)
	assert_almost_eq(Elements.multiplier("earth", "thunder"), 1.5)
	assert_almost_eq(Elements.multiplier("thunder", "ice"), 1.5)
	assert_almost_eq(Elements.multiplier("ice", "fire"), 1.5)

func test_ring_resist_matchup_is_0_66x() -> void:
	assert_almost_eq(Elements.multiplier("water", "fire"), 0.66)
	assert_almost_eq(Elements.multiplier("earth", "water"), 0.66)
	assert_almost_eq(Elements.multiplier("thunder", "earth"), 0.66)
	assert_almost_eq(Elements.multiplier("ice", "thunder"), 0.66)
	assert_almost_eq(Elements.multiplier("fire", "ice"), 0.66)

func test_same_element_is_neutral() -> void:
	assert_almost_eq(Elements.multiplier("fire", "fire"), 1.0)

func test_non_adjacent_ring_element_is_neutral() -> void:
	# fire is neither weak-into nor resisted-by thunder (2 steps away).
	assert_almost_eq(Elements.multiplier("fire", "thunder"), 1.0)

func test_neutral_element_is_always_1x() -> void:
	assert_almost_eq(Elements.multiplier("neutral", "fire"), 1.0)
	assert_almost_eq(Elements.multiplier("fire", "neutral"), 1.0)
	assert_almost_eq(Elements.multiplier("neutral", "neutral"), 1.0)

func test_dragon_attacker_is_strong_vs_all() -> void:
	assert_almost_eq(Elements.multiplier("dragon", "fire"), 1.5)
	assert_almost_eq(Elements.multiplier("dragon", "neutral"), 1.5)
	assert_almost_eq(Elements.multiplier("dragon", "dragon"), 1.5)

func test_dragon_defender_has_no_ring_weakness() -> void:
	assert_almost_eq(Elements.multiplier("fire", "dragon"), 1.0)
	assert_almost_eq(Elements.multiplier("water", "dragon"), 1.0)

func test_weakness_of_returns_preceding_ring_element() -> void:
	assert_eq(Elements.weakness_of("water"), "fire")
	assert_eq(Elements.weakness_of("earth"), "water")
	assert_eq(Elements.weakness_of("thunder"), "earth")
	assert_eq(Elements.weakness_of("ice"), "thunder")
	assert_eq(Elements.weakness_of("fire"), "ice")

func test_weakness_of_non_ring_element_is_empty() -> void:
	assert_eq(Elements.weakness_of("neutral"), "")
	assert_eq(Elements.weakness_of("dragon"), "")
	assert_eq(Elements.weakness_of("unknown"), "")
