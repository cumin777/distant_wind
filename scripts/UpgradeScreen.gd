extends Control

const CardScene = preload("res://scenes/CardCard.tscn")

@onready var card_container = $ScrollContainer/CardContainer
@onready var skip_btn = $SkipBtn

var card_displays: Array = []

func _ready():
	_apply_theme()
	skip_btn.pressed.connect(_on_skip)
	_show_upgradeable_cards()

func _apply_theme():
	var theme = Theme.new()
	theme.set_font_size("font_size", "Label", 20)
	theme.set_color("font_color", "Label", Color(0.8, 0.8, 0.9))

	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.12, 0.12, 0.2, 0.9)
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

	set_theme(theme)

func _show_upgradeable_cards():
	for i in range(GameManager.deck.size()):
		var card = GameManager.deck[i]
		if not card.upgraded:
			var display = CardScene.instantiate()
			card_container.add_child(display)
			display.setup(card, i)
			display.card_clicked.connect(_on_card_selected)
			card_displays.append(display)

	if card_displays.is_empty():
		skip_btn.text = "No cards to upgrade - Continue"

func _on_card_selected(deck_index: int):
	if deck_index >= 0 and deck_index < GameManager.deck.size():
		GameManager.deck[deck_index] = GameManager.deck[deck_index].get_upgraded()
		_proceed()

func _on_skip():
	_proceed()

func _proceed():
	if GameManager.current_floor >= 15:
		get_tree().change_scene_to_file("res://scenes/VictoryScreen.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/MapScreen.tscn")
