# CombatScreen — renders a CombatResolver HP-race for the picked monster,
# driven by a tap-timed "Dodge" button (touch/mouse) each round. The fight
# auto-starts on _ready (the overworld already gated the encounter). Once
# the reflex phase ends, the run's authoritative outcome (XP, drops, hunts,
# death) is resolved through RunState.resolve_fight — no rules logic is
# reimplemented here, only round timing/animation bookkeeping and the HUD.
# Instanced as an overlay child (e.g. by the overworld) rather than a
# standalone scene: it never changes scenes itself, it signals completion
# via `combat_finished` and leaves scene/run teardown to its parent.
extends Control

signal combat_finished(result: Dictionary)

const MonsterSpriteSheet = preload("res://src/ui/combat/monster_sprite_sheet.gd")
# Player walk sheet; its down-idle frame (top-left 64x64 cell) is the combat portrait.
const PLAYER_SHEET := preload("res://assets/sprites/player_ethan.png")

const ROUND_DURATION := 1.2
const PERFECT_OFFSET := 0.7 # seconds into the round considered a "perfect" dodge
const MAX_ROUNDS := 12

# Presentation-only timing: how long before a round resolves the telegraph
# banner/ring start flashing, and the idle-bob/blink rates. None of this
# affects ROUND_DURATION/PERFECT_OFFSET or CombatResolver's math.
const TELEGRAPH_LEAD := 0.5
const TELEGRAPH_BLINK_HZ := 4.0
const IDLE_BOB_AMPLITUDE := 12.0
const IDLE_BOB_HZ := 1.2
# Continuous "radar ping" ring around the monster (mockup's ring keyframe):
# expands from 0.7 to 1.4 while fading, looping for the whole fight so there
# is always motion around the monster, independent of the attack telegraph.
const RING_PULSE_PERIOD := 1.2
const DAMAGE_FLOAT_DISTANCE := 34.0
const DAMAGE_FLOAT_DURATION := 0.6

const ELEMENT_COLORS := {
	"fire": Color("#ff6a3d"),
	"water": Color("#3d8bff"),
	"earth": Color("#8a6a3d"),
	"thunder": Color("#ffd23d"),
	"ice": Color("#5eb8d9"),
	"dragon": Color("#b23dff"),
	"neutral": Color("#8a93a8"),
}

# Signal round-segments: track / teal (resolved) / amber (now). A discrete
# round meter, not decorative dots.
const DOT_PENDING_COLOR := Color(0.133333, 0.156863, 0.203922, 1)  # #222834 track
const DOT_RESOLVED_COLOR := Color(0.294118, 0.831373, 0.627451, 1) # #4bd4a0 teal (you)
const DOT_ACTIVE_COLOR := Color(0.960784, 0.725490, 0.258824, 1)   # #f5b942 amber (now)

@onready var timer: Timer = %RoundTimer
@onready var dodge_button: Button = %DodgeButton
@onready var player_hp_bar: ProgressBar = %PlayerHpBar
@onready var player_hp_label: Label = %PlayerHpLabel
@onready var monster_hp_bar: ProgressBar = %MonsterHpBar
@onready var monster_info_label: Label = %MonsterInfoLabel
@onready var monster_element_chip: ColorRect = %MonsterElementChip
@onready var monster_element_label: Label = %MonsterElementLabel
@onready var monster_part_label: Label = %MonsterPartLabel
@onready var monster_weakness_label: Label = %MonsterWeaknessLabel
@onready var monster_sprite: AnimatedSprite2D = %MonsterSprite
@onready var telegraph_ring: Control = %TelegraphRing
@onready var telegraph_banner: Control = %TelegraphBanner
@onready var damage_number_label: Label = %DamageNumberLabel
@onready var round_dots_row: HBoxContainer = %RoundDotsRow
@onready var result_overlay: Control = %ResultOverlay
@onready var result_title_label: Label = %ResultTitleLabel
@onready var result_body_label: Label = %ResultBodyLabel
@onready var xp_level_label: Label = %XpLevelLabel
@onready var xp_bar: ProgressBar = %XpBar
@onready var level_up_toasts: VBoxContainer = %LevelUpToasts
@onready var push_on_button: Button = %PushOnButton
@onready var bank_button: Button = %BankButton
@onready var continue_button: Button = %ContinueButton

var monster: MonsterDef
var player_stats: Dictionary
var monster_stats: Dictionary
var weapon_stats: Dictionary
var skill_profile: Dictionary = {}
var beats: Array = []

var _round_dots: Array = []
var _round_start_ms: int = 0
var _dodge_tapped_this_round: bool = false
var _fight_over: bool = false
var _fight_result: Dictionary = {}
var _reflex_outcome: Dictionary = {}
var _elapsed_time: float = 0.0
var _sprite_base_y: float = 0.0

func _ready() -> void:
	monster = GameState.pending_monster
	var run: RunState = GameState.current_run

	player_stats = {"hp_max": XpCurve.power_scaling(run.level) * 5.0, "power": XpCurve.power_scaling(run.level)}
	monster_stats = {"hp_max": monster.base_hp, "power": monster.base_attack, "element": monster.element}
	weapon_stats = _weapon_stats(run.equipped_weapon_id)
	skill_profile = GameState.skill_profile_for(run.equipped_armor_ids)

	player_hp_bar.max_value = player_stats["hp_max"]
	player_hp_bar.value = player_stats["hp_max"]
	monster_hp_bar.max_value = monster_stats["hp_max"]
	monster_hp_bar.value = monster_stats["hp_max"]
	_update_player_hp_label()
	_add_player_portrait()

	monster_info_label.text = "%s   Lv %s" % [monster.name, Big.fmt(monster.level)]
	monster_element_chip.color = ELEMENT_COLORS.get(monster.element, ELEMENT_COLORS["neutral"])
	monster_element_label.text = monster.element.capitalize()
	monster_part_label.text = "part: %s" % _targeted_part()
	var weakness := Elements.weakness_of(monster.element)
	monster_weakness_label.text = "WEAK" if weakness != "" else ""

	if DebugSettings.dots_enabled():
		# Debug dot mode: monster renders as a single dot marker, but keeps its
		# per-anim SpriteFrames so play("idle"/"hit"/"attack") + the idle bob all
		# still run harmlessly against the dot.
		monster_sprite.sprite_frames = DebugSettings.dot_sprite_frames(SpriteSheetSlicer.ANIMS.keys())
		monster_sprite.scale = Vector2(DebugSettings.DOT_DISPLAY_SCALE, DebugSettings.DOT_DISPLAY_SCALE)
	else:
		monster_sprite.sprite_frames = MonsterSpriteSheet.build(monster.id)
	monster_sprite.animation_finished.connect(_on_monster_anim_finished)
	monster_sprite.play("idle")
	_sprite_base_y = monster_sprite.position.y

	dodge_button.pressed.connect(_on_dodge_pressed)
	push_on_button.pressed.connect(_on_push_on_pressed)
	bank_button.pressed.connect(_on_bank_pressed)
	continue_button.pressed.connect(_on_continue_pressed)

	result_overlay.visible = false
	xp_level_label.visible = false
	xp_bar.visible = false
	telegraph_banner.visible = false
	damage_number_label.visible = false
	_start_ring_pulse()

	_build_round_dots()

	timer.wait_time = ROUND_DURATION
	timer.one_shot = true
	timer.timeout.connect(_on_round_timeout)

	set_process(true)
	beats.clear()
	_fight_over = false
	_start_round()

func _targeted_part() -> String:
	if not monster.drop_table.is_empty():
		var part: String = monster.drop_table[0].get("part", "")
		if part != "":
			return part
	if not monster.parts.is_empty():
		return monster.parts[0]
	return "body"

func _weapon_stats(weapon_id: String) -> Dictionary:
	if weapon_id != "" and GameState.weapons.has(weapon_id):
		var def: WeaponDef = GameState.weapons[weapon_id]
		return {"weapon_class": def.weapon_class, "element": def.element, "base_damage": def.base_damage}
	return {"weapon_class": "", "element": "neutral", "base_damage": 5.0}

func _build_round_dots() -> void:
	for child in round_dots_row.get_children():
		child.queue_free()
	_round_dots.clear()
	for i in range(MAX_ROUNDS):
		var dot := ColorRect.new()
		# Signal segments: thin bars that stretch to fill the row, so the round
		# meter reads as a discrete progress strip rather than a row of dots.
		dot.custom_minimum_size = Vector2(6, 8)
		dot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dot.color = DOT_PENDING_COLOR
		round_dots_row.add_child(dot)
		_round_dots.append(dot)
	_update_round_dots()

func _update_round_dots() -> void:
	for i in range(_round_dots.size()):
		var dot: ColorRect = _round_dots[i]
		if i < beats.size():
			dot.color = DOT_RESOLVED_COLOR
		elif i == beats.size() and not _fight_over:
			dot.color = DOT_ACTIVE_COLOR
		else:
			dot.color = DOT_PENDING_COLOR

# Continuous radar-ping ring around the monster for the whole fight — expands
# and fades on a loop, matching the mockup's always-on ring. The attack
# telegraph is signalled separately by the flashing banner in _process.
func _start_ring_pulse() -> void:
	# pivot_offset is set in the scene (150,150 = centre of the 300x300 ring);
	# do not recompute it here, size is not laid out yet at _ready.
	telegraph_ring.visible = true
	var tween := create_tween().set_loops()
	tween.tween_callback(func() -> void:
		telegraph_ring.scale = Vector2(0.7, 0.7)
		telegraph_ring.modulate.a = 0.9)
	tween.tween_property(telegraph_ring, "scale", Vector2(1.4, 1.4), RING_PULSE_PERIOD).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(telegraph_ring, "modulate:a", 0.0, RING_PULSE_PERIOD)

func _start_round() -> void:
	_round_start_ms = Time.get_ticks_msec()
	_dodge_tapped_this_round = false
	telegraph_banner.visible = false
	_update_round_dots()
	if timer.is_inside_tree():
		timer.start()
	else:
		timer.start.call_deferred()

func _process(delta: float) -> void:
	_elapsed_time += delta
	monster_sprite.position.y = _sprite_base_y + sin(_elapsed_time * IDLE_BOB_HZ * TAU) * IDLE_BOB_AMPLITUDE

	if _fight_over:
		return
	var elapsed := (Time.get_ticks_msec() - _round_start_ms) / 1000.0
	var in_telegraph := elapsed >= (ROUND_DURATION - TELEGRAPH_LEAD)
	telegraph_banner.visible = in_telegraph
	if in_telegraph:
		var blink := (sin(_elapsed_time * TELEGRAPH_BLINK_HZ * TAU) + 1.0) / 2.0
		telegraph_banner.modulate.a = 0.4 + blink * 0.6

func _on_dodge_pressed() -> void:
	if _fight_over or _dodge_tapped_this_round:
		return
	_dodge_tapped_this_round = true
	var elapsed := (Time.get_ticks_msec() - _round_start_ms) / 1000.0
	beats.append({"dodge_timing": absf(elapsed - PERFECT_OFFSET)})

func _on_round_timeout() -> void:
	if _fight_over:
		return
	if not _dodge_tapped_this_round:
		beats.append({"dodge_timing": INF})

	var monster_hp_before := monster_hp_bar.value
	var outcome := CombatResolver.resolve(player_stats, monster_stats, weapon_stats, beats, skill_profile)
	player_hp_bar.value = outcome["player_hp"]
	monster_hp_bar.value = outcome["monster_hp"]
	_update_player_hp_label()

	if outcome["monster_hp"] < monster_hp_before:
		monster_sprite.play("hit")
		_show_damage_number(monster_hp_before - outcome["monster_hp"])
	else:
		monster_sprite.play("attack")

	telegraph_banner.visible = false

	if outcome["monster_hp"] <= 0.0 or outcome["player_hp"] <= 0.0 or beats.size() >= MAX_ROUNDS:
		_reflex_outcome = outcome
		_end_reflex_phase()
	else:
		_start_round()

func _show_damage_number(amount: float) -> void:
	damage_number_label.text = "-%s" % Big.fmt(amount)
	damage_number_label.global_position = monster_sprite.global_position + Vector2(-20, -60)
	damage_number_label.modulate = Color(1, 1, 1, 1)
	damage_number_label.visible = true
	var tween := create_tween()
	tween.tween_property(damage_number_label, "global_position:y", damage_number_label.global_position.y - DAMAGE_FLOAT_DISTANCE, DAMAGE_FLOAT_DURATION)
	tween.parallel().tween_property(damage_number_label, "modulate:a", 0.0, DAMAGE_FLOAT_DURATION)
	tween.tween_callback(func(): damage_number_label.visible = false)

func _on_monster_anim_finished() -> void:
	if monster_sprite.animation != "idle":
		monster_sprite.play("idle")

func _end_reflex_phase() -> void:
	_fight_over = true
	dodge_button.visible = false
	telegraph_banner.visible = false
	telegraph_ring.visible = false
	_update_round_dots()

	var player_hp: float = _reflex_outcome.get("player_hp", 0.0)
	var monster_hp: float = _reflex_outcome.get("monster_hp", 0.0)
	var won: bool
	if monster_hp <= 0.0 and player_hp > 0.0:
		won = true
	elif player_hp <= 0.0:
		won = false
	else:
		var p_frac := player_hp / maxf(player_stats["hp_max"], 1.0)
		var m_frac := monster_hp / maxf(monster_stats["hp_max"], 1.0)
		won = p_frac >= m_frac

	var run: RunState = GameState.current_run
	var result := run.resolve_fight(monster, [], null, skill_profile, {"won": won})
	_fight_result = result

	push_on_button.visible = false
	bank_button.visible = false
	continue_button.visible = false

	if result["died"]:
		GameState.mark_bestiary_seen(monster.id)
		result_title_label.text = "Defeated"
		result_body_label.text = "The run's haul is forfeited."
		continue_button.visible = true
		xp_level_label.visible = false
		xp_bar.visible = false
		for child in level_up_toasts.get_children():
			child.queue_free()
	else:
		GameState.mark_bestiary_defeated(monster.id, result["materials_dropped"])
		result_title_label.text = "Victory!"
		var drops: String = ", ".join(result["materials_dropped"])
		result_body_label.text = ("Dropped: %s" % drops) if drops != "" else "No drops"
		xp_level_label.visible = true
		xp_bar.visible = true
		if run.status == "active":
			push_on_button.visible = true
			bank_button.visible = true
		else:
			continue_button.visible = true
		_animate_xp(result)

	result_overlay.visible = true

func _animate_xp(result: Dictionary) -> void:
	for child in level_up_toasts.get_children():
		child.queue_free()

	var segments: Array = XpCurve.fill_segments(
		result["level_before"], result["xp_carry_before"], result["level_after"], result["xp_carry_after"]
	)
	if segments.is_empty():
		return

	xp_level_label.text = "Lv %d" % int(result["level_before"])
	xp_bar.value = segments[0]["from"]

	var seg_time: float = clampf(1.2 / float(max(segments.size(), 1)), 0.10, 0.30)
	var tween := create_tween()
	for seg in segments:
		tween.tween_property(xp_bar, "value", seg["to"], seg_time).from(seg["from"]).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_callback(_on_xp_segment_finished.bind(seg))

func _on_xp_segment_finished(seg: Dictionary) -> void:
	if seg["levels_up"]:
		xp_level_label.text = "Lv %d" % (int(seg["level"]) + 1)
		_spawn_level_up_toast()

func _spawn_level_up_toast() -> void:
	var toast := Label.new()
	toast.text = "LEVEL UP!"
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_font_size_override("font_size", 15)
	toast.add_theme_color_override("font_color", Color(1, 0.8235294, 0.2901961, 1))
	level_up_toasts.add_child(toast)
	toast.pivot_offset = toast.size / 2.0
	toast.scale = Vector2(0.6, 0.6)
	toast.modulate.a = 0.0
	var start_pos := toast.position
	toast.position.y += 6.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(toast, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(toast, "modulate:a", 1.0, 0.15)
	tween.tween_property(toast, "position:y", start_pos.y, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_push_on_pressed() -> void:
	combat_finished.emit(_fight_result)

func _on_bank_pressed() -> void:
	var run: RunState = GameState.current_run
	if run.status == "active":
		run.retreat()
	combat_finished.emit(_fight_result)

func _on_continue_pressed() -> void:
	combat_finished.emit(_fight_result)

func _update_player_hp_label() -> void:
	player_hp_label.text = "YOU · %s / %s" % [Big.fmt(player_hp_bar.value), Big.fmt(player_hp_bar.max_value)]

# Drops the hunter's down-idle frame in as a small "YOU" avatar just above the
# player HP label, so the player is represented in combat (matches the overworld
# character). Built in code from an AtlasTexture region so no scene edit is needed.
func _add_player_portrait() -> void:
	var portrait := TextureRect.new()
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.size_flags_horizontal = Control.SIZE_FILL
	if DebugSettings.dots_enabled():
		# Debug dot mode: the "YOU" avatar is a centered dot square sized to the
		# real portrait (fits the 72px-tall slot).
		portrait.texture = DebugSettings.dot_texture(DebugSettings.DOT_COLOR, int(DebugSettings.DOT_DISPLAY_SCALE))
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	else:
		var frame := AtlasTexture.new()
		frame.atlas = PLAYER_SHEET
		frame.region = Rect2(0, 0, 64, 64)
		portrait.texture = frame
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(0, 72)
	var hud: Node = player_hp_label.get_parent()
	hud.add_child(portrait)
	hud.move_child(portrait, player_hp_label.get_index())
