extends Control
## Main home menu: New Game (era) → Character → Play, or Load.

@onready var title: Label = %Title
@onready var subtitle: Label = %Subtitle
@onready var main_buttons: VBoxContainer = %MainButtons
@onready var era_panel: PanelContainer = %EraPanel
@onready var era_list: VBoxContainer = %EraList
@onready var era_desc: Label = %EraDesc
@onready var load_panel: PanelContainer = %LoadPanel
@onready var load_list: VBoxContainer = %LoadList
@onready var how_to: RichTextLabel = %HowTo

var _selected_era: String = "present"


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameState.phase = GameState.GamePhase.MENU
	title.text = "MYSTERY HOLLOW"
	subtitle.text = "Open-world detective life simulator"
	era_panel.visible = false
	load_panel.visible = false
	_populate_eras()
	_populate_loads()
	how_to.text = "[b]Controls[/b]\nWASD — Move · Mouse — Look · Shift — Sprint · E — Interact\nJ — Journal · I — Inventory · B — Build mode (home) · Esc — Free cursor\n\n[b]Goal[/b]\nLive in Mystery Hollow, manage needs, and solve the Riverside Murder."


func _populate_eras() -> void:
	for c in era_list.get_children():
		c.queue_free()
	for era_id in EraManager.get_era_ids():
		var era: Dictionary = EraManager.ERAS[era_id]
		var btn := Button.new()
		btn.text = "%s  (%d)" % [era["label"], era["year"]]
		btn.custom_minimum_size = Vector2(280, 40)
		btn.pressed.connect(_on_era_pressed.bind(era_id))
		era_list.add_child(btn)
	_on_era_pressed("present")


func _populate_loads() -> void:
	for c in load_list.get_children():
		c.queue_free()
	for i in range(SaveSystem.SLOT_COUNT):
		var info := SaveSystem.get_slot_info(i)
		var btn := Button.new()
		if info.get("empty", true):
			btn.text = "Slot %d — Empty" % (i + 1)
			btn.disabled = true
		else:
			btn.text = "Slot %d — %s · %s · Day %s" % [
				i + 1, info.get("name", "?"), info.get("era", "?"), str(info.get("day", 1))
			]
			btn.pressed.connect(_on_load_slot.bind(i))
		btn.custom_minimum_size = Vector2(360, 40)
		load_list.add_child(btn)


func _on_era_pressed(era_id: String) -> void:
	_selected_era = era_id
	var era: Dictionary = EraManager.ERAS[era_id]
	era_desc.text = "%s\n%s\nVehicle: %s · Tools: %s" % [
		era["tagline"],
		"Fashion & tech shift with the era.",
		era["vehicle"],
		", ".join(era["tools"]),
	]


func _on_new_game() -> void:
	main_buttons.visible = false
	how_to.visible = false
	era_panel.visible = true
	load_panel.visible = false


func _on_continue_era() -> void:
	EraManager.set_era(_selected_era)
	GameState.phase = GameState.GamePhase.CUSTOMIZE
	get_tree().change_scene_to_file("res://scenes/ui/CharacterCustomizer.tscn")


func _on_load_game() -> void:
	main_buttons.visible = false
	how_to.visible = false
	era_panel.visible = false
	load_panel.visible = true
	_populate_loads()


func _on_load_slot(slot: int) -> void:
	if SaveSystem.load_game(slot):
		get_tree().change_scene_to_file("res://scenes/world/Town.tscn")


func _on_back() -> void:
	main_buttons.visible = true
	how_to.visible = true
	era_panel.visible = false
	load_panel.visible = false


func _on_quit() -> void:
	get_tree().quit()
