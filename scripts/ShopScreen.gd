extends Control

const CardScene = preload("res://scenes/CardCard.tscn")
const CardDatabase = preload("res://scripts/CardDatabase.gd")

@onready var gold_label = $GoldLabel
@onready var card_shop = $CardShop
@onready var proceed_btn = $ProceedBtn

var card_db: Node
var shop_cards: Array[Dictionary] = []

func _ready():
	_apply_theme()
	card_db = CardDatabase.new()
	add_child(card_db)
	proceed_btn.pressed.connect(_on_proceed)
	_generate_shop()

func _apply_theme():
	var theme = Theme.new()
	theme.set_font_size("font_size", "Label", 20)
	theme.set_color("font_color", "Label", Color(0.9, 0.85, 0.7))

	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.2, 0.15, 0.05, 0.9)
	btn_normal.border_color = Color(0.5, 0.4, 0.2)
	btn_normal.set_border_width_all(2)
	btn_normal.set_corner_radius_all(8)
	theme.set_stylebox("normal", "Button", btn_normal)

	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.3, 0.25, 0.1, 0.95)
	btn_hover.border_color = Color(0.7, 0.6, 0.3)
	btn_hover.set_border_width_all(2)
	btn_hover.set_corner_radius_all(8)
	theme.set_stylebox("hover", "Button", btn_hover)

	set_theme(theme)

func _generate_shop():
	gold_label.text = "Gold: %d" % GameManager.player_gold

	# Generate 5 cards for shop
	for i in range(5):
		var rarity_weights = [0.4, 0.4, 0.15, 0.05]
		var roll = randf()
		var rarity = CardData.CardRarity.COMMON
		var cumulative = 0.0
		for r in range(4):
			cumulative += rarity_weights[r]
			if roll < cumulative:
				rarity = r
				break

		var card = card_db.get_random_card_by_rarity(rarity)
		if card:
			var price = _get_price(rarity)
			shop_cards.append({"card": card, "price": price, "sold": false})

			var vbox = VBoxContainer.new()
			vbox.alignment = VBoxContainer.ALIGNMENT_CENTER

			var display = CardScene.instantiate()
			vbox.add_child(display)
			display.setup(card, i)

			var price_btn = Button.new()
			price_btn.text = "Buy (%d Gold)" % price
			price_btn.pressed.connect(_on_buy_card.bind(i, price_btn))
			if GameManager.player_gold < price:
				price_btn.disabled = true
			vbox.add_child(price_btn)

			card_shop.add_child(vbox)

	# Remove card service
	var remove_btn = Button.new()
	remove_btn.text = "Remove Card (75 Gold)"
	remove_btn.pressed.connect(_on_remove_card)
	if GameManager.player_gold < 75:
		remove_btn.disabled = true
	card_shop.add_child(remove_btn)

func _get_price(rarity: int) -> int:
	match rarity:
		CardData.CardRarity.COMMON:
			return randi_range(40, 60)
		CardData.CardRarity.UNCOMMON:
			return randi_range(70, 100)
		CardData.CardRarity.RARE:
			return randi_range(130, 170)
		_:
			return 50

func _on_buy_card(index: int, btn: Button):
	if index >= shop_cards.size():
		return
	var item = shop_cards[index]
	if item["sold"]:
		return
	if GameManager.spend_gold(item["price"]):
		GameManager.add_card_to_deck(item["card"])
		item["sold"] = true
		btn.text = "Sold!"
		btn.disabled = true
		gold_label.text = "Gold: %d" % GameManager.player_gold

func _on_remove_card():
	if GameManager.spend_gold(75) and GameManager.deck.size() > 0:
		# Remove a random basic card if possible
		var removed = false
		for i in range(GameManager.deck.size()):
			if GameManager.deck[i].card_name == "Strike" or GameManager.deck[i].card_name == "Defend":
				GameManager.remove_card_from_deck(i)
				removed = true
				break
		if not removed:
			GameManager.remove_card_from_deck(GameManager.deck.size() - 1)
		gold_label.text = "Gold: %d" % GameManager.player_gold

func _on_proceed():
	if GameManager.current_floor >= 15:
		get_tree().change_scene_to_file("res://scenes/VictoryScreen.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/MapScreen.tscn")
