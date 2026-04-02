extends Control

enum NodeType { COMBAT, ELITE, REST, SHOP, EVENT, BOSS }

@onready var map_container = $ScrollContainer/MapContainer
@onready var hp_label = $PlayerInfo/HPLabel
@onready var gold_label = $PlayerInfo/GoldLabel
@onready var floor_label = $PlayerInfo/FloorLabel

var map_rows: Array = []
var current_row: int = -1

func _ready():
	_apply_theme()
	_generate_map()
	_update_info()

func _apply_theme():
	var theme = Theme.new()
	theme.set_font_size("font_size", "Label", 18)
	theme.set_color("font_color", "Label", Color(0.85, 0.85, 0.9))

	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.15, 0.15, 0.25, 0.9)
	btn_normal.border_color = Color(0.4, 0.4, 0.6)
	btn_normal.set_border_width_all(2)
	btn_normal.set_corner_radius_all(6)
	theme.set_stylebox("normal", "Button", btn_normal)

	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.25, 0.25, 0.4, 0.95)
	btn_hover.border_color = Color(0.6, 0.6, 0.8)
	btn_hover.set_border_width_all(2)
	btn_hover.set_corner_radius_all(6)
	theme.set_stylebox("hover", "Button", btn_hover)

	var btn_disabled = StyleBoxFlat.new()
	btn_disabled.bg_color = Color(0.08, 0.08, 0.12, 0.5)
	btn_disabled.border_color = Color(0.2, 0.2, 0.3)
	btn_disabled.set_border_width_all(2)
	btn_disabled.set_corner_radius_all(6)
	theme.set_stylebox("disabled", "Button", btn_disabled)

	set_theme(theme)

func _generate_map():
	for child in map_container.get_children():
		child.queue_free()
	map_rows.clear()

	var floors_remaining = 15 - GameManager.current_floor
	if floors_remaining <= 0:
		floors_remaining = 1

	for row in range(floors_remaining):
		var h_box = HBoxContainer.new()
		h_box.alignment = HBoxContainer.ALIGNMENT_CENTER
		h_box.add_theme_constant_override("separation", 40)

		var node_type: int
		# Determine node type based on remaining floors
		# Boss on last floor
		if row == floors_remaining - 1:
			node_type = NodeType.BOSS
		elif row == floors_remaining - 5 or row == floors_remaining - 10:
			node_type = NodeType.ELITE
		elif row == floors_remaining - 4 or row == floors_remaining - 8:
			node_type = NodeType.REST
		elif row == 3 or row == 7:
			node_type = NodeType.SHOP
		elif row == 1 or row == 5:
			node_type = NodeType.EVENT
		else:
			node_type = NodeType.COMBAT

		var num_choices = 3 if row == 0 else 1
		if row > 0 and row < floors_remaining - 1 and row % 3 == 0:
			num_choices = 2

		var row_data = []
		for col in range(num_choices):
			var actual_type = node_type
			if num_choices > 1 and col > 0:
				var variants = [NodeType.COMBAT, NodeType.EVENT, NodeType.SHOP]
				if row > 2:
					variants.append(NodeType.REST)
				actual_type = variants[randi() % variants.size()]

			var btn = Button.new()
			btn.custom_minimum_size = Vector2(160, 50)

			var type_names = {NodeType.COMBAT: "Combat", NodeType.ELITE: "Elite", NodeType.REST: "Rest", NodeType.SHOP: "Shop", NodeType.EVENT: "Event", NodeType.BOSS: "BOSS"}
			var type_colors = {NodeType.COMBAT: Color(0.6, 0.3, 0.3), NodeType.ELITE: Color(0.7, 0.2, 0.5), NodeType.REST: Color(0.2, 0.5, 0.3), NodeType.SHOP: Color(0.5, 0.5, 0.2), NodeType.EVENT: Color(0.3, 0.3, 0.6), NodeType.BOSS: Color(0.7, 0.5, 0.1)}

			btn.text = type_names.get(actual_type, "???")

			var base_col = type_colors.get(actual_type, Color.GRAY)
			var style = StyleBoxFlat.new()
			style.bg_color = base_col
			style.set_border_width_all(2)
			style.set_corner_radius_all(8)
			style.border_color = Color(min(1, base_col.r + 0.2), min(1, base_col.g + 0.2), min(1, base_col.b + 0.2))
			btn.add_theme_stylebox_override("normal", style)

			var hover_style = StyleBoxFlat.new()
			hover_style.bg_color = Color(min(1, base_col.r + 0.15), min(1, base_col.g + 0.15), min(1, base_col.b + 0.15))
			hover_style.set_border_width_all(3)
			hover_style.set_corner_radius_all(8)
			hover_style.border_color = Color.WHITE
			btn.add_theme_stylebox_override("hover", hover_style)

			btn.disabled = true if row > 0 else false

			var node_data = {"type": actual_type, "row": row, "col": col}
			row_data.append(node_data)
			btn.pressed.connect(_on_node_selected.bind(node_data))
			h_box.add_child(btn)

		map_rows.append(row_data)
		map_container.add_child(h_box)

	current_row = -1
	_enable_next_row()

func _enable_next_row():
	if current_row + 1 < map_rows.size():
		var next_row_idx = current_row + 1
		if next_row_idx < map_container.get_child_count():
			var row_container = map_container.get_child(next_row_idx)
			for btn in row_container.get_children():
				btn.disabled = false

func _on_node_selected(node_data: Dictionary):
	GameManager.current_floor += 1
	var type = node_data["type"]

	match type:
		NodeType.COMBAT, NodeType.ELITE, NodeType.BOSS:
			get_tree().change_scene_to_file("res://scenes/Combat.tscn")
		NodeType.REST:
			get_tree().change_scene_to_file("res://scenes/RestScreen.tscn")
		NodeType.SHOP:
			get_tree().change_scene_to_file("res://scenes/ShopScreen.tscn")
		NodeType.EVENT:
			get_tree().change_scene_to_file("res://scenes/EventScreen.tscn")

func _update_info():
	hp_label.text = "HP: %d/%d" % [GameManager.player_hp, GameManager.player_max_hp]
	gold_label.text = "Gold: %d" % GameManager.player_gold
	floor_label.text = "Floor: %d/15" % GameManager.current_floor
