# OverworldScreen — walkable Verdant Fields: a TileMap painted with danger
# sections banded by RADIAL DISTANCE from the map center (SectionLayout, PRD
# issue #36: Concentric Sections), a character body driven by joystick +
# keyboard input (OverworldMovement), a following Camera2D, and the
# encounter gauge HUD. The player spawns at a center camp and travels
# outward toward a portal on the outer ring. Every physics frame reads the
# section under the character, ticks EncounterSystem, and updates the gauge
# bar; on fire it band-picks a monster via
# EncounterSystem.pick_monster and opens CombatScreen as an instanced
# overlay, freezing movement/encounter ticking until it signals
# `combat_finished` (issue #21). Retreat still banks the run via the
# existing RunState.retreat() -> GameState.settle_run path and returns to
# launch.
extends Node2D

const OverworldMovement = preload("res://src/systems/overworld_movement.gd")
const OverworldTileset = preload("res://src/ui/overworld/overworld_tileset.gd")
const SectionLayout = preload("res://src/systems/section_layout.gd")
const EncounterSystem = preload("res://src/systems/encounter_system.gd")
const PoiLayout = preload("res://src/systems/poi_layout.gd")
const CombatScreenScene = preload("res://src/ui/combat/combat_screen.tscn")

const TILE_SIZE := 64
const MAP_COLS := 30
const MAP_ROWS := 40

# Player walk sheet (4x4 grid of 64x64 frames). Rows = facing, cols = walk cycle.
const PLAYER_SHEET := preload("res://assets/sprites/player_ethan.png")
const FRAME_SIZE := 64
const WALK_COLS := 4
const WALK_FPS := 8.0
const FACE_DOWN := 0
const FACE_UP := 1
const FACE_LEFT := 2
const FACE_RIGHT := 3

# Presentation-only: a tier is a "hot region" once it's in the upper half of
# the zone's danger tiers, driving the warning strip. Purely cosmetic — the
# gauge/encounter math it decorates is untouched (EncounterSystem.tick).
const GAUGE_COLOR_LOW := Color("#57c964")
const GAUGE_COLOR_HIGH := Color("#f5b942")
const EXIT_PULSE_PERIOD := 1.1
const MARKER_EDGE_MARGIN := 28.0

# Section banner (issue #38): how long the on-enter banner holds fully
# visible after sliding in before it fades back out.
const SECTION_BANNER_HOLD := 1.6
const SECTION_BANNER_FADE := 0.35

# POI overlay (ADR-0001 slice B): small code-drawn tinted markers, one per
# PoiLayout.generate() entry, rendered above the tilemap. No new art assets.
const POI_MARKER_SIZE := 20
const POI_MARKER_COLORS := {
	"camp": Color("#4fd1c5"),
	"portal": Color("#f5b942"),
	"den": Color("#e05263"),
	"forage": Color("#8bd17c"),
	"cache": Color("#c9a13b"),
	"landmark": Color("#7c9cf5"),
}

# Den → spawn bias (ADR-0001 slice B): standing on/adjacent to a den cell
# multiplies the tier's gauge_rate before it's passed into the unchanged
# EncounterSystem.tick, so fights come denser near a den without forking the
# encounter system itself. Kept modest — a hint, not a trap.
const DEN_BIAS_RADIUS := 1
const DEN_GAUGE_MULTIPLIER := 1.5

@onready var tile_map: TileMap = %TileMap
@onready var character: CharacterBody2D = %Character
@onready var character_sprite: Sprite2D = %CharacterSprite
@onready var camera: Camera2D = %Camera
@onready var joystick: Control = %Joystick
@onready var retreat_button: Button = %RetreatButton
@onready var gauge_bar: ProgressBar = %GaugeBar
@onready var hot_strip_label: Label = %HotStripLabel
@onready var section_banner: Control = %SectionBanner
@onready var section_banner_label: Label = %SectionBannerLabel
@onready var exit_marker: Control = %ExitMarker
@onready var exit_marker_label: Label = %ExitMarkerLabel
@onready var ui_layer: CanvasLayer = %UI
@onready var sprite_toggle: CheckButton = %SpriteToggle

var _map_size: Vector2
var _tier_ids: Array = [0]
var _section_layout: Dictionary = {}
var _gauge := 0.0
var _rng := RandomNumberGenerator.new()
var _combat_active := false
var _combat_overlay: Control = null
var _exit_cell: Vector2i
var _travel_target_zone_id := ""
var _facing := FACE_DOWN
var _walk_col := 0
var _anim_accum := 0.0
var _pois: Array = []
var _den_cells: Array = []
var _zone_def: ZoneDef = null
var _current_section_id := -1
var _section_banner_tween: Tween = null

func _ready() -> void:
	var run: RunState = GameState.current_run
	if run == null or run.status != "active":
		get_tree().change_scene_to_file("res://src/ui/launch/launch_screen.tscn")
		return

	_rng.randomize()
	_zone_def = GameState.zones.get(run.zone_id)
	var min_level := _zone_def.min_level if _zone_def != null else 1.0
	var max_level := _zone_def.max_level if _zone_def != null else 8.0
	var band_names: Array = _zone_def.band_names if _zone_def != null else []
	_section_layout = SectionLayout.generate(MAP_COLS, MAP_ROWS, min_level, max_level, _rng, band_names)
	_exit_cell = _section_layout["portal"]
	_build_tilemap()
	_build_character_sprite()
	_build_poi_markers()
	_travel_target_zone_id = _zone_def.connections[0] if _zone_def != null and not _zone_def.connections.is_empty() else ""
	_map_size = Vector2(MAP_COLS * TILE_SIZE, MAP_ROWS * TILE_SIZE)
	var camp_cell: Vector2i = _section_layout["camp"]
	character.position = Vector2(camp_cell) * float(TILE_SIZE) + Vector2(TILE_SIZE, TILE_SIZE) / 2.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(_map_size.x)
	camera.limit_bottom = int(_map_size.y)
	# Snap the follow-camera onto the spawn point immediately so it never
	# starts at the map's top-left corner and slides in (also makes a
	# single-frame render represent real gameplay framing).
	camera.reset_smoothing()
	retreat_button.pressed.connect(_on_retreat_pressed)
	sprite_toggle.button_pressed = not DebugSettings.dots_enabled()
	sprite_toggle.toggled.connect(_on_sprite_toggle_toggled)
	gauge_bar.min_value = 0.0
	gauge_bar.max_value = EncounterSystem.GAUGE_THRESHOLD
	gauge_bar.value = 0.0
	_build_gauge_style()
	hot_strip_label.visible = false
	section_banner.visible = false
	var exit_zone: ZoneDef = GameState.zones.get(_travel_target_zone_id)
	exit_marker_label.text = "EXIT\n%s" % (exit_zone.name if exit_zone != null else "???")
	exit_marker.visible = _travel_target_zone_id != ""
	_start_exit_pulse()
	_update_exit_marker()
	# Spawn is inside a section already; establish it as the current section
	# and show the persistent badge, but don't fire the on-enter banner —
	# that's reserved for actually crossing a border during play.
	_current_section_id = SectionLayout.section_for_cell(tile_map.local_to_map(character.position), MAP_COLS, MAP_ROWS, _section_layout)
	_update_hot_strip(_current_section_id)

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
	_tier_ids = _section_layout["section_ids"]
	var palette: Array = _zone_def.palette if _zone_def != null and not _zone_def.palette.is_empty() else OverworldTileset.DEFAULT_PALETTE
	tile_map.tile_set = OverworldTileset.build(TILE_SIZE, _tier_ids, palette)
	var variant_count := OverworldTileset.variant_count()
	var path_cell_set: Dictionary = _section_layout["path_cell_set"]
	for x in range(MAP_COLS):
		for y in range(MAP_ROWS):
			var cell := Vector2i(x, y)
			var section_id := SectionLayout.section_for_cell(cell, MAP_COLS, MAP_ROWS, _section_layout)
			var section_index := _tier_ids.find(section_id)
			var variant := _rng.randi_range(0, variant_count - 1)
			# Concentric Sections (PRD issue #36): danger rises with radial
			# distance from the center camp, not row depth — the gradient
			# shade is keyed on SectionLayout.distance_ratio.
			var distance := SectionLayout.distance_ratio(cell, MAP_COLS, MAP_ROWS)
			var shade := OverworldTileset.shade_index_for_distance(distance, section_index, _tier_ids.size())
			# The visible optimal path (issue #39): on-path cells are painted
			# with the repurposed dirt-trail row instead of their normal
			# danger shade, so the camp -> portal route reads as a corridor.
			if path_cell_set.has(cell):
				shade = OverworldTileset.trail_shade_row()
			tile_map.set_cell(0, cell, section_id, Vector2i(variant, shade))

# Points-of-interest overlay (ADR-0001 slice B, re-homed onto the section map
# by issue #41): places PoiLayout's markers above the tilemap and remembers
# the den cells for the encounter-gauge bias in _tick_encounter. Reuses the
# screen's own _rng (already randomize()'d in _ready), so layout varies run
# to run like the tile variant jitter next to it; PoiLayout itself stays
# deterministic/unit-tested for a given seed. PoiLayout now places dens/
# forage/cache/landmarks directly off SectionLayout's radial distance and
# visible path, and sources camp/portal from the same layout, so the markers
# always match where the hunter actually spawns and travels.
func _build_poi_markers() -> void:
	_pois = PoiLayout.generate(MAP_COLS, MAP_ROWS, _section_layout, _rng)
	_den_cells.clear()

	var layer := Node2D.new()
	layer.name = "PoiLayer"
	layer.z_index = 5
	add_child(layer)
	# Owned + unique-named so tests can reach it via %PoiLayer like the rest
	# of this scene's structural smoke checks, even though it's built in code.
	layer.owner = self
	layer.unique_name_in_owner = true

	for poi in _pois:
		var poi_type: String = poi["type"]
		var cell: Vector2i = poi["cell"]
		if poi_type == "den":
			_den_cells.append(cell)
		var marker := Sprite2D.new()
		marker.name = "Poi_%s_%d_%d" % [poi_type, cell.x, cell.y]
		marker.texture = _poi_marker_texture(POI_MARKER_COLORS.get(poi_type, Color.WHITE))
		marker.position = Vector2(cell) * float(TILE_SIZE) + Vector2(TILE_SIZE, TILE_SIZE) / 2.0
		layer.add_child(marker)

# A small code-drawn filled circle with a darker rim, tinted per POI type —
# placeholder art (per the spec) assembled at runtime the same way
# OverworldTileset builds its tile atlas; no new art asset files.
func _poi_marker_texture(color: Color) -> ImageTexture:
	var size := POI_MARKER_SIZE
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	var center := float(size) / 2.0
	var radius := float(size) / 2.0 - 2.0
	for x in range(size):
		for y in range(size):
			var dist := Vector2(x - center, y - center).length()
			if dist <= radius:
				img.set_pixel(x, y, color)
			elif dist <= radius + 1.5:
				img.set_pixel(x, y, color.darkened(0.4))
	return ImageTexture.create_from_image(img)

# Den bias (ADR-0001 slice B): when `cell` is on or Chebyshev-adjacent to a
# den, returns a COPY of tier_params with gauge_rate multiplied up, so
# EncounterSystem.tick (unchanged) fires denser near a den. Untouched
# tier_params dict is returned as-is everywhere else.
func _apply_den_bias(tier_params: Dictionary, cell: Vector2i) -> Dictionary:
	for den_cell in _den_cells:
		if absi(cell.x - den_cell.x) <= DEN_BIAS_RADIUS and absi(cell.y - den_cell.y) <= DEN_BIAS_RADIUS:
			var boosted := tier_params.duplicate()
			boosted["gauge_rate"] = float(boosted.get("gauge_rate", 0.0)) * DEN_GAUGE_MULTIPLIER
			return boosted
	return tier_params

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

# Section name + recommended level for `tier_id` (a section id), e.g.
# "Bramble Hollow  Lv 4-7" — the generated per-section name (issue #41,
# SectionLayout params[id].name, derived from the zone's band_names) falls
# back to the plain band name if generation left it empty (e.g. a zone with
# no band_names). Falls back to "" when the tier/zone data isn't resolvable
# (defensive; every painted cell has a known tier in practice).
func _section_label(tier_id: int) -> String:
	var index := _tier_ids.find(tier_id)
	if index == -1 or _zone_def == null:
		return ""
	var tier_params: Dictionary = _section_layout.get("params", {}).get(tier_id, {})
	var section_name: String = tier_params.get("name", "")
	if section_name == "":
		section_name = _zone_def.band_name_for_tier_index(index, _tier_ids.size())
	var level_min := int(tier_params.get("level_min", 0))
	var level_max := int(tier_params.get("level_max", 0))
	return "%s  Lv %d-%d" % [section_name, level_min, level_max]

# Persistent HUD badge (issue #38): reuses the hot-strip slot to always show
# the section the hunter currently stands in, not just its former "hot
# region" warning. Still intensifies the ⚠ marker once the section is in the
# upper half of the zone's danger tiers, matching the prior hot-strip cue.
func _update_hot_strip(tier_id: int) -> void:
	var index := _tier_ids.find(tier_id)
	var label := _section_label(tier_id)
	if index == -1 or label == "":
		hot_strip_label.visible = false
		return
	var is_hot := index >= int(ceili(_tier_ids.size() / 2.0))
	hot_strip_label.visible = true
	hot_strip_label.text = "%s %s" % ["⚠" if is_hot else "▸", label]

# On-enter banner (issue #38): slides in over the map when a border crossing
# resolves the hunter into a new section, holds briefly, then fades out.
# Killing/replacing any in-flight tween lets rapid border hops (e.g. walking
# back and forth on a boundary) restart cleanly instead of stacking tweens.
func _show_section_banner(tier_id: int) -> void:
	var label := _section_label(tier_id)
	if label == "":
		return
	section_banner_label.text = label
	section_banner.visible = true
	section_banner.modulate.a = 1.0
	if _section_banner_tween != null and _section_banner_tween.is_valid():
		_section_banner_tween.kill()
	_section_banner_tween = create_tween()
	_section_banner_tween.tween_interval(SECTION_BANNER_HOLD)
	_section_banner_tween.tween_property(section_banner, "modulate:a", 0.0, SECTION_BANNER_FADE)
	_section_banner_tween.tween_callback(func(): section_banner.visible = false)

# Player character sprite: a Gen-4-style humanoid overworld walk sheet
# (assets/sprites/player_ethan.png, a 4x4 grid of 64x64 frames — rows are
# DOWN / UP / LEFT / RIGHT, columns are the 4-frame walk cycle). The sprite
# shows one region cell; _physics_process picks the facing row from the
# movement direction and cycles the walk columns while moving, holding the
# idle column (0) when standing still.
func _build_character_sprite() -> void:
	character_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	character_sprite.centered = true
	if DebugSettings.dots_enabled():
		_build_dot_character_sprite()
		return
	character_sprite.texture = PLAYER_SHEET
	character_sprite.region_enabled = true
	# Scale the sprite up so the hunter reads clearly against the 64px tiles,
	# and lift it (offset compensated for the scale) so the feet stay grounded
	# on the tile rather than drawing centered through the body position.
	character_sprite.scale = Vector2(1.35, 1.35)
	character_sprite.offset = Vector2(0, -19)
	_set_player_frame(FACE_DOWN, 0)

# Debug dot mode: the player renders as a plain 1px dot marker (scaled up so
# it's visible) centered on the character body instead of the walk sheet. No
# region/facing/walk-cycle — the dot is orientation-agnostic.
func _build_dot_character_sprite() -> void:
	character_sprite.region_enabled = false
	character_sprite.texture = DebugSettings.dot_texture()
	character_sprite.scale = Vector2(DebugSettings.DOT_DISPLAY_SCALE, DebugSettings.DOT_DISPLAY_SCALE)
	character_sprite.offset = Vector2.ZERO

# Shows one 64x64 cell of the walk sheet (row = facing, col = walk frame).
func _set_player_frame(row: int, col: int) -> void:
	character_sprite.region_rect = Rect2(col * FRAME_SIZE, row * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)

# Maps a movement vector to a facing row; the dominant axis wins.
func _facing_for(direction: Vector2) -> int:
	if absf(direction.x) > absf(direction.y):
		return FACE_RIGHT if direction.x > 0.0 else FACE_LEFT
	return FACE_DOWN if direction.y > 0.0 else FACE_UP

# Advances the walk-cycle column while moving; resets to the idle column when
# standing still. Called every physics frame with the frame delta.
func _animate_walk(direction: Vector2, delta: float) -> void:
	# Dot mode has no walk sheet / facing rows to cycle — leave the dot as-is.
	if DebugSettings.dots_enabled():
		return
	if direction == Vector2.ZERO:
		_anim_accum = 0.0
		_walk_col = 0
		_set_player_frame(_facing, 0)
		return
	_facing = _facing_for(direction)
	_anim_accum += delta
	var step := 1.0 / WALK_FPS
	while _anim_accum >= step:
		_anim_accum -= step
		_walk_col = (_walk_col + 1) % WALK_COLS
	_set_player_frame(_facing, _walk_col)

func _physics_process(delta: float) -> void:
	if GameState.current_run == null or _combat_active:
		return
	var keyboard_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var joystick_vector: Vector2 = joystick.output_vector if joystick != null else Vector2.ZERO
	var direction := OverworldMovement.combine_input(keyboard_vector, joystick_vector)
	character.position = OverworldMovement.step(character.position, direction, delta, _map_size)
	_animate_walk(direction, delta)
	if direction == Vector2.ZERO:
		return
	if _travel_target_zone_id != "" and tile_map.local_to_map(character.position) == _exit_cell:
		_travel_deeper()
		return
	_tick_encounter(delta)

func _tick_encounter(delta: float) -> void:
	var cell := tile_map.local_to_map(character.position)
	var tier_id := SectionLayout.section_for_cell(cell, MAP_COLS, MAP_ROWS, _section_layout)
	if tier_id != _current_section_id:
		_current_section_id = tier_id
		_gauge = 0.0
		gauge_bar.value = 0.0
		_show_section_banner(tier_id)
	var tier_params: Dictionary = _section_layout.get("params", {}).get(tier_id, {})
	tier_params = _apply_den_bias(tier_params, cell)

	var result := EncounterSystem.tick(tier_params, _gauge, _rng, delta)
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

# In-game debug switch: pressed = real sprites, released = 1px dot mode.
# Flips the global DebugSettings flag and live-rebuilds the player sprite so
# the change is visible immediately; combat (instanced per fight) reads the
# flag fresh when it next opens.
func _on_sprite_toggle_toggled(button_pressed: bool) -> void:
	DebugSettings.sprites_as_dots = not button_pressed
	_build_character_sprite()

func _on_retreat_pressed() -> void:
	var run: RunState = GameState.current_run
	run.retreat()
	GameState.settle_run(run)
	GameState.current_run = null
	get_tree().change_scene_to_file("res://src/ui/launch/launch_screen.tscn")
