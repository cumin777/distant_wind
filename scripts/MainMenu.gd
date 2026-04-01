extends Control

@onready var new_game_btn = $VBox/NewGameBtn
@onready var continue_btn = $VBox/ContinueBtn
@onready var quit_btn = $VBox/QuitBtn
@onready var title_label = $Title
@onready var subtitle_label = $Subtitle

func _ready():
	_apply_theme()
	new_game_btn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	quit_btn.pressed.connect(_on_quit)
	continue_btn.disabled = true

func _apply_theme():
	var theme = Theme.new()
	var title_font = SystemFont.new()
	title_font.font_names = ["Arial", "Helvetica", "DejaVu Sans"]

	theme.set_font("font", "Label", SystemFont.new())
	theme.set_font_size("font_size", "Label", 16)
	theme.set_color("font_color", "Label", Color(0.85, 0.85, 0.9))

	theme.set_font_size("font_size", "Button", 20)
	theme.set_color("font_color", "Button", Color(0.9, 0.9, 0.95))
	theme.set_color("font_hover_color", "Button", Color(1, 0.85, 0.3))

	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.15, 0.15, 0.25, 0.9)
	btn_normal.border_color = Color(0.4, 0.4, 0.6)
	btn_normal.set_border_width_all(2)
	btn_normal.set_corner_radius_all(8)
	theme.set_stylebox("normal", "Button", btn_normal)

	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.2, 0.2, 0.35, 0.95)
	btn_hover.border_color = Color(0.6, 0.6, 0.8)
	btn_hover.set_border_width_all(2)
	btn_hover.set_corner_radius_all(8)
	theme.set_stylebox("hover", "Button", btn_hover)

	var btn_pressed = StyleBoxFlat.new()
	btn_pressed.bg_color = Color(0.1, 0.1, 0.2)
	btn_pressed.border_color = Color(0.5, 0.5, 0.7)
	btn_pressed.set_border_width_all(2)
	btn_pressed.set_corner_radius_all(8)
	theme.set_stylebox("pressed", "Button", btn_pressed)

	# Title font
	var title_style = LabelSettings.new()
	title_style.font_size = 64
	title_style.font_color = Color(1, 0.85, 0.3)
	title_label.label_settings = title_style

	var subtitle_style = LabelSettings.new()
	subtitle_style.font_size = 18
	subtitle_style.font_color = Color(0.6, 0.6, 0.7)
	subtitle_label.label_settings = subtitle_style

	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)

	set_theme(theme)

func _on_new_game():
	GameManager.reset_run()
	get_tree().change_scene_to_file("res://scenes/MapScreen.tscn")

func _on_continue():
	pass

func _on_quit():
	get_tree().quit()
