# Scene-smoke tests (issue #28) — the highest UI seam achievable headless.
# Instantiates every screen scene, runs its _ready() clean (with minimal
# GameState set up for the combat/overworld overlays), and asserts the
# project-wide pixel Theme is applied and the vendored fonts load. This does
# NOT assert pixels/layout — aesthetics are reviewed via scripts/screenshot.sh
# out-of-band. Later slices (#29-#31) extend this file's assertions for the
# screen they restructure.
extends "res://tests/test_case.gd"

const PIXEL_THEME_PATH := "res://assets/theme/pixel_theme.tres"
const PRESS_START_PATH := "res://assets/fonts/press_start_2p/PressStart2P-Regular.woff2"
const VT323_PATH := "res://assets/fonts/vt323/VT323-Regular.woff2"

const LAUNCH_SCENE := "res://src/ui/launch/launch_screen.tscn"
const OVERWORLD_SCENE := "res://src/ui/overworld/overworld_screen.tscn"
const COMBAT_SCENE := "res://src/ui/combat/combat_screen.tscn"
const INVENTORY_SCENE := "res://src/ui/inventory/inventory_screen.tscn"
const BESTIARY_SCENE := "res://src/ui/bestiary/bestiary_screen.tscn"
const META_SCENE := "res://src/ui/meta/meta_screen.tscn"

# Clean any run state left by a previous test so screens that don't touch
# GameState.current_run/pending_monster aren't affected by ones that do.
# Also ensures GameState's content/save/inventory are loaded: GameState is an
# autoload so it's already in the SceneTree by the time this script runs, but
# headless `--script` runs (tests/run_tests.gd) never flush the deferred
# NOTIFICATION_READY that would normally call its _ready() — so without this,
# GameState.zones/monsters/inventory are all still empty/null. Force it once
# here rather than relying on engine frame timing every screen depends on.
func before_each() -> void:
	if GameState.zones.is_empty():
		GameState._ready()
	GameState.current_run = null
	GameState.pending_monster = null

func after_each() -> void:
	GameState.current_run = null
	GameState.pending_monster = null

func _tree() -> SceneTree:
	return Engine.get_main_loop()

func _instantiate(scene_path: String) -> Node:
	var packed: PackedScene = load(scene_path)
	assert_not_null(packed, "failed to load %s" % scene_path)
	var node: Node = packed.instantiate()
	_tree().root.add_child(node)
	return node

func _cleanup(node: Node) -> void:
	if node == null:
		return
	_tree().root.remove_child(node)
	node.free()

func _setup_minimal_run() -> void:
	# Minimal GameState for the combat/overworld overlays: a live RunState in
	# a real zone plus a pending_monster pulled from loaded content, per the
	# combat/overworld screens' _ready() dependencies (see run_state.gd /
	# game_state.gd).
	var zone_id: String = GameState.zones.keys()[0]
	GameState.current_run = RunState.start(zone_id, "", {}, RunState.DEFAULT_HUNTS)
	var monster_id: String = GameState.monsters.keys()[0]
	GameState.pending_monster = GameState.monsters[monster_id]

# --- Theme / font foundation -------------------------------------------------

func test_project_theme_is_pixel_theme() -> void:
	var project_theme: Theme = ThemeDB.get_project_theme()
	assert_not_null(project_theme, "ThemeDB.get_project_theme() must be non-null")
	var pixel_theme: Theme = load(PIXEL_THEME_PATH)
	assert_not_null(pixel_theme, "pixel_theme.tres must load")
	assert_eq(project_theme.resource_path, pixel_theme.resource_path,
		"project default GUI theme must be assets/theme/pixel_theme.tres")

func test_vendored_fonts_load() -> void:
	var press_font: Resource = load(PRESS_START_PATH)
	assert_not_null(press_font, "Press Start 2P must load")
	assert_true(press_font is FontFile, "Press Start 2P must load as a FontFile")

	var vt_font: Resource = load(VT323_PATH)
	assert_not_null(vt_font, "VT323 must load")
	assert_true(vt_font is FontFile, "VT323 must load as a FontFile")

# --- Screen smoke: instantiate, _ready() runs clean, theme inherited --------

func _assert_control_inherits_project_theme(control: Control) -> void:
	assert_true(control is Control, "screen root must be a Control")
	assert_true(control.theme == null,
		"screen root must not set a per-scene theme override (inherits the project theme)")

func test_launch_screen_smoke() -> void:
	var screen: Control = _instantiate(LAUNCH_SCENE)
	_assert_control_inherits_project_theme(screen)
	var essence_label: Label = screen.get_node("%EssenceLabel")
	assert_not_null(essence_label, "launch %EssenceLabel must exist")
	var zone_swatch: ColorRect = screen.get_node("%ZoneSwatch")
	assert_not_null(zone_swatch, "launch %ZoneSwatch must exist")
	var zone_name_label: Label = screen.get_node("%ZoneNameLabel")
	assert_not_null(zone_name_label, "launch %ZoneNameLabel must exist")
	assert_true(zone_name_label.text != "", "zone card must show a selected zone name")
	var weapon_icon: TextureRect = screen.get_node("%WeaponIcon")
	assert_not_null(weapon_icon, "launch %WeaponIcon must exist")
	var weapon_name_label: Label = screen.get_node("%WeaponNameLabel")
	assert_not_null(weapon_name_label, "launch %WeaponNameLabel must exist")
	assert_eq(weapon_name_label.text, "( none )", "fresh save must show no equipped weapon")
	var start_button: Button = screen.get_node("%StartButton")
	assert_not_null(start_button, "launch %StartButton must exist")
	var nav_buttons := [screen.get_node("%InventoryButton"), screen.get_node("%BestiaryButton"), screen.get_node("%MetaButton")]
	for nav_button in nav_buttons:
		assert_not_null(nav_button, "launch nav buttons must exist")
	_cleanup(screen)

func test_inventory_screen_smoke() -> void:
	var screen: Control = _instantiate(INVENTORY_SCENE)
	_assert_control_inherits_project_theme(screen)
	_cleanup(screen)

func test_bestiary_screen_smoke() -> void:
	var screen: Control = _instantiate(BESTIARY_SCENE)
	_assert_control_inherits_project_theme(screen)
	_cleanup(screen)

func test_meta_screen_smoke() -> void:
	var screen: Control = _instantiate(META_SCENE)
	_assert_control_inherits_project_theme(screen)
	_cleanup(screen)

func test_combat_screen_smoke() -> void:
	_setup_minimal_run()
	var screen: Control = _instantiate(COMBAT_SCENE)
	_assert_control_inherits_project_theme(screen)
	_cleanup(screen)

func test_overworld_screen_smoke() -> void:
	_setup_minimal_run()
	var screen: Node2D = _instantiate(OVERWORLD_SCENE)
	assert_true(screen is Node2D, "overworld screen root is a Node2D")
	# The overworld's HUD lives under its %UI CanvasLayer; those Control
	# children inherit the project theme the same way the full-Control
	# screens do.
	var ui_layer: CanvasLayer = screen.get_node("%UI")
	assert_not_null(ui_layer, "overworld %UI CanvasLayer must exist")
	var retreat_button: Button = screen.get_node("%RetreatButton")
	assert_not_null(retreat_button, "overworld %RetreatButton must exist")
	assert_true(retreat_button.theme == null,
		"overworld HUD controls must not set a per-scene theme override")
	_cleanup(screen)
