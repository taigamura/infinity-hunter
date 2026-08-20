# Builds assets/theme/pixel_theme.tres — the project-wide pixel-art Theme
# (issue #28). Constructed in code (rather than hand-writing the .tres text
# format) so the StyleBox/font wiring is easy to review and regenerate; run
# once via:
#   godot --headless --path . --script res://assets/theme/_gen/build_theme.gd
# Mirrors the assets/weapons/_gen/ convention: a small generator kept next to
# its output for reproducibility.
extends SceneTree

const PRESS_START := "res://assets/fonts/press_start_2p/PressStart2P-Regular.woff2"
const VT323 := "res://assets/fonts/vt323/VT323-Regular.woff2"
const OUT_PATH := "res://assets/theme/pixel_theme.tres"

# Dark-navy panel palette, gold #f5c542 primary accent.
const COLOR_BG_NAVY := Color("#0e1220")
const COLOR_PANEL := Color("#121a2c")
const COLOR_PANEL_BORDER := Color("#33415e")
const COLOR_GOLD := Color("#f5c542")
const COLOR_GOLD_DIM := Color("#c79a2e")
const COLOR_TEXT := Color("#e7e9f0")
const COLOR_TEXT_DIM := Color("#9aa3b8")
const COLOR_BUTTON_NORMAL := Color("#1c273f")
const COLOR_BUTTON_HOVER := Color("#26355a")
const COLOR_BUTTON_PRESSED := Color("#0f1626")
const COLOR_BUTTON_DISABLED := Color("#161d2e")

# Card family (issue #32 fidelity pass) — bg/border shared by all
# Panel/PanelContainer instances (zone/weapon cards, combat top panel,
# result overlay, etc).
const COLOR_CARD_BG := Color("#1b2030")
const COLOR_CARD_BORDER := Color("#39415a")

# Essence pill (issue #32).
const COLOR_PILL_BG := Color("#1c2130")
const COLOR_PILL_BORDER := Color("#39415a")

# HP bar track (issue #32) — shared by the monster/player gradient fills.
const COLOR_HP_TRACK_BG := Color("#0c0f16")
const COLOR_HP_TRACK_BORDER := Color("#495168")

# Builds a two/three-stop vertical (or custom-direction) gradient texture,
# used where StyleBoxFlat's flat bg_color can't express a gradient fill
# (START button, HP bars).
static func _gradient_texture(stops: Array, tex_size: Vector2i, fill_from: Vector2, fill_to: Vector2) -> GradientTexture2D:
	var grad := Gradient.new()
	var colors := PackedColorArray()
	var offsets := PackedFloat32Array()
	for stop in stops:
		offsets.append(stop[0])
		colors.append(stop[1])
	grad.offsets = offsets
	grad.colors = colors
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = tex_size.x
	tex.height = tex_size.y
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = fill_from
	tex.fill_to = fill_to
	return tex

func _initialize() -> void:
	var theme := Theme.new()

	var press_font: FontFile = load(PRESS_START)
	var vt_font: FontFile = load(VT323)
	if press_font == null or vt_font == null:
		push_error("build_theme: failed to load vendored fonts")
		quit(1)
		return

	# Default: Press Start 2P everywhere (headers/labels/buttons). VT323 is
	# applied to RichTextLabel, which is the one control this UI uses for
	# larger blocks of descriptive text.
	theme.default_font = press_font
	theme.default_font_size = 12

	theme.set_font("font", "Label", press_font)
	theme.set_font_size("font_size", "Label", 12)
	theme.set_color("font_color", "Label", COLOR_TEXT)

	theme.set_font("font", "Button", press_font)
	theme.set_font_size("font_size", "Button", 12)
	theme.set_color("font_color", "Button", COLOR_TEXT)
	theme.set_color("font_hover_color", "Button", COLOR_GOLD)
	theme.set_color("font_pressed_color", "Button", COLOR_GOLD)
	theme.set_color("font_disabled_color", "Button", COLOR_TEXT_DIM)

	theme.set_font("font", "RichTextLabel", vt_font)
	theme.set_font_size("normal_font_size", "RichTextLabel", 18)
	theme.set_color("default_color", "RichTextLabel", COLOR_TEXT)

	theme.set_font("font", "OptionButton", press_font)
	theme.set_font_size("font_size", "OptionButton", 12)
	theme.set_color("font_color", "OptionButton", COLOR_TEXT)

	theme.set_font("font", "LineEdit", vt_font)
	theme.set_font_size("font_size", "LineEdit", 18)
	theme.set_color("font_color", "LineEdit", COLOR_TEXT)

	# --- Panel: card-navy fill, lighter border, rounded corners. ---
	var panel_box := StyleBoxFlat.new()
	panel_box.bg_color = COLOR_CARD_BG
	panel_box.border_color = COLOR_CARD_BORDER
	panel_box.set_border_width_all(2)
	panel_box.set_corner_radius_all(14)
	panel_box.set_content_margin_all(10)
	theme.set_stylebox("panel", "Panel", panel_box)

	var panel_container_box := panel_box.duplicate()
	theme.set_stylebox("panel", "PanelContainer", panel_container_box)

	# --- Button: beveled look via normal/hover/pressed/disabled StyleBoxFlats. ---
	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = COLOR_BUTTON_NORMAL
	btn_normal.border_color = COLOR_GOLD_DIM
	btn_normal.set_border_width_all(2)
	btn_normal.border_width_bottom = 4 # beveled: thicker bottom edge reads as depth
	btn_normal.set_corner_radius_all(6)
	btn_normal.set_content_margin_all(10)

	var btn_hover := btn_normal.duplicate()
	btn_hover.bg_color = COLOR_BUTTON_HOVER
	btn_hover.border_color = COLOR_GOLD

	var btn_pressed := btn_normal.duplicate()
	btn_pressed.bg_color = COLOR_BUTTON_PRESSED
	btn_pressed.border_width_bottom = 2
	btn_pressed.border_width_top = 4 # pressed: bevel flips (looks "pushed in")

	var btn_disabled := btn_normal.duplicate()
	btn_disabled.bg_color = COLOR_BUTTON_DISABLED
	btn_disabled.border_color = COLOR_PANEL_BORDER

	var btn_focus := btn_normal.duplicate()
	btn_focus.border_color = COLOR_GOLD
	btn_focus.draw_center = false

	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("disabled", "Button", btn_disabled)
	theme.set_stylebox("focus", "Button", btn_focus)

	# OptionButton reuses the same beveled family.
	theme.set_stylebox("normal", "OptionButton", btn_normal)
	theme.set_stylebox("hover", "OptionButton", btn_hover)
	theme.set_stylebox("pressed", "OptionButton", btn_pressed)
	theme.set_stylebox("disabled", "OptionButton", btn_disabled)
	theme.set_stylebox("focus", "OptionButton", btn_focus)

	# --- ProgressBar: bordered fill + background. ---
	var progress_bg := StyleBoxFlat.new()
	progress_bg.bg_color = COLOR_BG_NAVY
	progress_bg.border_color = COLOR_PANEL_BORDER
	progress_bg.set_border_width_all(2)
	progress_bg.set_corner_radius_all(4)

	var progress_fill := StyleBoxFlat.new()
	progress_fill.bg_color = COLOR_GOLD
	progress_fill.border_color = COLOR_GOLD_DIM
	progress_fill.set_border_width_all(2)
	progress_fill.set_corner_radius_all(4)

	theme.set_stylebox("background", "ProgressBar", progress_bg)
	theme.set_stylebox("fill", "ProgressBar", progress_fill)
	theme.set_font("font", "ProgressBar", press_font)
	theme.set_font_size("font_size", "ProgressBar", 10)
	theme.set_color("font_color", "ProgressBar", COLOR_TEXT)

	# --- EssencePill: distinct pill bg/border via a PanelContainer type variation. ---
	var pill_box := StyleBoxFlat.new()
	pill_box.bg_color = COLOR_PILL_BG
	pill_box.border_color = COLOR_PILL_BORDER
	pill_box.set_border_width_all(2)
	pill_box.set_corner_radius_all(10)
	pill_box.set_content_margin_all(8)
	theme.set_type_variation("EssencePill", "PanelContainer")
	theme.set_stylebox("panel", "EssencePill", pill_box)

	# --- StartButton: green gradient fill w/ darker bottom edge (issue #32). ---
	var start_tex := _gradient_texture([
		[0.0, Color("#6ce27a")],
		[0.82, Color("#46b357")],
		[1.0, Color("#2f7a3a")],
	], Vector2i(4, 32), Vector2(0.5, 0.0), Vector2(0.5, 1.0))
	var start_normal := StyleBoxTexture.new()
	start_normal.texture = start_tex
	start_normal.set_content_margin_all(10)
	var start_hover := StyleBoxTexture.new()
	start_hover.texture = start_tex
	start_hover.set_content_margin_all(10)
	start_hover.modulate_color = Color(1.08, 1.08, 1.08)
	var start_pressed := StyleBoxTexture.new()
	start_pressed.texture = start_tex
	start_pressed.set_content_margin_all(10)
	start_pressed.modulate_color = Color(0.85, 0.85, 0.85)

	theme.set_type_variation("StartButton", "Button")
	theme.set_stylebox("normal", "StartButton", start_normal)
	theme.set_stylebox("hover", "StartButton", start_hover)
	theme.set_stylebox("pressed", "StartButton", start_pressed)
	theme.set_stylebox("disabled", "StartButton", start_normal)
	theme.set_stylebox("focus", "StartButton", start_normal)
	theme.set_font("font", "StartButton", press_font)
	theme.set_font_size("font_size", "StartButton", 16)
	theme.set_color("font_color", "StartButton", Color("#12261a"))
	theme.set_color("font_hover_color", "StartButton", Color("#12261a"))
	theme.set_color("font_pressed_color", "StartButton", Color("#12261a"))

	# --- HP bars: shared dark track + red (monster) / green (player)
	# gradient fills, exposed as ProgressBar type variations. ---
	var hp_track := StyleBoxFlat.new()
	hp_track.bg_color = COLOR_HP_TRACK_BG
	hp_track.border_color = COLOR_HP_TRACK_BORDER
	hp_track.set_border_width_all(2)
	hp_track.set_corner_radius_all(4)

	var monster_hp_tex := _gradient_texture([
		[0.0, Color("#ff5a3c")],
		[1.0, Color("#cc331a")],
	], Vector2i(4, 32), Vector2(0.5, 0.0), Vector2(0.5, 1.0))
	var monster_hp_fill := StyleBoxTexture.new()
	monster_hp_fill.texture = monster_hp_tex

	var player_hp_tex := _gradient_texture([
		[0.0, Color("#6ce27a")],
		[1.0, Color("#46b357")],
	], Vector2i(4, 32), Vector2(0.5, 0.0), Vector2(0.5, 1.0))
	var player_hp_fill := StyleBoxTexture.new()
	player_hp_fill.texture = player_hp_tex

	theme.set_type_variation("MonsterHpBar", "ProgressBar")
	theme.set_stylebox("background", "MonsterHpBar", hp_track)
	theme.set_stylebox("fill", "MonsterHpBar", monster_hp_fill)
	theme.set_font("font", "MonsterHpBar", press_font)
	theme.set_font_size("font_size", "MonsterHpBar", 10)

	theme.set_type_variation("PlayerHpBar", "ProgressBar")
	theme.set_stylebox("background", "PlayerHpBar", hp_track)
	theme.set_stylebox("fill", "PlayerHpBar", player_hp_fill)
	theme.set_font("font", "PlayerHpBar", press_font)
	theme.set_font_size("font_size", "PlayerHpBar", 10)

	# --- PanelContainer/Control background convenience for full-screen roots. ---
	var root_box := StyleBoxFlat.new()
	root_box.bg_color = COLOR_BG_NAVY
	theme.set_stylebox("panel", "root_background", root_box)

	var err := ResourceSaver.save(theme, OUT_PATH)
	if err != OK:
		push_error("build_theme: failed to save theme, error %d" % err)
		quit(1)
		return

	print("build_theme: wrote %s" % OUT_PATH)
	quit(0)
