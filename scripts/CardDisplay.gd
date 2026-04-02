extends Control

var card_data: CardData
var card_index: int = -1
var is_hovered: bool = false
var original_position: Vector2 = Vector2.ZERO
var in_hand: bool = false

signal card_clicked(index: int)
signal card_hovered(index: int)
signal card_unhovered(index: int)

@onready var bg = $Background
@onready var border = $BorderColor
@onready var inner = $InnerBg
@onready var cost_label = $CostLabel
@onready var name_label = $NameLabel
@onready var type_label = $TypeLabel
@onready var art_rect = $ArtRect
@onready var desc_label = $DescLabel
@onready var button = $Button

func _ready():
	button.pressed.connect(_on_button_pressed)
	button.mouse_entered.connect(_on_mouse_entered)
	button.mouse_exited.connect(_on_mouse_exited)
	_apply_theme()

func _apply_theme():
	var theme = Theme.new()
	theme.set_font_size("font_size", "Label", 14)
	theme.set_color("font_color", "Label", Color(0.9, 0.9, 0.95))
	set_theme(theme)

func setup(data: CardData, index: int = -1):
	card_data = data
	card_index = index
	_update_display()

func _update_display():
	if card_data == null:
		return

	cost_label.text = str(card_data.get_effective_cost())
	name_label.text = card_data.card_name

	var type_names = ["ATK", "SKL", "PWR"]
	type_label.text = type_names[card_data.card_type] if card_data.card_type < type_names.size() else "???"

	# Build description with actual values
	var desc = card_data.description
	if card_data.get_effective_damage() > 0:
		desc = desc.replace("6", str(card_data.get_effective_damage())).replace("8", str(card_data.get_effective_damage())).replace("5", str(card_data.get_effective_damage())).replace("9", str(card_data.get_effective_damage())).replace("13", str(card_data.get_effective_damage())).replace("10", str(card_data.get_effective_damage())).replace("3", str(card_data.get_effective_damage()))
	if card_data.get_effective_block() > 0:
		desc = desc.replace("5 Block", str(card_data.get_effective_block()) + " Block").replace("8 Block", str(card_data.get_effective_block()) + " Block").replace("30 Block", str(card_data.get_effective_block()) + " Block")
	desc_label.text = desc

	# Color based on card type
	var type_colors = [
		Color(0.7, 0.15, 0.15),  # Attack - Red
		Color(0.15, 0.3, 0.7),   # Skill - Blue
		Color(0.6, 0.4, 0.1)     # Power - Gold
	]
	var card_color = type_colors[card_data.card_type] if card_data.card_type < type_colors.size() else Color.GRAY

	border.color = card_color
	art_rect.color = Color(card_color.r * 0.6, card_color.g * 0.6, card_color.b * 0.6, 1)

	# Rarity glow
	if card_data.rarity == CardData.CardRarity.RARE:
		inner.color = Color(0.18, 0.15, 0.08)
	elif card_data.rarity == CardData.CardRarity.UNCOMMON:
		inner.color = Color(0.1, 0.1, 0.18)
	else:
		inner.color = Color(0.12, 0.12, 0.18)

func _on_button_pressed():
	card_clicked.emit(card_index)

func _on_mouse_entered():
	if not is_instance_valid(self):
		return
	is_hovered = true
	card_hovered.emit(card_index)
	if in_hand:
		original_position = position
		position.y -= 30
		scale = Vector2(1.1, 1.1)
		z_index = 10

func _on_mouse_exited():
	if not is_instance_valid(self):
		return
	is_hovered = false
	card_unhovered.emit(card_index)
	if in_hand:
		position = original_position
		scale = Vector2(1.0, 1.0)
		z_index = 0

func set_playable(playable: bool):
	if not is_instance_valid(self):
		return
	if playable:
		modulate = Color.WHITE
		button.disabled = false
	else:
		modulate = Color(0.5, 0.5, 0.5, 0.8)
		button.disabled = true
