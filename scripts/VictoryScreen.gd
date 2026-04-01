extends Control

@onready var title_label = $Title
@onready var stats_label = $StatsLabel
@onready var retry_btn = $RetryBtn
@onready var menu_btn = $MenuBtn

func _ready():
	_apply_theme()
	stats_label.text = "You conquered the Spire!\n\nHP: %d/%d\nGold: %d\nDeck size: %d\nFloors cleared: %d" % [
		GameManager.player_hp,
		GameManager.player_max_hp,
		GameManager.player_gold,
		GameManager.deck.size(),
		GameManager.current_floor
	]
	retry_btn.pressed.connect(_on_retry)
	menu_btn.pressed.connect(_on_menu)

func _apply_theme():
	var theme = Theme.new()
	theme.set_font_size("font_size", "Label", 20)
	theme.set_color("font_color", "Label", Color(0.7, 0.9, 0.7))

	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.1, 0.15, 0.1, 0.9)
	btn_normal.border_color = Color(0.3, 0.5, 0.3)
	btn_normal.set_border_width_all(2)
	btn_normal.set_corner_radius_all(8)
	theme.set_stylebox("normal", "Button", btn_normal)

	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.15, 0.25, 0.15, 0.95)
	btn_hover.border_color = Color(0.5, 0.7, 0.5)
	btn_hover.set_border_width_all(2)
	btn_hover.set_corner_radius_all(8)
	theme.set_stylebox("hover", "Button", btn_hover)

	set_theme(theme)

	var title_style = LabelSettings.new()
	title_style.font_size = 56
	title_style.font_color = Color(0.3, 1.0, 0.3)
	title_label.label_settings = title_style

func _on_retry():
	GameManager.reset_run()
	get_tree().change_scene_to_file("res://scenes/MapScreen.tscn")

func _on_menu():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
