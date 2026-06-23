extends Button
class_name BaseButton

signal focus_started
signal focus_ended

var _hovered := false
var _last_disabled := false

var _empty_stylebox := StyleBoxEmpty.new()

func _ready() -> void:
	flat = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	mouse_entered.connect(_handle_focus_start)
	mouse_exited.connect(_handle_focus_end)
	focus_entered.connect(_handle_focus_start)
	focus_exited.connect(_handle_focus_end)
	button_down.connect(_on_press)
	button_up.connect(_on_release)
	add_theme_stylebox_override("focus", _empty_stylebox)
	add_theme_color_override("font_color", Color.TRANSPARENT)
	add_theme_color_override("font_hover_color", Color.TRANSPARENT)
	add_theme_color_override("font_pressed_color", Color.TRANSPARENT)
	add_theme_color_override("font_disabled_color", Color.TRANSPARENT)
	_last_disabled = disabled
	_refresh_disabled()

func _process(_delta: float) -> void:
	if disabled == _last_disabled:
		return

	_last_disabled = disabled
	_refresh_disabled()

func _handle_focus_start() -> void:
	if disabled:
		return

	if _hovered:
		return

	_hovered = true
	_on_focus_start()
	focus_started.emit()

func _handle_focus_end() -> void:
	if not _hovered:
		return

	_hovered = false
	_on_focus_end()
	focus_ended.emit()

func _on_focus_start() -> void:
	pass

func _on_focus_end() -> void:
	pass

func _on_press() -> void:
	pass

func _on_release() -> void:
	pass

func _refresh_disabled() -> void:
	modulate = Color(0.45, 0.45, 0.45, 0.8) if disabled else Color.WHITE
	mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
