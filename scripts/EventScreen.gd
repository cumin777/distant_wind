extends Control

@onready var title_label = $Title
@onready var desc_label = $DescLabel
@onready var choice_container = $ChoiceContainer

var events: Array[Dictionary] = []

func _ready():
	_apply_theme()
	_register_events()
	_show_random_event()

func _apply_theme():
	var theme = Theme.new()
	theme.set_font_size("font_size", "Label", 18)
	theme.set_color("font_color", "Label", Color(0.85, 0.85, 0.9))
	theme.set_font_size("font_size", "Button", 18)

	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.12, 0.1, 0.18, 0.9)
	btn_normal.border_color = Color(0.4, 0.3, 0.6)
	btn_normal.set_border_width_all(2)
	btn_normal.set_corner_radius_all(8)
	theme.set_stylebox("normal", "Button", btn_normal)

	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.2, 0.18, 0.3, 0.95)
	btn_hover.border_color = Color(0.6, 0.5, 0.8)
	btn_hover.set_border_width_all(2)
	btn_hover.set_corner_radius_all(8)
	theme.set_stylebox("hover", "Button", btn_hover)

	set_theme(theme)

func _register_events():
	events = [
		{
			"title": "Mysterious Shrine",
			"desc": "You discover a glowing shrine in a clearing. Ancient runes pulse with energy. A voice whispers: 'Offer your blood for power.'",
			"choices": [
				{"text": "Pray (Lose 10% HP, gain 25 Gold)", "action": "pray_shrine"},
				{"text": "Leave carefully", "action": "leave"}
			]
		},
		{
			"title": "Wandering Merchant",
			"desc": "A shady merchant blocks your path. 'I have something special for you... For a price.'",
			"choices": [
				{"text": "Buy potion (Lose 30 Gold, Heal 20 HP)", "action": "buy_potion"},
				{"text": "Threaten them (50% chance: gain 50 Gold or lose 15 HP)", "action": "threaten"},
				{"text": "Walk away", "action": "leave"}
			]
		},
		{
			"title": "Ancient Library",
			"desc": "You stumble upon a hidden library filled with forbidden knowledge. The books seem to whisper secrets of power.",
			"choices": [
				{"text": "Study (Upgrade a random card)", "action": "study"},
				{"text": "Rest here (Heal 15 HP)", "action": "rest_library"},
				{"text": "Ignore it", "action": "leave"}
			]
		},
		{
			"title": "Golden Idol",
			"desc": "A golden idol sits on a pedestal. It gleams temptingly, but something feels off about this place...",
			"choices": [
				{"text": "Take the gold (Gain 50 Gold)", "action": "take_gold"},
				{"text": "Examine carefully (Gain 30 Gold safely)", "action": "examine"},
				{"text": "Leave it alone", "action": "leave"}
			]
		},
		{
			"title": "Healing Spring",
			"desc": "A crystal-clear spring bubbles up from the ground. The water glows with a soft blue light.",
			"choices": [
				{"text": "Drink deeply (Heal 25 HP)", "action": "drink_spring"},
				{"text": "Fill waterskin (Heal 10 HP, gain 15 Gold)", "action": "fill_waterskin"},
				{"text": "Move on", "action": "leave"}
			]
		},
		{
			"title": "Cursed Chest",
			"desc": "An ornate chest sits in the middle of the path. Strange symbols cover its surface. You can feel dark energy radiating from within.",
			"choices": [
				{"text": "Open it (Gain 40 Gold, take 8 damage)", "action": "open_chest"},
				{"text": "Destroy it (Gain 15 Gold)", "action": "destroy_chest"},
				{"text": "Leave it", "action": "leave"}
			]
		},
		{
			"title": "Tired Adventurer",
			"desc": "A fellow adventurer sits by the road, looking exhausted. They offer to trade supplies.",
			"choices": [
				{"text": "Share food (Lose 10 HP, gain a card)", "action": "share_food"},
				{"text": "Trade (Lose 20 Gold, Heal 20 HP)", "action": "trade_adventurer"},
				{"text": "Ignore them", "action": "leave"}
			]
		}
	]

func _show_random_event():
	var event = events[randi() % events.size()]
	title_label.text = event["title"]
	desc_label.text = event["desc"]

	# Clear old buttons
	for child in choice_container.get_children():
		child.queue_free()

	for choice in event["choices"]:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(350, 50)
		btn.text = choice["text"]
		btn.pressed.connect(_on_choice_made.bind(choice["action"]))
		choice_container.add_child(btn)

func _on_choice_made(action: String):
	match action:
		"pray_shrine":
			var hp_loss = max(1, int(GameManager.player_max_hp * 0.1))
			GameManager.take_damage(hp_loss)
			GameManager.add_gold(25)
		"buy_potion":
			if GameManager.player_gold >= 30:
				GameManager.spend_gold(30)
				GameManager.heal(20)
		"threaten":
			if randf() < 0.5:
				GameManager.add_gold(50)
			else:
				GameManager.take_damage(15)
		"study":
			if not GameManager.deck.is_empty():
				var upgradable = GameManager.deck.filter(func(c): return not c.upgraded)
				if not upgradable.is_empty():
					var card = upgradable[randi() % upgradable.size()]
					var idx = GameManager.deck.find(card)
					GameManager.deck[idx] = card.get_upgraded()
		"rest_library":
			GameManager.heal(15)
		"take_gold":
			GameManager.add_gold(50)
			if randf() < 0.3:
				GameManager.take_damage(10)
		"examine":
			GameManager.add_gold(30)
		"drink_spring":
			GameManager.heal(25)
		"fill_waterskin":
			GameManager.heal(10)
			GameManager.add_gold(15)
		"open_chest":
			GameManager.add_gold(40)
			GameManager.take_damage(8)
		"destroy_chest":
			GameManager.add_gold(15)
		"share_food":
			GameManager.take_damage(10)
			var card_db = CardDatabase.new()
			add_child(card_db)
			var card = card_db.get_random_card_by_rarity(CardData.CardRarity.COMMON)
			if card:
				GameManager.add_card_to_deck(card)
			card_db.queue_free()
		"trade_adventurer":
			if GameManager.player_gold >= 20:
				GameManager.spend_gold(20)
				GameManager.heal(20)
		"leave":
			pass

	_proceed()

func _proceed():
	await get_tree().create_timer(0.5).timeout
	if GameManager.is_player_dead():
		get_tree().change_scene_to_file("res://scenes/GameOver.tscn")
	elif GameManager.current_floor >= 15:
		get_tree().change_scene_to_file("res://scenes/VictoryScreen.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/MapScreen.tscn")
