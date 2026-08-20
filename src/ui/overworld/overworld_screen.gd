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

# Presentation-only: a tier is a "hot region" once it's in the upper half of
# the zone's danger tiers, driving the warning strip. Purely cosmetic — the
# gauge/encounter math it decorates is untouched (EncounterSystem.tick).
const GAUGE_COLOR_LOW := Color("#57c964")
const GAUGE_COLOR_HIGH := Color("#f5c542")
const EXIT_PULSE_PERIOD := 1.1
const MARKER_EDGE_MARGIN := 28.0

@onready var tile_map: TileMap = %TileMap
@onready var character: CharacterBody2D = %Character
@onready var character_sprite: Sprite2D = %CharacterSprite
@onready var camera: Camera2D = %Camera
@onready var joystick: Control = %Joystick
@onready var retreat_button: Button = %RetreatButton
@onready var gauge_bar: ProgressBar = %GaugeBar
@onready var hot_strip_label: Label = %HotStripLabel
@onready var exit_marker: Control = %ExitMarker
@onready var exit_marker_label: Label = %ExitMarkerLabel
@onready var ui_layer: CanvasLayer = %UI

var _map_size: Vector2
var _tier_ids: Array = [0]
var _tier_table: TierTableDef = null
var _gauge := 0.0
var _rng := RandomNumberGenerator.new()
var _combat_active := false
var _combat_overlay: Control = null
var _exit_cell: Vector2i
var _travel_target_zone_id := ""

func _ready() -> void:
	var run: RunState = GameState.current_run
	if run == null or run.status != "active":
		get_tree().change_scene_to_file("res://src/ui/launch/launch_screen.tscn")
		return

	_rng.randomize()
	_tier_table = GameState.tier_tables.get(run.zone_id)
	_build_tilemap()
	_build_character_sprite()
	_exit_cell = OverworldTierLayout.exit_cell(MAP_COLS, MAP_ROWS)
	var zone: ZoneDef = GameState.zones.get(run.zone_id)
	_travel_target_zone_id = zone.connections[0] if zone != null and not zone.connections.is_empty() else ""
	_map_size = Vector2(MAP_COLS * TILE_SIZE, MAP_ROWS * TILE_SIZE)
	character.position = _map_size / 2.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(_map_size.x)
	camera.limit_bottom = int(_map_size.y)
	# Snap the follow-camera onto the spawn point immediately so it never
	# starts at the map's top-left corner and slides in (also makes a
	# single-frame render represent real gameplay framing).
	camera.reset_smoothing()
	retreat_button.pressed.connect(_on_retreat_pressed)
	gauge_bar.min_value = 0.0
	gauge_bar.max_value = EncounterSystem.GAUGE_THRESHOLD
	gauge_bar.value = 0.0
	_build_gauge_style()
	hot_strip_label.visible = false
	var exit_zone: ZoneDef = GameState.zones.get(_travel_target_zone_id)
	exit_marker_label.text = "EXIT\n%s" % (exit_zone.name if exit_zone != null else "???")
	exit_marker.visible = _travel_target_zone_id != ""
	_start_exit_pulse()
	_update_exit_marker()
	_update_hot_strip(OverworldTierLayout.tier_for_cell(tile_map.local_to_map(character.position), MAP_COLS, MAP_ROWS, _tier_ids))

# Positions the exit marker over the exit cell's on-screen location, clamped
# to the viewport edges so it reads as a directional pointer toward the hot
# corner while the exit is off-camera, and lands on the tile once it scrolls
# into view. Runs in _process so it tracks the follow-camera every frame.
func _process(_delta: float) -> void:
	if not _combat_active:
		_update_exit_marker()

func _update_exit_marker() -> void:
	if _travel_target_zone_id == "":
		exit_marker.visible = false
		return
	# Needs a live viewport/camera transform; guard so instantiation off the
	# tree (e.g. the scene smoke test) never dereferences a null viewport.
	if not is_inside_tree() or get_viewport() == null:
		return
	var world := Vector2(_exit_cell) * float(TILE_SIZE) + Vector2(TILE_SIZE, TILE_SIZE) / 2.0
	var screen := get_viewport().get_canvas_transform() * world
	var vp := get_viewport_rect().size
	var half := exit_marker.size / 2.0
	screen.x = clampf(screen.x, MARKER_EDGE_MARGIN + half.x, vp.x - MARKER_EDGE_MARGIN - half.x)
	screen.y = clampf(screen.y, MARKER_EDGE_MARGIN + half.y, vp.y - MARKER_EDGE_MARGIN - half.y)
	exit_marker.position = screen - half

func _build_tilemap() -> void:
	if _tier_table != null:
		_tier_ids = _tier_table.tiers.keys().map(func(k): return int(k))
		_tier_ids.sort()
	else:
		_tier_ids = [0]
	tile_map.tile_set = OverworldTileset.build(TILE_SIZE, _tier_ids)
	var variant_count := OverworldTileset.variant_count()
	for x in range(MAP_COLS):
		for y in range(MAP_ROWS):
			var cell := Vector2i(x, y)
			var tier_id := OverworldTierLayout.tier_for_cell(cell, MAP_COLS, MAP_ROWS, _tier_ids)
			var tier_index := _tier_ids.find(tier_id)
			var distance := OverworldTierLayout.distance_ratio(cell, MAP_COLS, MAP_ROWS)
			var shade := OverworldTileset.shade_index_for_distance(distance, tier_index, _tier_ids.size())
			var variant := _rng.randi_range(0, variant_count - 1)
			tile_map.set_cell(0, cell, tier_id, Vector2i(variant, shade))

# Screen-space fade pulse on the exit marker. The marker's POSITION is driven
# by _update_exit_marker (it tracks the exit cell projected through the
# follow-camera, clamped to the viewport edges); this only animates its alpha.
func _start_exit_pulse() -> void:
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(exit_marker, "modulate:a", 0.45, EXIT_PULSE_PERIOD / 2.0)
	tween.tween_property(exit_marker, "modulate:a", 1.0, EXIT_PULSE_PERIOD / 2.0)

# Static green->gold gradient fill (issue #34); the gauge's live value still
# drives the bar's filled width via ProgressBar.value as usual, so no
# per-tick style rebuild is needed.
func _build_gauge_style() -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([GAUGE_COLOR_LOW, GAUGE_COLOR_HIGH])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 32
	texture.height = 4
	texture.fill_from = Vector2(0, 0.5)
	texture.fill_to = Vector2(1, 0.5)
	var fill := StyleBoxTexture.new()
	fill.texture = texture
	gauge_bar.add_theme_stylebox_override("fill", fill)

func _update_hot_strip(tier_id: int) -> void:
	var index := _tier_ids.find(tier_id)
	if index == -1:
		hot_strip_label.visible = false
		return
	hot_strip_label.visible = index >= int(ceili(_tier_ids.size() / 2.0))

# Placeholder programmer-art marker (bordered square + drop shadow, both
# baked into the texture) so the character reads against the tilemap without
# a hand-authored sprite asset.
func _build_character_sprite() -> void:
	const BODY_SIZE := 32
	const PAD := 8
	const SHADOW_OFFSET := 4
	const BORDER := 2
	var canvas := BODY_SIZE + PAD * 2
	var img := Image.create(canvas, canvas, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var body_color := Color(0.9, 0.85, 0.2)
	var border_color := body_color.darkened(0.45)
	var shadow_color := Color(0, 0, 0, 0.35)

	for x in range(BODY_SIZE):
		for y in range(BODY_SIZE):
			img.set_pixel(PAD + SHADOW_OFFSET + x, PAD + SHADOW_OFFSET + y, shadow_color)
	for x in range(BODY_SIZE):
		for y in range(BODY_SIZE):
			var is_border := x < BORDER or y < BORDER or x >= BODY_SIZE - BORDER or y >= BODY_SIZE - BORDER
			img.set_pixel(PAD + x, PAD + y, border_color if is_border else body_color)

	character_sprite.texture = ImageTexture.create_from_image(img)

func _physics_process(delta: float) -> void:
	if GameState.current_run == null or _combat_active:
		return
	var keyboard_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var joystick_vector: Vector2 = joystick.output_vector if joystick != null else Vector2.ZERO
	var direction := OverworldMovement.combine_input(keyboard_vector, joystick_vector)
	character.position = OverworldMovement.step(character.position, direction, delta, _map_size)
	if direction == Vector2.ZERO:
		return
	if _travel_target_zone_id != "" and tile_map.local_to_map(character.position) == _exit_cell:
		_travel_deeper()
		return
	_tick_encounter()

func _tick_encounter() -> void:
	var cell := tile_map.local_to_map(character.position)
	var tier_id := tile_map.get_cell_source_id(0, cell)
	var tier_params: Dictionary = _tier_table.tier_params(tier_id) if _tier_table != null else {}

	var result := EncounterSystem.tick(tier_params, _gauge, _rng)
	_gauge = result["gauge"]
	gauge_bar.value = _gauge
	_update_hot_strip(tier_id)

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

# Exit-tile travel (issue #22): reaching the exit cell unlocks the connected
# zone and moves the run there, then reloads this scene so it rebuilds the
# tilemap/tier table for the new zone_id. RunState itself (level, hunts,
# haul) is untouched by the reload.
func _travel_deeper() -> void:
	var run: RunState = GameState.current_run
	run.unlock_zone(_travel_target_zone_id)
	get_tree().reload_current_scene()

func _on_retreat_pressed() -> void:
	var run: RunState = GameState.current_run
	run.retreat()
	GameState.settle_run(run)
	GameState.current_run = null
	get_tree().change_scene_to_file("res://src/ui/launch/launch_screen.tscn")
