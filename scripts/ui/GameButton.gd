extends BaseButton
class_name GameButton

@export var hover_scale := 1.05
@export var press_scale := 0.96
@export var normal_color := Color(0.16, 0.16, 0.28, 0.95)
@export var hover_color := Color(0.24, 0.22, 0.38, 1.0)
@export var pressed_color := Color(0.11, 0.11, 0.2, 1.0)
@export var disabled_color := Color(0.1, 0.1, 0.12, 0.65)

@onready var background: Panel = %Background
@onready var glow: ColorRect = %Glow
@onready var label: Label = %Label

var _tween: Tween
var _normal_style := StyleBoxFlat.new()
var _hover_style := StyleBoxFlat.new()
var _pressed_style := StyleBoxFlat.new()
var _disabled_style := StyleBoxFlat.new()

func _ready() -> void:
	_build_styles()
	super._ready()
	_update_text()
	pivot_offset = size * 0.5
	glow.modulate.a = 0.0
	_apply_style(_disabled_style if disabled else _normal_style)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = size * 0.5

func _on_focus_start() -> void:
	_animate(Vector2.ONE * hover_scale, 0.28, _hover_style, 0.12)

func _on_focus_end() -> void:
	_animate(Vector2.ONE, 0.0, _normal_style, 0.18)

func _on_press() -> void:
	_animate(Vector2.ONE * press_scale, 0.14, _pressed_style, 0.08)

func _on_release() -> void:
	_animate(Vector2.ONE * hover_scale, 0.28, _hover_style, 0.1)

func _refresh_disabled() -> void:
	super._refresh_disabled()
	if not is_node_ready():
		return

	if disabled:
		_kill_tween()
		scale = Vector2.ONE
		glow.modulate.a = 0.0
		_apply_style(_disabled_style)
	else:
		_apply_style(_normal_style)

func _update_text() -> void:
	label.text = text

func _build_styles() -> void:
	_configure_style(_normal_style, normal_color, Color(0.5, 0.48, 0.72))
	_configure_style(_hover_style, hover_color, Color(0.95, 0.75, 0.28))
	_configure_style(_pressed_style, pressed_color, Color(0.75, 0.55, 0.18))
	_configure_style(_disabled_style, disabled_color, Color(0.26, 0.26, 0.3))

func _configure_style(style: StyleBoxFlat, fill: Color, border: Color) -> void:
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8

func _animate(target_scale: Vector2, glow_alpha: float, style: StyleBoxFlat, duration: float) -> void:
	_kill_tween()
	_apply_style(style)
	_tween = create_tween().set_parallel()
	_tween.tween_property(self, "scale", target_scale, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(glow, "modulate:a", glow_alpha, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _apply_style(style: StyleBoxFlat) -> void:
	background.add_theme_stylebox_override("panel", style)

func _kill_tween() -> void:
	if _tween:
		_tween.kill()
