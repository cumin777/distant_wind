extends Control

@onready var rest_btn = $RestBtn
@onready var smith_btn = $SmithBtn
@onready var proceed_btn = $ProceedBtn
@onready var title_label = $Title

func _ready():
	_apply_theme()
	rest_btn.pressed.connect(_on_rest)
	smith_btn.pressed.connect(_on_smith)
	proceed_btn.disabled = true
	proceed_btn.pressed.connect(_on_proceed)

func _apply_theme():
	var theme = Theme.new()
	theme.set_font_size("font_size", "Button", 20)
	theme.set_color("font_color", "Button", Color(0.9, 0.85, 0.7))
	theme.set_color("font_color", "Label", Color(0.7, 0.8, 0.7))

	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.1, 0.2, 0.1, 0.9)
	btn_normal.border_color = Color(0.3, 0.5, 0.3)
	btn_normal.set_border_width_all(2)
	btn_normal.set_corner_radius_all(8)
	theme.set_stylebox("normal", "Button", btn_normal)

	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.15, 0.3, 0.15, 0.95)
	btn_hover.border_color = Color(0.5, 0.7, 0.5)
	btn_hover.set_border_width_all(2)
	btn_hover.set_corner_radius_all(8)
	theme.set_stylebox("hover", "Button", btn_hover)

	set_theme(theme)

func _on_rest():
	var heal_amount = max(1, int(GameManager.player_max_hp * 0.3))
	GameManager.heal(heal_amount)
	rest_btn.disabled = true
	smith_btn.disabled = true
	proceed_btn.disabled = false
	title_label.text = "Healed %d HP!" % heal_amount

func _on_smith():
	get_tree().change_scene_to_file("res://scenes/UpgradeScreen.tscn")

func _on_proceed():
	if GameManager.current_floor >= 15:
		get_tree().change_scene_to_file("res://scenes/VictoryScreen.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/MapScreen.tscn")
