extends Node
## Loads cases, tracks evidence, interviews, and endings.

var cases: Dictionary = {}           # case_id -> runtime state
var case_defs: Dictionary = {}       # case_id -> static definition from JSON
var active_case_id: String = ""


func _ready() -> void:
	_load_case_defs()


func _load_case_defs() -> void:
	case_defs.clear()
	var dir := DirAccess.open("res://data/cases")
	if dir == null:
		push_warning("No cases folder found")
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			var path := "res://data/cases/%s" % file_name
			var f := FileAccess.open(path, FileAccess.READ)
			if f:
				var parsed = JSON.parse_string(f.get_as_text())
				f.close()
				if typeof(parsed) == TYPE_DICTIONARY and parsed.has("id"):
					case_defs[parsed["id"]] = parsed
		file_name = dir.get_next()
	dir.list_dir_end()


func reset_cases() -> void:
	cases.clear()
	active_case_id = ""
	GameState.active_case_id = ""
	for id in case_defs.keys():
		cases[id] = {
			"status": "available" if case_defs[id].get("starts_available", false) else "locked",
			"evidence_found": [],
			"interviewed": [],
			"notes": [],
			"board_links": [],
			"ending": "",
		}


func accept_case(case_id: String) -> bool:
	if not cases.has(case_id):
		return false
	if cases[case_id]["status"] == "locked":
		return false
	cases[case_id]["status"] = "active"
	active_case_id = case_id
	GameState.active_case_id = case_id
	EventBus.case_updated.emit(case_id)
	EventBus.notification.emit("Case accepted: %s" % case_defs[case_id].get("title", case_id), 3.0)
	return true


func get_active_def() -> Dictionary:
	if active_case_id == "" or not case_defs.has(active_case_id):
		return {}
	return case_defs[active_case_id]


func get_active_state() -> Dictionary:
	if active_case_id == "" or not cases.has(active_case_id):
		return {}
	return cases[active_case_id]


func collect_evidence(evidence_id: String) -> void:
	if active_case_id == "":
		return
	var state: Dictionary = cases[active_case_id]
	var found: Array = state["evidence_found"]
	if evidence_id in found:
		return
	found.append(evidence_id)
	state["evidence_found"] = found
	var def := get_active_def()
	var evidence_list: Array = def.get("evidence", [])
	for e in evidence_list:
		if e.get("id") == evidence_id:
			GameState.add_item({
				"id": e["id"],
				"name": e.get("name", evidence_id),
				"type": "evidence",
				"desc": e.get("description", ""),
			})
			break
	EventBus.case_updated.emit(active_case_id)


func mark_interviewed(npc_id: String) -> void:
	if active_case_id == "":
		return
	var state: Dictionary = cases[active_case_id]
	var interviewed: Array = state["interviewed"]
	if npc_id not in interviewed:
		interviewed.append(npc_id)
		state["interviewed"] = interviewed
		EventBus.case_updated.emit(active_case_id)


func add_note(text: String) -> void:
	if active_case_id == "":
		return
	var state: Dictionary = cases[active_case_id]
	var notes: Array = state["notes"]
	notes.append(text)
	state["notes"] = notes
	EventBus.case_updated.emit(active_case_id)


func has_evidence(evidence_id: String) -> bool:
	var state := get_active_state()
	if state.is_empty():
		return false
	return evidence_id in state.get("evidence_found", [])


func can_accuse() -> bool:
	var def := get_active_def()
	var state := get_active_state()
	if def.is_empty() or state.is_empty():
		return false
	if state.get("status") != "active":
		return false
	var required: Array = def.get("required_evidence_to_accuse", [])
	for req in required:
		if req not in state.get("evidence_found", []):
			return false
	return true


func make_accusation(suspect_id: String) -> Dictionary:
	## Returns {success, ending_id, message}
	var def := get_active_def()
	var state := get_active_state()
	if def.is_empty():
		return {"success": false, "ending_id": "none", "message": "No active case."}
	if not can_accuse():
		return {"success": false, "ending_id": "insufficient", "message": "You need more evidence before accusing anyone."}

	var correct: String = str(def.get("correct_suspect", ""))
	var endings: Dictionary = def.get("endings", {})
	var success := suspect_id == correct
	var ending_id := "correct" if success else "wrong_%s" % suspect_id
	if not endings.has(ending_id):
		ending_id = "correct" if success else "wrong_generic"

	var ending: Dictionary = endings.get(ending_id, {})
	state["status"] = "solved" if success else "failed"
	state["ending"] = ending_id
	active_case_id = ""
	GameState.active_case_id = ""

	if success:
		GameState.change_reputation(15)
		GameState.mood = clampf(GameState.mood + 20.0, 0.0, 100.0)
		GameState.money += int(ending.get("reward", 200))
		_unlock_next_case(str(def.get("id", "")))
	else:
		GameState.change_reputation(-10)
		GameState.mood = clampf(GameState.mood - 15.0, 0.0, 100.0)

	var message := str(ending.get("text", "Case closed."))
	EventBus.accusation_result.emit(success, ending_id)
	EventBus.case_updated.emit(def.get("id", ""))
	return {"success": success, "ending_id": ending_id, "message": message}


func get_dialogue_for(npc_id: String) -> Array:
	## Returns dialogue nodes for this NPC on the active case (or town smalltalk).
	var def := get_active_def()
	if not def.is_empty():
		var dialogues: Dictionary = def.get("dialogues", {})
		if dialogues.has(npc_id):
			return dialogues[npc_id]
	return _fallback_smalltalk(npc_id)


func _fallback_smalltalk(npc_id: String) -> Array:
	return [
		{
			"id": "start",
			"speaker": npc_id,
			"text": "Morning, Detective. Quiet day in Mystery Hollow… for now.",
			"options": [
				{"text": "Anything unusual lately?", "next": "unusual", "rel": 1},
				{"text": "Just passing through.", "next": "end", "rel": 0},
			],
		},
		{
			"id": "unusual",
			"speaker": npc_id,
			"text": "Heard some talk down by the river. Might be nothing. Might not.",
			"options": [
				{"text": "Thanks for the tip.", "next": "end", "rel": 2},
			],
		},
		{
			"id": "end",
			"speaker": npc_id,
			"text": "Take care of yourself out there.",
			"options": [],
		},
	]


func _unlock_next_case(solved_id: String) -> void:
	var chain := {
		"case_01_riverside": "case_02_midnight_diner",
		"case_02_midnight_diner": "case_03_church_bell",
	}
	if not chain.has(solved_id):
		return
	var next_id: String = chain[solved_id]
	if cases.has(next_id) and cases[next_id].get("status") == "locked":
		cases[next_id]["status"] = "available"
		EventBus.notification.emit("New case available at the Agency: check the board.", 4.0)


func to_dict() -> Dictionary:
	return {"cases": cases, "active_case_id": active_case_id}


func from_dict(data: Dictionary) -> void:
	if data.is_empty():
		reset_cases()
		return
	cases = data.get("cases", {})
	active_case_id = str(data.get("active_case_id", ""))
	GameState.active_case_id = active_case_id
	# Ensure all defs exist in state
	for id in case_defs.keys():
		if not cases.has(id):
			cases[id] = {
				"status": "available" if case_defs[id].get("starts_available", false) else "locked",
				"evidence_found": [],
				"interviewed": [],
				"notes": [],
				"board_links": [],
				"ending": "",
			}
