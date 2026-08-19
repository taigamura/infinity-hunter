# Tests for MetaProgression (src/systems/meta_progression.gd): essence
# formula, bank-vs-forfeit on run settlement, upgrade purchase + capped
# effect, and persistence round-trip through SaveManager (#5).
extends "res://tests/test_case.gd"

const MetaProgression = preload("res://src/systems/meta_progression.gd")
const SaveManager = preload("res://src/systems/save_manager.gd")

const TEST_PATH := "user://test_meta_progression.json"

func before_each() -> void:
	_cleanup()

func after_each() -> void:
	_cleanup()

func _cleanup() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		var p: String = TEST_PATH + suffix
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)

func test_essence_formula_scales_with_peak_level() -> void:
	var lvl1 := MetaProgression.essence_for_peak_level(1.0)
	var lvl5 := MetaProgression.essence_for_peak_level(5.0)
	var lvl10 := MetaProgression.essence_for_peak_level(10.0)
	assert_almost_eq(lvl1, MetaProgression.ESSENCE_BASE)
	assert_gt(lvl5, lvl1)
	assert_gt(lvl10, lvl5)

func test_settle_run_forfeits_on_death() -> void:
	var save_state := SaveManager.default_state()
	var awarded := MetaProgression.settle_run(save_state, 7.0, "dead")
	assert_almost_eq(awarded, 0.0)
	assert_almost_eq(save_state["essence"], 0.0)

func test_settle_run_banks_on_retreat_or_hunt_exhaustion() -> void:
	var save_state := SaveManager.default_state()
	var awarded := MetaProgression.settle_run(save_state, 7.0, "banked")
	assert_gt(awarded, 0.0)
	assert_almost_eq(save_state["essence"], awarded)

	var save_state2 := SaveManager.default_state()
	var awarded2 := MetaProgression.settle_run(save_state2, 7.0, "banked")
	assert_almost_eq(awarded2, awarded, 0.0001, "hunt_exhaustion and retreat both end in status \"banked\"")

func test_purchase_upgrade_debits_essence_and_increments_level() -> void:
	var save_state := SaveManager.default_state()
	save_state["essence"] = 1000.0
	var cost := MetaProgression.upgrade_cost(save_state, "xp_multiplier")
	var ok := MetaProgression.purchase_upgrade(save_state, "xp_multiplier")
	assert_true(ok)
	assert_almost_eq(save_state["essence"], 1000.0 - cost)
	assert_eq(MetaProgression.upgrade_level(save_state, "xp_multiplier"), 1)

func test_purchase_upgrade_fails_when_unaffordable() -> void:
	var save_state := SaveManager.default_state()
	save_state["essence"] = 0.0
	var ok := MetaProgression.purchase_upgrade(save_state, "xp_multiplier")
	assert_false(ok)
	assert_eq(MetaProgression.upgrade_level(save_state, "xp_multiplier"), 0)
	assert_almost_eq(save_state["essence"], 0.0)

func test_purchase_upgrade_fails_at_max_level() -> void:
	var save_state := SaveManager.default_state()
	save_state["essence"] = 1.0e12
	var def: Dictionary = MetaProgression.UPGRADES["starting_level"]
	for i in range(def["max_level"]):
		assert_true(MetaProgression.purchase_upgrade(save_state, "starting_level"))
	assert_eq(MetaProgression.upgrade_level(save_state, "starting_level"), int(def["max_level"]))
	assert_false(MetaProgression.can_purchase(save_state, "starting_level"))
	assert_false(MetaProgression.purchase_upgrade(save_state, "starting_level"))

func test_upgrade_effect_is_capped_and_bounded_below_gear() -> void:
	var save_state := SaveManager.default_state()
	save_state["essence"] = 1.0e12
	var def: Dictionary = MetaProgression.UPGRADES["crit_chance"]
	for i in range(def["max_level"]):
		MetaProgression.purchase_upgrade(save_state, "crit_chance")
	var effect := MetaProgression.upgrade_effect(save_state, "crit_chance")
	assert_almost_eq(effect, def["cap"])
	assert_lt(effect, 0.5, "crit_chance upgrade must stay modest, not dominate gear")

func test_get_run_modifiers_reflects_purchased_upgrades() -> void:
	var save_state := SaveManager.default_state()
	var zero_modifiers := MetaProgression.get_run_modifiers(save_state)
	assert_almost_eq(zero_modifiers["starting_level_bonus"], 0.0)

	save_state["essence"] = 1.0e12
	MetaProgression.purchase_upgrade(save_state, "starting_level")
	MetaProgression.purchase_upgrade(save_state, "hunt_count")
	var modifiers := MetaProgression.get_run_modifiers(save_state)
	assert_gt(modifiers["starting_level_bonus"], 0.0)
	assert_gt(modifiers["hunt_count_bonus"], 0.0)
	assert_almost_eq(modifiers["crit_chance_bonus"], 0.0)

func test_persists_essence_and_upgrades_through_save_manager() -> void:
	var save_state := SaveManager.default_state()
	save_state["essence"] = 500.0
	MetaProgression.purchase_upgrade(save_state, "drop_rate")
	var essence_after_purchase: float = save_state["essence"]

	assert_true(SaveManager.save_game(save_state, TEST_PATH))
	var loaded := SaveManager.load_game(TEST_PATH)

	assert_almost_eq(loaded["essence"], essence_after_purchase)
	assert_eq(MetaProgression.upgrade_level(loaded, "drop_rate"), 1)
	assert_almost_eq(MetaProgression.upgrade_effect(loaded, "drop_rate"), MetaProgression.upgrade_effect(save_state, "drop_rate"))
