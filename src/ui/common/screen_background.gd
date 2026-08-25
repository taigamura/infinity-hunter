# Full-rect screen background (issue #32) — a `Theme` cannot paint a root
# background, so each screen that needs the mockup's dark-navy backdrop
# (instead of Godot's default grey) gets one of these as its first child.
# Draws a vertical or radial two-stop gradient, plus an optional faint grid
# overlay (launch only). Presentation-only; carries no game state.
extends Control

enum Mode { LINEAR, RADIAL }

@export var mode: Mode = Mode.LINEAR
@export var top_color: Color = Color("#14171f")
@export var bottom_color: Color = Color("#0f1218")
@export var show_grid: bool = false
@export var grid_step: int = 48
@export var grid_color: Color = Color(90.0 / 255.0, 110.0 / 255.0, 160.0 / 255.0, 0.05)

const RADIAL_STEPS := 40

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	if mode == Mode.RADIAL:
		_draw_radial()
	else:
		_draw_linear()
	if show_grid:
		_draw_grid()

func _draw_linear() -> void:
	# A single quad with per-vertex colors: the GPU interpolates top->bottom,
	# which is exactly a vertical linear gradient.
	var points := PackedVector2Array([Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, size.y), Vector2(0, size.y)])
	var colors := PackedColorArray([top_color, top_color, bottom_color, bottom_color])
	draw_polygon(points, colors)

func _draw_radial() -> void:
	# Concentric circles centred at top-middle, drawn outside-in so the
	# lighter centre color ends up on top -- approximates a radial gradient
	# without a shader.
	var center := Vector2(size.x * 0.5, 0.0)
	var max_r := size.length()
	for i in range(RADIAL_STEPS, -1, -1):
		var t := float(i) / float(RADIAL_STEPS)
		draw_circle(center, max_r * t, top_color.lerp(bottom_color, t))

func _draw_grid() -> void:
	var x := 0.0
	while x <= size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), grid_color, 1.0)
		x += grid_step
	var y := 0.0
	while y <= size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), grid_color, 1.0)
		y += grid_step
