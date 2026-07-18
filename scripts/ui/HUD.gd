extends CanvasLayer
## In-game HUD: needs, clock, prompts, journal, dialogue, accusation, pause.

@onready var needs_label: Label = %NeedsLabel
@onready var clock_label: Label = %ClockLabel
@onready var prompt_label: Label = %PromptLabel
@onready var notice_label: Label = %NoticeLabel
@onready var journal: PanelContainer = %JournalPanel
@onready var journal_text: RichTextLabel = %JournalText
@onready var dialogue: PanelContainer = %DialoguePanel
@onready var dialogue_speaker: Label = %DialogueSpeaker
@onready var dialogue_body: RichTextLabel = %DialogueBody
@onready var dialogue_options: VBoxContainer = %DialogueOptions
@onready var lie_label: Label = %LieLabel
@onready var accuse_panel: PanelContainer = %AccusePanel
@onready var accuse_list: VBoxContainer = %AccuseList
@onready var pause_panel: PanelContainer = %PausePanel
@onready var inventory_panel: PanelContainer = %InventoryPanel
@onready var inventory_text: RichTextLabel = %InventoryText
@onready var ending_panel: PanelContainer = %EndingPanel
@onready var ending_text: RichTextLabel = %EndingText

var _dialogue_nodes: Array = []
var _dialogue_index: Dictionary = {}
var _current_npc_id: String = ""
var _current_npc_name: String = ""
var _notice_timer: float = 0.0


func _ready() -> void:
	add_to_group("hud")
	journal.visible = false
	dialogue.visible = false
	accuse_panel.visible = false
	pause_panel.visible = false
	inventory_panel.visible = false
	ending_panel.visible = false
	prompt_label.text = ""
	notice_label.text = ""
	lie_label.text = ""
	EventBus.needs_changed.connect(_on_needs)
	EventBus.time_changed.connect(_on_time)
	EventBus.interaction_available.connect(func(t): prompt_label.text = t)
	EventBus.interaction_cleared.connect(func(): prompt_label.text = "")
	EventBus.notification.connect(_on_notice)
	EventBus.accusation_result.connect(_on_ending)
	EventBus.case_updated.connect(func(_c): _refresh_journal())
	_on_needs(GameState.hunger, GameState.energy, GameState.mood)
	_on_time(TimeSystem.get_hour(), TimeSystem.day)


func _process(delta: float) -> void:
	if _notice_timer > 0.0:
		_notice_timer -= delta
		if _notice_timer <= 0.0:
			notice_label.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("journal"):
		if dialogue.visible:
			return
		journal.visible = not journal.visible
		if journal.visible:
			_refresh_journal()
			_free_cursor(true)
		else:
			_free_cursor(false)
	if event.is_action_pressed("inventory"):
		inventory_panel.visible = not inventory_panel.visible
		if inventory_panel.visible:
			_refresh_inventory()
			_free_cursor(true)
		else:
			_free_cursor(false)
	if event.is_action_pressed("pause_menu") and not dialogue.visible:
		pause_panel.visible = not pause_panel.visible
		GameState.phase = GameState.GamePhase.PAUSED if pause_panel.visible else GameState.GamePhase.PLAYING
		TimeSystem.paused = pause_panel.visible
		_free_cursor(pause_panel.visible)
	if event.is_action_pressed("build_mode") and GameState.current_location == "house":
		EventBus.notification.emit("Build mode: furniture list saved with your home. Expand in future updates.", 3.0)


func open_journal() -> void:
	journal.visible = true
	_refresh_journal()
	_free_cursor(true)


func open_dialogue(npc_id: String, display_name: String) -> void:
	_current_npc_id = npc_id
	_current_npc_name = display_name
	_dialogue_nodes = CaseManager.get_dialogue_for(npc_id)
	_dialogue_index.clear()
	for n in _dialogue_nodes:
		_dialogue_index[n.get("id", "")] = n
	GameState.phase = GameState.GamePhase.DIALOGUE
	TimeSystem.paused = true
	dialogue.visible = true
	_free_cursor(true)
	_show_node("start")
	CaseManager.mark_interviewed(npc_id)
	EventBus.dialogue_started.emit(npc_id)


func open_accusation() -> void:
	accuse_panel.visible = true
	_free_cursor(true)
	for c in accuse_list.get_children():
		c.queue_free()
	var def := CaseManager.get_active_def()
	if def.is_empty():
		var lbl := Label.new()
		lbl.text = "No active case. Accept one at the Agency."
		accuse_list.add_child(lbl)
		return
	if not CaseManager.can_accuse():
		var need := Label.new()
		need.text = "Not enough evidence to accuse. Required clues still missing."
		need.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		accuse_list.add_child(need)
	for s in def.get("suspects", []):
		var btn := Button.new()
		btn.text = "Accuse %s (%s)" % [s.get("name"), s.get("role")]
		btn.pressed.connect(_on_accuse.bind(str(s.get("id"))))
		accuse_list.add_child(btn)
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.pressed.connect(func():
		accuse_panel.visible = false
		_free_cursor(false)
	)
	accuse_list.add_child(cancel)


func _on_accuse(suspect_id: String) -> void:
	var result := CaseManager.make_accusation(suspect_id)
	accuse_panel.visible = false
	ending_panel.visible = true
	ending_text.text = result.get("message", "")
	_free_cursor(true)


func _show_node(node_id: String) -> void:
	if not _dialogue_index.has(node_id):
		_close_dialogue()
		return
	var node: Dictionary = _dialogue_index[node_id]
	dialogue_speaker.text = str(node.get("speaker", _current_npc_name))
	dialogue_body.text = str(node.get("text", ""))
	lie_label.text = ""
	if bool(node.get("lie_flag", false)) and node.has("lie_tell"):
		lie_label.text = "⚠ Tell: %s" % node["lie_tell"]
	if node.has("gives_evidence"):
		CaseManager.collect_evidence(str(node["gives_evidence"]))
	for c in dialogue_options.get_children():
		c.queue_free()
	var options: Array = node.get("options", [])
	if options.is_empty():
		var done := Button.new()
		done.text = "Leave"
		done.pressed.connect(_close_dialogue)
		dialogue_options.add_child(done)
		return
	for opt in options:
		var req: Array = opt.get("requires_evidence", [])
		var locked := false
		for r in req:
			if not CaseManager.has_evidence(str(r)) and not GameState.has_item(str(r)):
				locked = true
				break
		var btn := Button.new()
		btn.text = str(opt.get("text", "..."))
		if locked:
			btn.text += "  [need evidence]"
			btn.disabled = true
		btn.pressed.connect(_on_option.bind(opt))
		dialogue_options.add_child(btn)


func _on_option(opt: Dictionary) -> void:
	var rel: int = int(opt.get("rel", 0))
	if rel != 0:
		GameState.change_relationship(_current_npc_id, rel)
	if opt.get("action", "") == "eat":
		GameState.eat(20.0)
	var next: String = str(opt.get("next", "end"))
	if next == "end" or not _dialogue_index.has(next):
		# show end node if exists
		if _dialogue_index.has("end") and next == "end":
			_show_node("end")
			# if end has no options, still show leave
			return
		_close_dialogue()
		return
	_show_node(next)


func _close_dialogue() -> void:
	dialogue.visible = false
	GameState.phase = GameState.GamePhase.PLAYING
	TimeSystem.paused = false
	_free_cursor(false)
	EventBus.dialogue_ended.emit(_current_npc_id)


func _refresh_journal() -> void:
	var def := CaseManager.get_active_def()
	var state := CaseManager.get_active_state()
	var era := EraManager.get_era()
	var lines: PackedStringArray = []
	lines.append("[b]Detective Journal[/b]")
	lines.append("Era: %s · Reputation: %d · $%d" % [era["label"], GameState.reputation, GameState.money])
	lines.append("")
	if def.is_empty():
		lines.append("[i]No active case. Visit the Detective Agency.[/i]")
	else:
		lines.append("[b]%s[/b]" % def.get("title", "Case"))
		lines.append(str(def.get("summary", "")))
		lines.append("")
		lines.append("[b]Evidence[/b]")
		var found: Array = state.get("evidence_found", [])
		for e in def.get("evidence", []):
			var mark := "✓" if e.get("id") in found else "○"
			lines.append("%s %s — %s" % [mark, e.get("name"), e.get("description")])
		lines.append("")
		lines.append("[b]Suspects[/b]")
		for s in def.get("suspects", []):
			lines.append("• %s (%s) — %s" % [s.get("name"), s.get("role"), s.get("bio")])
		lines.append("")
		lines.append("[b]Interviewed[/b]: %s" % ", ".join(state.get("interviewed", [])) if state.get("interviewed", []) else "None yet")
		if CaseManager.can_accuse():
			lines.append("")
			lines.append("[color=gold]You have enough to make an accusation at the Agency.[/color]")
	journal_text.text = "\n".join(lines)


func _refresh_inventory() -> void:
	var lines: PackedStringArray = ["[b]Inventory[/b]", ""]
	if GameState.inventory.is_empty():
		lines.append("[i]Empty pockets.[/i]")
	else:
		for item in GameState.inventory:
			lines.append("• [b]%s[/b] (%s)" % [item.get("name"), item.get("type", "item")])
			lines.append("  %s" % item.get("desc", ""))
	inventory_text.text = "\n".join(lines)


func _on_needs(h: float, e: float, m: float) -> void:
	needs_label.text = "Hunger %d  |  Energy %d  |  Mood %d" % [int(h), int(e), int(m)]


func _on_time(hour: float, day: int) -> void:
	var period := "Night" if TimeSystem.is_night() else "Day"
	clock_label.text = "Day %d  %s  (%s)" % [day, TimeSystem.get_clock_string(), period]


func _on_notice(text: String, duration: float) -> void:
	notice_label.text = text
	_notice_timer = duration


func _on_ending(success: bool, _ending_id: String) -> void:
	if not ending_panel.visible:
		ending_panel.visible = true
		_free_cursor(true)


func _free_cursor(free: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if free else Input.MOUSE_MODE_CAPTURED


func _on_save() -> void:
	SaveSystem.save_game(0)


func _on_save_slot(slot: int) -> void:
	SaveSystem.save_game(slot)


func _on_main_menu() -> void:
	TimeSystem.paused = false
	GameState.phase = GameState.GamePhase.MENU
	get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")


func _on_resume() -> void:
	pause_panel.visible = false
	GameState.phase = GameState.GamePhase.PLAYING
	TimeSystem.paused = false
	_free_cursor(false)


func _on_close_ending() -> void:
	ending_panel.visible = false
	_free_cursor(false)
	GameState.phase = GameState.GamePhase.PLAYING
