# VirtualJoystick — on-screen touch/mouse joystick. Exposes `output_vector`,
# a unit-clamped Vector2 while dragging, zero when released. Keyboard input
# (Input.get_vector) drives the same OverworldMovement.combine_input seam, so
# desktop/headless testing never needs this node. Manual-verify only (touch
# and mouse input); the math it feeds is covered by
# tests/unit/test_overworld_movement.gd.
extends Control

@export var radius: float = 70.0

@onready var _base: Control = %Base
@onready var _knob: Control = %Knob

var output_vector: Vector2 = Vector2.ZERO

var _dragging: bool = false
var _touch_index: int = -1
var _center: Vector2 = Vector2.ZERO

func _ready() -> void:
	_center = _base.position + _base.size / 2.0
	_reset_knob()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_start_drag(event.position, event.index)
		elif event.index == _touch_index:
			_end_drag()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_drag(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag(event.position, -1)
		else:
			_end_drag()
	elif event is InputEventMouseMotion and _dragging and _touch_index == -1:
		_update_drag(event.position)

func _start_drag(pos: Vector2, index: int) -> void:
	_dragging = true
	_touch_index = index
	_update_drag(pos)

func _update_drag(pos: Vector2) -> void:
	var offset := pos - _center
	if offset.length() > radius:
		offset = offset.normalized() * radius
	_knob.position = _center + offset - _knob.size / 2.0
	output_vector = offset / radius

func _end_drag() -> void:
	_dragging = false
	_touch_index = -1
	output_vector = Vector2.ZERO
	_reset_knob()

func _reset_knob() -> void:
	_knob.position = _center - _knob.size / 2.0
