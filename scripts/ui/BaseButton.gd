extends Control
class_name BaseButton

signal pressed
signal focus_started
signal focus_ended

var _disabled := false
var _hovered := false
var _pressed_inside := false

@export var disabled: bool:
	get:
		return _disabled
	set(value):
		_disabled = value
		_refresh_disabled()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	mouse_entered.connect(_handle_focus_start)
	mouse_exited.connect(_handle_focus_end)
	focus_entered.connect(_handle_focus_start)
	focus_exited.connect(_handle_focus_end)
	_refresh_disabled()

func _gui_input(event: InputEvent) -> void:
	if disabled:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressed_inside = true
			_on_press()
		elif _pressed_inside:
			_pressed_inside = false
			_on_release()
			pressed.emit()
	elif event.is_action_pressed("ui_accept"):
		_pressed_inside = true
		_on_press()
	elif event.is_action_released("ui_accept") and _pressed_inside:
		_pressed_inside = false
		_on_release()
		pressed.emit()

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
	_pressed_inside = false
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
	modulate = Color(0.45, 0.45, 0.45, 0.8) if _disabled else Color.WHITE
	mouse_default_cursor_shape = Control.CURSOR_ARROW if _disabled else Control.CURSOR_POINTING_HAND
