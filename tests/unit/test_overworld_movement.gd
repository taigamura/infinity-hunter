# Tests for OverworldMovement (src/systems/overworld_movement.gd): input
# combination (joystick precedence, diagonal clamping) and bounded position
# stepping.
extends "res://tests/test_case.gd"

const OverworldMovement = preload("res://src/systems/overworld_movement.gd")

func test_combine_input_uses_keyboard_when_joystick_idle() -> void:
	var result := OverworldMovement.combine_input(Vector2(1, 0), Vector2.ZERO)
	assert_eq(result, Vector2(1, 0))

func test_combine_input_prefers_joystick_when_both_active() -> void:
	var result := OverworldMovement.combine_input(Vector2(1, 0), Vector2(0, 1))
	assert_eq(result, Vector2(0, 1))

func test_combine_input_clamps_diagonal_keyboard_to_unit_length() -> void:
	var result := OverworldMovement.combine_input(Vector2(1, 1), Vector2.ZERO)
	assert_almost_eq(result.length(), 1.0)

func test_combine_input_preserves_partial_joystick_magnitude() -> void:
	var result := OverworldMovement.combine_input(Vector2.ZERO, Vector2(0.5, 0.0))
	assert_almost_eq(result.length(), 0.5)

func test_step_moves_by_speed_times_delta() -> void:
	var result := OverworldMovement.step(Vector2(100, 100), Vector2(1, 0), 1.0, Vector2(1000, 1000), 50.0)
	assert_almost_eq(result.x, 150.0)
	assert_almost_eq(result.y, 100.0)

func test_step_clamps_to_map_bounds_lower() -> void:
	var result := OverworldMovement.step(Vector2(5, 5), Vector2(-1, -1), 1.0, Vector2(1000, 1000), 50.0)
	assert_almost_eq(result.x, 0.0)
	assert_almost_eq(result.y, 0.0)

func test_step_clamps_to_map_bounds_upper() -> void:
	var result := OverworldMovement.step(Vector2(995, 995), Vector2(1, 1).normalized(), 1.0, Vector2(1000, 1000), 50.0)
	assert_almost_eq(result.x, 1000.0)
	assert_almost_eq(result.y, 1000.0)

func test_step_zero_direction_does_not_move() -> void:
	var result := OverworldMovement.step(Vector2(500, 500), Vector2.ZERO, 1.0, Vector2(1000, 1000), 50.0)
	assert_almost_eq(result.x, 500.0)
	assert_almost_eq(result.y, 500.0)
