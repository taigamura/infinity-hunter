# Tests for CaptureSystem (src/systems/capture_system.gd): HP threshold
# gating, trap consumption, zero-XP-on-capture, capture persistence, and
# companion passive application.
extends "res://tests/test_case.gd"

const CaptureSystem = preload("res://src/systems/capture_system.gd")
const MonsterDef = preload("res://src/models/monster_def.gd")
const CompanionDef = preload("res://src/models/companion_def.gd")
const Inventory = preload("res://src/systems/inventory.gd")

func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng

func _monster(capturable: bool = true, threshold: float = 0.2) -> MonsterDef:
	var m := MonsterDef.new()
	m.id = "slime"
	m.name = "Slime"
	m.level = 1.0
	m.element = "water"
	m.base_hp = 20.0
	m.base_attack = 2.0
	m.xp_reward = 10.0
	m.zone_id = "verdant_fields"
	m.parts = ["body"]
	m.capturable = capturable
	m.capture_hp_threshold = threshold
	m.capture_only_materials = ["slime_core"]
	m.drop_table = [{"material_id": "slime_gel", "weight": 100}]
	return m

func _inventory_with_trap(count: int = 1) -> Inventory:
	var inv := Inventory.new()
	inv.add_consumable("trap", count)
	return inv

func _companion(skill: String = "xp_boost", value: float = 0.05) -> CompanionDef:
	var c := CompanionDef.new()
	c.id = "slime_pal"
	c.name = "Slime Pal"
	c.source_monster_id = "slime"
	c.passive_skill = skill
	c.passive_value = value
	return c

# ---- threshold gating -----------------------------------------------------

func test_capturable_below_threshold() -> void:
	var m := _monster(true, 0.2)
	assert_true(CaptureSystem.is_capturable(m, 3.0, 20.0))

func test_not_capturable_above_threshold() -> void:
	var m := _monster(true, 0.2)
	assert_false(CaptureSystem.is_capturable(m, 10.0, 20.0))

func test_not_capturable_when_flag_false() -> void:
	var m := _monster(false, 0.2)
	assert_false(CaptureSystem.is_capturable(m, 1.0, 20.0))

func test_attempt_capture_rejects_above_threshold() -> void:
	var m := _monster(true, 0.2)
	var inv := _inventory_with_trap()
	var result := CaptureSystem.attempt_capture(m, 10.0, 20.0, inv, _rng(1))
	assert_false(result["ok"])
	assert_eq(inv.consumables.get("trap", 0), 1, "trap must not be consumed on a rejected attempt")

# ---- trap consumption -------------------------------------------------------

func test_attempt_capture_consumes_one_trap_on_success() -> void:
	var m := _monster(true, 0.2)
	var inv := _inventory_with_trap(2)
	var result := CaptureSystem.attempt_capture(m, 1.0, 20.0, inv, _rng(1))
	assert_true(result["ok"])
	assert_eq(inv.consumables.get("trap", 0), 1)

func test_attempt_capture_fails_without_a_trap() -> void:
	var m := _monster(true, 0.2)
	var inv := Inventory.new()
	var result := CaptureSystem.attempt_capture(m, 1.0, 20.0, inv, _rng(1))
	assert_false(result["ok"])
	assert_eq(result["error"], "no trap available")

# ---- zero XP + materials ----------------------------------------------------

func test_attempt_capture_awards_zero_xp_on_success() -> void:
	var m := _monster(true, 0.2)
	var inv := _inventory_with_trap()
	var result := CaptureSystem.attempt_capture(m, 1.0, 20.0, inv, _rng(1))
	assert_true(result["ok"])
	assert_eq(result["xp_awarded"], 0.0)

func test_attempt_capture_grants_capture_only_materials() -> void:
	var m := _monster(true, 0.2)
	var inv := _inventory_with_trap()
	var result := CaptureSystem.attempt_capture(m, 1.0, 20.0, inv, _rng(1))
	assert_has(result["materials"], "slime_core", "capture-only bonus material must be granted")
	assert_has(result["materials"], "slime_gel", "normal drop table roll still applies")

# ---- capture persistence (#5) -----------------------------------------------

func test_record_capture_persists_species() -> void:
	var state := {"captures": []}
	CaptureSystem.record_capture(state, "slime")
	assert_true(CaptureSystem.has_captured(state, "slime"))

func test_record_capture_is_idempotent() -> void:
	var state := {"captures": []}
	CaptureSystem.record_capture(state, "slime")
	CaptureSystem.record_capture(state, "slime")
	assert_eq(state["captures"].size(), 1, "capturing the same species twice must not duplicate the entry")

func test_has_captured_false_for_uncaptured_species() -> void:
	var state := {"captures": []}
	assert_false(CaptureSystem.has_captured(state, "rock_lizard"))

# ---- companion selection + passive application ------------------------------

func test_select_companion_requires_species_captured() -> void:
	var state := {"captures": []}
	var result := CaptureSystem.select_companion(state, _companion())
	assert_false(result["ok"])
	assert_false(state.has("selected_companion_id"))

func test_select_companion_succeeds_once_captured() -> void:
	var state := {"captures": []}
	CaptureSystem.record_capture(state, "slime")
	var result := CaptureSystem.select_companion(state, _companion())
	assert_true(result["ok"])
	assert_eq(state["selected_companion_id"], "slime_pal")

func test_apply_passive_boosts_xp_boost_skill() -> void:
	var companion := _companion("xp_boost", 0.05)
	var boosted := CaptureSystem.apply_passive(companion, 100.0)
	assert_almost_eq(boosted, 105.0, 0.0001)

func test_apply_passive_passes_through_unknown_skill() -> void:
	var companion := _companion("mystery_skill", 0.5)
	var value := CaptureSystem.apply_passive(companion, 42.0)
	assert_almost_eq(value, 42.0, 0.0001)
