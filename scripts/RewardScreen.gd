extends Control

const CardScene = preload("res://scenes/CardCard.tscn")
const CardDatabase = preload("res://scripts/CardDatabase.gd")

@onready var gold_label = $GoldLabel
@onready var card_container = $CardContainer
@onready var skip_btn = $SkipBtn

var card_db: Node
var reward_cards: Array[CardData] = []

func _ready():
	_apply_theme()
	card_db = CardDatabase.new()
	add_child(card_db)
	skip_btn.pressed.connect(_on_skip)

	reward_cards = card_db.get_reward_cards(3)
	_show_rewards()

func _apply_theme():
	var theme = Theme.new()
	theme.set_font_size("font_size", "Label", 22)
	theme.set_color("font_color", "Label", Color(0.9, 0.85, 0.7))

	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.15, 0.15, 0.25, 0.9)
	btn_normal.border_color = Color(0.5, 0.4, 0.2)
	btn_normal.set_border_width_all(2)
	btn_normal.set_corner_radius_all(8)
	theme.set_stylebox("normal", "Button", btn_normal)

	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.25, 0.25, 0.4, 0.95)
	btn_hover.border_color = Color(0.7, 0.6, 0.3)
	btn_hover.set_border_width_all(2)
	btn_hover.set_corner_radius_all(8)
	theme.set_stylebox("hover", "Button", btn_hover)

	set_theme(theme)

func _show_rewards():
	gold_label.text = "+%d Gold" % randi_range(20, 40)

	for i in range(reward_cards.size()):
		var card = reward_cards[i]
		var display = CardScene.instantiate()
		card_container.add_child(display)
		display.setup(card, i)
		display.card_clicked.connect(_on_card_selected.bind(i))

func _on_card_selected(index: int):
	if index >= 0 and index < reward_cards.size():
		GameManager.add_card_to_deck(reward_cards[index])
		_proceed()

func _on_skip():
	_proceed()

func _proceed():
	# Check if run is over (floor 15)
	if GameManager.current_floor >= 15:
		get_tree().change_scene_to_file("res://scenes/VictoryScreen.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/MapScreen.tscn")
