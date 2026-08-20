# OverworldMovement — pure input-vector combination and position stepping for
# the overworld walk (on-screen joystick + keyboard drive the same movement
# vector, so desktop/headless can drive it identically). No Node/Input
# coupling, so this is covered by the headless logic test suite;
# OverworldScreen wires real Input/joystick events to these functions.
class_name OverworldMovement
extends RefCounted

const DEFAULT_SPEED := 220.0 # px/sec

# Combines a keyboard-derived vector (e.g. Input.get_vector, already -1..1
# per axis) with a joystick-derived vector (already clamped to unit length)
# into one movement direction, clamped to unit length so diagonals aren't
# faster. Joystick wins when both are non-zero (an actively dragged thumb
# overrides idle keys).
static func combine_input(keyboard_vector: Vector2, joystick_vector: Vector2) -> Vector2:
	var raw := joystick_vector if joystick_vector.length_squared() > 0.0001 else keyboard_vector
	if raw.length() > 1.0:
		raw = raw.normalized()
	return raw

# Steps `position` by `direction * speed * delta`, clamped so the character
# stays within [0, map_size] (map_size in the same units as position, e.g.
# pixels). `direction` is expected pre-clamped to unit length (combine_input).
static func step(position: Vector2, direction: Vector2, delta: float, map_size: Vector2, speed: float = DEFAULT_SPEED) -> Vector2:
	var moved := position + direction * speed * delta
	moved.x = clampf(moved.x, 0.0, map_size.x)
	moved.y = clampf(moved.y, 0.0, map_size.y)
	return moved
