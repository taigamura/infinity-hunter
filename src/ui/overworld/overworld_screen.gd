# OverworldScreen — walkable Verdant Fields: a TileMap for the zone, a
# character body driven by joystick + keyboard input (OverworldMovement), and
# a following Camera2D. Retreat banks the run via the existing
# RunState.retreat() -> GameState.settle_run path and returns to launch, same
# as the old node-map. No encounters/combat yet (issue #19); the gauge-driven
# encounter overlay lands in a later slice without touching this scene's
# movement/retreat wiring.
extends Node2D

const OverworldMovement = preload("res://src/systems/overworld_movement.gd")
const OverworldTileset = preload("res://src/ui/overworld/overworld_tileset.gd")

const TILE_SIZE := 64
const MAP_COLS := 30
const MAP_ROWS := 40

@onready var tile_map: TileMap = %TileMap
@onready var character: CharacterBody2D = %Character
@onready var character_sprite: Sprite2D = %CharacterSprite
@onready var camera: Camera2D = %Camera
@onready var joystick: Control = %Joystick
@onready var retreat_button: Button = %RetreatButton

var _map_size: Vector2

func _ready() -> void:
	var run: RunState = GameState.current_run
	if run == null or run.status != "active":
		get_tree().change_scene_to_file("res://src/ui/launch/launch_screen.tscn")
		return

	_build_tilemap()
	_build_character_sprite()
	_map_size = Vector2(MAP_COLS * TILE_SIZE, MAP_ROWS * TILE_SIZE)
	character.position = _map_size / 2.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(_map_size.x)
	camera.limit_bottom = int(_map_size.y)
	retreat_button.pressed.connect(_on_retreat_pressed)

func _build_tilemap() -> void:
	tile_map.tile_set = OverworldTileset.build(TILE_SIZE)
	for x in range(MAP_COLS):
		for y in range(MAP_ROWS):
			tile_map.set_cell(0, Vector2i(x, y), 0, Vector2i.ZERO)

# Placeholder programmer-art marker (solid square) so the character reads
# against the tilemap without a hand-authored sprite asset.
func _build_character_sprite() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.9, 0.85, 0.2))
	character_sprite.texture = ImageTexture.create_from_image(img)

func _physics_process(delta: float) -> void:
	if GameState.current_run == null:
		return
	var keyboard_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var joystick_vector: Vector2 = joystick.output_vector if joystick != null else Vector2.ZERO
	var direction := OverworldMovement.combine_input(keyboard_vector, joystick_vector)
	character.position = OverworldMovement.step(character.position, direction, delta, _map_size)

func _on_retreat_pressed() -> void:
	var run: RunState = GameState.current_run
	run.retreat()
	GameState.settle_run(run)
	GameState.current_run = null
	get_tree().change_scene_to_file("res://src/ui/launch/launch_screen.tscn")
