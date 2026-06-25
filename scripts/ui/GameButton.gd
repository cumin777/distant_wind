extends "res://scripts/ui/BaseButton.gd"
class_name GameButton

@export var hover_scale := 1.32
@export var press_scale := 0.82
@export var normal_color := Color(0.28, 0.07, 0.12, 0.98)
@export var hover_color := Color(0.58, 0.16, 0.18, 1.0)
@export var pressed_color := Color(0.14, 0.02, 0.05, 1.0)
@export var disabled_color := Color(0.1, 0.1, 0.12, 0.65)

@onready var aura: ColorRect = %Aura
@onready var background: Panel = %Background
@onready var glow: ColorRect = %Glow
@onready var shine: ColorRect = %Shine
@onready var flash: ColorRect = %Flash
@onready var label: Label = %Label
@onready var sparkles: Control = %Sparkles

var _state_tween: Tween
var _idle_tween: Tween
var _shine_tween: Tween
var _flash_tween: Tween
var _sparkle_idle_tweens: Array[Tween] = []
var _normal_style := StyleBoxFlat.new()
var _hover_style := StyleBoxFlat.new()
var _pressed_style := StyleBoxFlat.new()
var _disabled_style := StyleBoxFlat.new()
var _sparkle_points := [
	Vector2(20, 8),
	Vector2(62, 52),
	Vector2(118, 6),
	Vector2(186, 54),
	Vector2(246, 10),
	Vector2(282, 44),
]

func _ready() -> void:
	_build_styles()
	super._ready()
	_update_text()
	_sort_visual_layers()
	pivot_offset = size * 0.5
	aura.modulate.a = 0.65
	glow.modulate.a = 0.55
	shine.modulate.a = 0.0
	flash.modulate.a = 0.0
	_apply_style(_disabled_style if disabled else _normal_style)
	_build_sparkles()
	_start_idle_pulse()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = size * 0.5

func _on_focus_start() -> void:
	_animate(Vector2.ONE * hover_scale, 1.0, _hover_style, -12.0, 0.12)
	_sweep_shine()
	_pop_sparkles()

func _on_focus_end() -> void:
	_animate(Vector2.ONE, 0.55, _normal_style, 0.0, 0.18)

func _on_press() -> void:
	_animate(Vector2.ONE * press_scale, 0.85, _pressed_style, 8.0, 0.08)
	_flash()

func _on_release() -> void:
	_animate(Vector2.ONE * hover_scale, 1.0, _hover_style, -12.0, 0.1)
	_sweep_shine()
	_pop_sparkles()

func _refresh_disabled() -> void:
	super._refresh_disabled()
	if not is_node_ready():
		return

	if disabled:
		_kill_state_tween()
		scale = Vector2.ONE
		aura.modulate.a = 0.0
		glow.modulate.a = 0.0
		shine.modulate.a = 0.0
		flash.modulate.a = 0.0
		label.position.y = 0.0
		_apply_style(_disabled_style)
	else:
		_apply_style(_normal_style)

func _update_text() -> void:
	label.text = text

func _build_styles() -> void:
	_configure_style(_normal_style, normal_color, Color(1.0, 0.52, 0.08))
	_configure_style(_hover_style, hover_color, Color(1.0, 0.95, 0.16))
	_configure_style(_pressed_style, pressed_color, Color(1.0, 0.42, 0.02))
	_configure_style(_disabled_style, disabled_color, Color(0.26, 0.26, 0.3))

func _configure_style(style: StyleBoxFlat, fill: Color, border: Color) -> void:
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(7)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(1.0, 0.28, 0.02, 0.9)
	style.shadow_size = 42
	style.shadow_offset = Vector2(0, 0)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8

func _animate(target_scale: Vector2, glow_alpha: float, style: StyleBoxFlat, label_y: float, duration: float) -> void:
	_kill_state_tween()
	_apply_style(style)
	_state_tween = create_tween().set_parallel(true)
	_state_tween.tween_property(self, "scale", target_scale, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_state_tween.tween_property(glow, "modulate:a", glow_alpha, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_state_tween.tween_property(aura, "modulate:a", max(glow_alpha * 0.85, 0.55), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_state_tween.tween_property(label, "position:y", label_y, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _apply_style(style: StyleBoxFlat) -> void:
	background.add_theme_stylebox_override("panel", style)

func _start_idle_pulse() -> void:
	if _idle_tween:
		_idle_tween.kill()

	_idle_tween = create_tween().set_loops(0)
	_idle_tween.tween_property(aura, "modulate:a", 1.0, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.parallel().tween_property(glow, "modulate:a", 0.92, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(aura, "modulate:a", 0.45, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.parallel().tween_property(glow, "modulate:a", 0.48, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _sweep_shine() -> void:
	if _shine_tween:
		_shine_tween.kill()

	shine.position.x = -150.0
	shine.modulate.a = 0.0
	_shine_tween = create_tween()
	_shine_tween.tween_property(shine, "modulate:a", 1.0, 0.04)
	_shine_tween.parallel().tween_property(shine, "position:x", size.x + 140.0, 0.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_shine_tween.tween_property(shine, "modulate:a", 0.0, 0.12)

func _flash() -> void:
	if _flash_tween:
		_flash_tween.kill()

	flash.modulate.a = 0.0
	_flash_tween = create_tween()
	_flash_tween.tween_property(flash, "modulate:a", 1.0, 0.035)
	_flash_tween.tween_property(flash, "modulate:a", 0.0, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _build_sparkles() -> void:
	for tween in _sparkle_idle_tweens:
		if tween:
			tween.kill()
	_sparkle_idle_tweens.clear()

	for child in sparkles.get_children():
		child.queue_free()

	for i in range(_sparkle_points.size()):
		var point: Vector2 = _sparkle_points[i]
		var sparkle := ColorRect.new()
		sparkle.custom_minimum_size = Vector2(14, 14)
		sparkle.size = Vector2(14, 14)
		sparkle.position = point
		sparkle.color = Color(1.0, 0.88, 0.24, 1.0)
		sparkle.modulate.a = 0.75
		sparkle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sparkles.add_child(sparkle)
		_start_sparkle_idle(sparkle, i)

func _pop_sparkles() -> void:
	for i in range(sparkles.get_child_count()):
		var sparkle := sparkles.get_child(i) as ColorRect
		if sparkle == null:
			continue

		var base_position: Vector2 = _sparkle_points[i]
		sparkle.position = base_position
		sparkle.scale = Vector2.ONE * 0.9
		sparkle.modulate.a = 0.75
		var direction := Vector2(-1.0 if i % 2 == 0 else 1.0, -1.0).normalized()
		var tween := create_tween().set_parallel(true)
		tween.tween_property(sparkle, "modulate:a", 1.0, 0.08).set_delay(i * 0.025)
		tween.tween_property(sparkle, "scale", Vector2.ONE * 2.8, 0.16).set_delay(i * 0.025)
		tween.tween_property(sparkle, "position", base_position + direction * 38.0, 0.24).set_delay(i * 0.025).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.chain().tween_property(sparkle, "modulate:a", 0.75, 0.18)

func _start_sparkle_idle(sparkle: ColorRect, index: int) -> void:
	var tween := create_tween().set_loops(0)
	tween.tween_property(sparkle, "modulate:a", 1.0, 0.35).set_delay(index * 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sparkle, "modulate:a", 0.55, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_sparkle_idle_tweens.append(tween)

func _sort_visual_layers() -> void:
	move_child(aura, 0)
	move_child(background, 1)
	move_child(glow, 2)
	move_child(shine, 3)
	move_child(flash, 4)
	move_child(sparkles, 5)
	move_child(label, 6)

func _kill_state_tween() -> void:
	if _state_tween:
		_state_tween.kill()
