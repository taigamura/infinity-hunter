# Builds assets/theme/pixel_theme.tres — the project-wide pixel-art Theme
# (issue #28, retuned to the "Signal" direction). Constructed in code (rather
# than hand-writing the .tres text format) so the StyleBox/font wiring is easy
# to review and regenerate; run once via:
#   godot --headless --path . --script res://assets/theme/_gen/build_theme.gd
# Mirrors the assets/weapons/_gen/ convention: a small generator kept next to
# its output for reproducibility.
#
# SIGNAL SYSTEM (locked direction): one cool-dark ground, no bevels, no
# gradients on chrome, no rounded cards. Panels become surfaces separated by
# 1px rules (corner radius 14 -> 3). Amber is the ONLY action color; red is
# threat/low, teal is you/good. See the "Signal UI Kit" design artifact.
extends SceneTree

const PRESS_START := "res://assets/fonts/press_start_2p/PressStart2P-Regular.woff2"
const VT323 := "res://assets/fonts/vt323/VT323-Regular.woff2"
const OUT_PATH := "res://assets/theme/pixel_theme.tres"

# --- Signal palette (6 load-bearing tokens + neutrals). ---
const COLOR_GROUND := Color("#12151c")    # base background (passes the navy gate: dark + blue-leaning)
const COLOR_SURFACE := Color("#171b24")   # raised surface (panels, buttons, rows)
const COLOR_RULE := Color("#232834")      # hairline rule / border
const COLOR_BORDER := Color("#2a3140")    # ghost-button / interactive outline
const COLOR_AMBER := Color("#f5b942")     # the one action color
const COLOR_AMBER_HI := Color("#ffca5c")  # amber hover
const COLOR_AMBER_LO := Color("#d89f2e")  # amber pressed
const COLOR_INK := Color("#12151c")       # text on top of amber
const COLOR_RED := Color("#ff5147")       # threat / monster HP / low
const COLOR_TEAL := Color("#4bd4a0")      # you / player HP / good
const COLOR_TEXT := Color("#e8eaed")
const COLOR_TEXT_DIM := Color("#79808f")
const COLOR_TRACK := Color("#222834")     # bar/segment track

# Button interaction backgrounds (flat, no bevel).
const COLOR_BTN_NORMAL := COLOR_SURFACE
const COLOR_BTN_HOVER := Color("#1d2431")
const COLOR_BTN_PRESSED := Color("#0e1119")
const COLOR_BTN_DISABLED := Color("#14171f")

func _initialize() -> void:
	var theme := Theme.new()

	var press_font: FontFile = load(PRESS_START)
	var vt_font: FontFile = load(VT323)
	if press_font == null or vt_font == null:
		push_error("build_theme: failed to load vendored fonts")
		quit(1)
		return

	# NOTE (typography): the Signal direction calls for a crisp sans (Inter) as
	# the UI face, with Press Start 2P reserved for the wordmark only. That swap
	# needs a vendored Inter asset and is a separate step; this pass keeps the
	# existing Press Start 2P / VT323 wiring and only reskins the chrome.
	theme.default_font = press_font
	theme.default_font_size = 12

	theme.set_font("font", "Label", press_font)
	theme.set_font_size("font_size", "Label", 12)
	theme.set_color("font_color", "Label", COLOR_TEXT)

	theme.set_font("font", "Button", press_font)
	theme.set_font_size("font_size", "Button", 12)
	theme.set_color("font_color", "Button", COLOR_TEXT)
	theme.set_color("font_hover_color", "Button", COLOR_AMBER)
	theme.set_color("font_pressed_color", "Button", COLOR_AMBER)
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

	# --- Panel: flat surface separated by a 1px rule, small radius (no cards). ---
	var panel_box := StyleBoxFlat.new()
	panel_box.bg_color = COLOR_SURFACE
	panel_box.border_color = COLOR_RULE
	panel_box.set_border_width_all(1)
	panel_box.set_corner_radius_all(3)
	panel_box.set_content_margin_all(12)
	theme.set_stylebox("panel", "Panel", panel_box)

	var panel_container_box := panel_box.duplicate()
	theme.set_stylebox("panel", "PanelContainer", panel_container_box)

	# --- Button: flat fill, 1px outline, small radius, NO bevel. ---
	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = COLOR_BTN_NORMAL
	btn_normal.border_color = COLOR_BORDER
	btn_normal.set_border_width_all(1)
	btn_normal.set_corner_radius_all(3)
	btn_normal.set_content_margin_all(11)

	var btn_hover := btn_normal.duplicate()
	btn_hover.bg_color = COLOR_BTN_HOVER
	btn_hover.border_color = COLOR_AMBER

	var btn_pressed := btn_normal.duplicate()
	btn_pressed.bg_color = COLOR_BTN_PRESSED
	btn_pressed.border_color = COLOR_AMBER

	var btn_disabled := btn_normal.duplicate()
	btn_disabled.bg_color = COLOR_BTN_DISABLED
	btn_disabled.border_color = COLOR_RULE

	var btn_focus := btn_normal.duplicate()
	btn_focus.border_color = COLOR_AMBER
	btn_focus.draw_center = false

	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("disabled", "Button", btn_disabled)
	theme.set_stylebox("focus", "Button", btn_focus)

	# OptionButton reuses the same flat family.
	theme.set_stylebox("normal", "OptionButton", btn_normal)
	theme.set_stylebox("hover", "OptionButton", btn_hover)
	theme.set_stylebox("pressed", "OptionButton", btn_pressed)
	theme.set_stylebox("disabled", "OptionButton", btn_disabled)
	theme.set_stylebox("focus", "OptionButton", btn_focus)

	# --- ProgressBar: flat track + flat amber fill, radius 1 (no gradient). ---
	var progress_bg := StyleBoxFlat.new()
	progress_bg.bg_color = COLOR_TRACK
	progress_bg.border_color = COLOR_RULE
	progress_bg.set_border_width_all(1)
	progress_bg.set_corner_radius_all(1)

	var progress_fill := StyleBoxFlat.new()
	progress_fill.bg_color = COLOR_AMBER
	progress_fill.set_corner_radius_all(1)

	theme.set_stylebox("background", "ProgressBar", progress_bg)
	theme.set_stylebox("fill", "ProgressBar", progress_fill)
	theme.set_font("font", "ProgressBar", press_font)
	theme.set_font_size("font_size", "ProgressBar", 10)
	theme.set_color("font_color", "ProgressBar", COLOR_TEXT)

	# --- EssencePill: flattened to a plain label (no pill bg/border). ---
	var pill_box := StyleBoxEmpty.new()
	pill_box.set_content_margin_all(4)
	theme.set_type_variation("EssencePill", "PanelContainer")
	theme.set_stylebox("panel", "EssencePill", pill_box)

	# --- StartButton: flat amber fill, ink text, small radius (no gradient/bevel). ---
	var start_normal := StyleBoxFlat.new()
	start_normal.bg_color = COLOR_AMBER
	start_normal.set_corner_radius_all(3)
	start_normal.set_content_margin_all(12)

	var start_hover := start_normal.duplicate()
	start_hover.bg_color = COLOR_AMBER_HI

	var start_pressed := start_normal.duplicate()
	start_pressed.bg_color = COLOR_AMBER_LO

	var start_disabled := start_normal.duplicate()
	start_disabled.bg_color = COLOR_BTN_DISABLED

	theme.set_type_variation("StartButton", "Button")
	theme.set_stylebox("normal", "StartButton", start_normal)
	theme.set_stylebox("hover", "StartButton", start_hover)
	theme.set_stylebox("pressed", "StartButton", start_pressed)
	theme.set_stylebox("disabled", "StartButton", start_disabled)
	theme.set_stylebox("focus", "StartButton", start_normal)
	theme.set_font("font", "StartButton", press_font)
	theme.set_font_size("font_size", "StartButton", 16)
	theme.set_color("font_color", "StartButton", COLOR_INK)
	theme.set_color("font_hover_color", "StartButton", COLOR_INK)
	theme.set_color("font_pressed_color", "StartButton", COLOR_INK)
	theme.set_color("font_disabled_color", "StartButton", COLOR_TEXT_DIM)

	# --- DodgeButton: the combat primary action, amber fill like StartButton
	# (the scene references this type variation for the big Dodge tap target). ---
	theme.set_type_variation("DodgeButton", "Button")
	theme.set_stylebox("normal", "DodgeButton", start_normal)
	theme.set_stylebox("hover", "DodgeButton", start_hover)
	theme.set_stylebox("pressed", "DodgeButton", start_pressed)
	theme.set_stylebox("disabled", "DodgeButton", start_disabled)
	theme.set_stylebox("focus", "DodgeButton", start_normal)
	theme.set_font("font", "DodgeButton", press_font)
	theme.set_color("font_color", "DodgeButton", COLOR_INK)
	theme.set_color("font_hover_color", "DodgeButton", COLOR_INK)
	theme.set_color("font_pressed_color", "DodgeButton", COLOR_INK)

	# --- HP bars: shared flat dark track + flat red (monster) / teal (player)
	# fills, exposed as ProgressBar type variations (no gradients). ---
	var hp_track := StyleBoxFlat.new()
	hp_track.bg_color = COLOR_TRACK
	hp_track.border_color = COLOR_RULE
	hp_track.set_border_width_all(1)
	hp_track.set_corner_radius_all(1)

	var monster_hp_fill := StyleBoxFlat.new()
	monster_hp_fill.bg_color = COLOR_RED
	monster_hp_fill.set_corner_radius_all(1)

	var player_hp_fill := StyleBoxFlat.new()
	player_hp_fill.bg_color = COLOR_TEAL
	player_hp_fill.set_corner_radius_all(1)

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
	root_box.bg_color = COLOR_GROUND
	theme.set_stylebox("panel", "root_background", root_box)

	var err := ResourceSaver.save(theme, OUT_PATH)
	if err != OK:
		push_error("build_theme: failed to save theme, error %d" % err)
		quit(1)
		return

	print("build_theme: wrote %s" % OUT_PATH)
	quit(0)
