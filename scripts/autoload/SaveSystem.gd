extends Node
## Save / load slots under user://saves/

const SAVE_DIR := "user://saves"
const SLOT_COUNT := 3


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, slot]


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


func save_game(slot: int = 0) -> bool:
	var data := GameState.to_dict()
	data["saved_at"] = Time.get_datetime_string_from_system()
	data["version"] = "0.1.0"
	var path := slot_path(slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Save failed: %s" % FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	EventBus.game_saved.emit()
	EventBus.notification.emit("Game saved (slot %d)." % (slot + 1), 2.0)
	return true


func load_game(slot: int = 0) -> bool:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		EventBus.notification.emit("No save in slot %d." % (slot + 1), 2.0)
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Corrupt save file")
		return false
	GameState.from_dict(parsed)
	EventBus.notification.emit("Game loaded (slot %d)." % (slot + 1), 2.0)
	return true


func delete_save(slot: int) -> void:
	var path := slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func get_slot_info(slot: int) -> Dictionary:
	if not has_save(slot):
		return {"empty": true}
	var file := FileAccess.open(slot_path(slot), FileAccess.READ)
	if file == null:
		return {"empty": true}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"empty": true}
	return {
		"empty": false,
		"name": parsed.get("character", {}).get("name", "Detective"),
		"era": parsed.get("era_id", "present"),
		"saved_at": parsed.get("saved_at", ""),
		"day": parsed.get("time", {}).get("day", 1),
	}
