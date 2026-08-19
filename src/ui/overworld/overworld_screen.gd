# OverworldScreen — walkable Verdant Fields: a TileMap painted with danger
# tiers (OverworldTierLayout), a character body driven by joystick + keyboard
# input (OverworldMovement), a following Camera2D, and the encounter gauge
# HUD. Every physics frame reads the tier under the character, ticks
# EncounterSystem, and updates the gauge bar; on fire it band-picks a monster
# via EncounterSystem.pick_monster and opens CombatScreen as an instanced
# overlay, freezing movement/encounter ticking until it signals
# `combat_finished` (issue #21). Retreat still banks the run via the
# existing RunState.retreat() -> GameState.settle_run path and returns to
# launch.
extends Node2D

const OverworldMovement = preload("res://src/systems/overworld_movement.gd")
const OverworldTileset = preload("res://src/ui/overworld/overworld_tileset.gd")
const OverworldTierLayout = preload("res://src/systems/overworld_tier_layout.gd")
const EncounterSystem = preload("res://src/systems/encounter_system.gd")
const CombatScreenScene = preload("res://src/ui/combat/combat_screen.tscn")

const TILE_SIZE := 64
const MAP_COLS := 30
const MAP_ROWS := 40

@onready var tile_map: TileMap = %TileMap
@onready var character: CharacterBody2D = %Character
@onready var character_sprite: Sprite2D = %CharacterSprite
@onready var camera: Camera2D = %Camera
@onready var joystick: Control = %Joystick
@onready var retreat_button: Button = %RetreatButton
@onready var gauge_bar: ProgressBar = %GaugeBar
@onready var ui_layer: CanvasLayer = %UI

var _map_size: Vector2
var _tier_ids: Array = [0]
var _tier_table: TierTableDef = null
var _gauge := 0.0
var _rng := RandomNumberGenerator.new()
var _combat_active := false
var _combat_overlay: Control = null

func _ready() -> void:
	var run: RunState = GameState.current_run
	if run == null or run.status != "active":
		get_tree().change_scene_to_file("res://src/ui/launch/launch_screen.tscn")
		return

	_rng.randomize()
	_tier_table = GameState.tier_tables.get(run.zone_id)
	_build_tilemap()
	_build_character_sprite()
	_map_size = Vector2(MAP_COLS * TILE_SIZE, MAP_ROWS * TILE_SIZE)
	character.position = _map_size / 2.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(_map_size.x)
	camera.limit_bottom = int(_map_size.y)
	retreat_button.pressed.connect(_on_retreat_pressed)
	gauge_bar.min_value = 0.0
	gauge_bar.max_value = EncounterSystem.GAUGE_THRESHOLD
	gauge_bar.value = 0.0

func _build_tilemap() -> void:
	if _tier_table != null:
		_tier_ids = _tier_table.tiers.keys().map(func(k): return int(k))
		_tier_ids.sort()
	else:
		_tier_ids = [0]
	tile_map.tile_set = OverworldTileset.build(TILE_SIZE, _tier_ids)
	for x in range(MAP_COLS):
		for y in range(MAP_ROWS):
			var cell := Vector2i(x, y)
			var tier_id := OverworldTierLayout.tier_for_cell(cell, MAP_COLS, MAP_ROWS, _tier_ids)
			tile_map.set_cell(0, cell, tier_id, Vector2i.ZERO)

# Placeholder programmer-art marker (solid square) so the character reads
# against the tilemap without a hand-authored sprite asset.
func _build_character_sprite() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.9, 0.85, 0.2))
	character_sprite.texture = ImageTexture.create_from_image(img)

func _physics_process(delta: float) -> void:
	if GameState.current_run == null or _combat_active:
		return
	var keyboard_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var joystick_vector: Vector2 = joystick.output_vector if joystick != null else Vector2.ZERO
	var direction := OverworldMovement.combine_input(keyboard_vector, joystick_vector)
	character.position = OverworldMovement.step(character.position, direction, delta, _map_size)
	if direction != Vector2.ZERO:
		_tick_encounter()

func _tick_encounter() -> void:
	var cell := tile_map.local_to_map(character.position)
	var tier_id := tile_map.get_cell_source_id(0, cell)
	var tier_params: Dictionary = _tier_table.tier_params(tier_id) if _tier_table != null else {}

	var result := EncounterSystem.tick(tier_params, _gauge, _rng)
	_gauge = result["gauge"]
	gauge_bar.value = _gauge

	if result["fired"]:
		var run: RunState = GameState.current_run
		var zone: ZoneDef = GameState.zones.get(run.zone_id)
		var monster_id := EncounterSystem.pick_monster(zone, tier_params, GameState.monsters, _rng)
		if monster_id != "":
			GameState.pending_monster = GameState.monsters[monster_id]
			GameState.mark_bestiary_seen(monster_id)
			_start_combat()

# Opens CombatScreen as an instanced overlay over the (now-frozen) map and
# waits for its `combat_finished` signal; all outcome resolution happened
# already inside CombatScreen via RunState.resolve_fight.
func _start_combat() -> void:
	_combat_active = true
	retreat_button.visible = false
	if joystick != null:
		joystick.visible = false
	var overlay: Control = CombatScreenScene.instantiate()
	overlay.combat_finished.connect(_on_combat_finished)
	ui_layer.add_child(overlay)
	_combat_overlay = overlay

func _on_combat_finished(_result: Dictionary) -> void:
	if _combat_overlay != null:
		_combat_overlay.queue_free()
		_combat_overlay = null

	var run: RunState = GameState.current_run
	if run != null and run.status == "active":
		_combat_active = false
		_gauge = 0.0
		gauge_bar.value = 0.0
		retreat_button.visible = true
		if joystick != null:
			joystick.visible = true
		return

	if run != null:
		GameState.settle_run(run)
	GameState.current_run = null
	get_tree().change_scene_to_file("res://src/ui/launch/launch_screen.tscn")

func _on_retreat_pressed() -> void:
	var run: RunState = GameState.current_run
	run.retreat()
	GameState.settle_run(run)
	GameState.current_run = null
	get_tree().change_scene_to_file("res://src/ui/launch/launch_screen.tscn")
