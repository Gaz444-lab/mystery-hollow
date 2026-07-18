extends Node
## GameManager — central runtime state for Mystery Hollow.
## Character, needs (life sim), inventory, relationships, house, location.

enum GamePhase { MENU, ERA_SELECT, CUSTOMIZE, BACKSTORY, PLAYING, PAUSED, DIALOGUE, BUILD }

var phase: GamePhase = GamePhase.MENU

## Full character profile (era-aware appearance + identity)
var character: Dictionary = {
	"name": "Detective",
	"gender": "neutral",       # masculine | feminine | neutral
	"height": 1,               # 0 short, 1 average, 2 tall
	"body_type": 1,            # 0 slim, 1 average, 2 athletic
	"skin_tone": 2,
	"hair_style": 0,
	"hair_color": 0,
	"eye_color": 0,
	"face_style": 0,
	"facial_hair": 0,
	"outfit": 0,               # top / suit style index
	"bottoms": 0,
	"shoes": 0,
	"outerwear": 0,
	"accessory": 0,            # 0 none, 1 glasses, 2 hat, 3 watch
	"badge": 1,
	"primary_color": Color(0.18, 0.22, 0.32),
	"secondary_color": Color(0.32, 0.28, 0.24),
	"backstory": "local",      # local | transfer | returning
}

# Life sim needs 0–100
var hunger: float = 80.0
var thirst: float = 80.0
var energy: float = 90.0
var hygiene: float = 85.0
var mood: float = 75.0

var reputation: int = 50
var money: int = 500
var inventory: Array[Dictionary] = []
var relationships: Dictionary = {}
var house_furniture: Array[Dictionary] = []
var player_position: Vector3 = Vector3(0, 1.5, 10)
var player_rotation_y: float = 0.0
var current_location: String = "town"  # town | house | office
var weather: String = "clear"          # clear | rain | fog | overcast
var tutorial_done: bool = false
var active_case_id: String = ""


func _ready() -> void:
	_seed_default_relationships()


func _seed_default_relationships() -> void:
	for npc_id in ["mayor_hart", "deputy_cole", "dr_ellis", "bartender_sam",
			"shopkeeper_rita", "witness_ben", "suspect_vera", "suspect_marcus", "suspect_owen"]:
		if not relationships.has(npc_id):
			relationships[npc_id] = 0


func new_game(era_id: String, char_data: Dictionary) -> void:
	character = char_data.duplicate(true)
	hunger = 80.0
	thirst = 80.0
	energy = 90.0
	hygiene = 85.0
	mood = 75.0
	reputation = 50
	money = 500
	inventory.clear()
	relationships.clear()
	_seed_default_relationships()
	house_furniture = _default_furniture()
	player_position = Vector3(0, 1.5, 12)
	player_rotation_y = 0.0
	current_location = "town"
	weather = "clear"
	tutorial_done = false
	active_case_id = ""
	EraManager.set_era(era_id)
	TimeSystem.reset_clock()
	CaseManager.reset_cases()
	phase = GamePhase.PLAYING
	_emit_needs()


func _default_furniture() -> Array[Dictionary]:
	return [
		{"id": "bed", "name": "Bed", "pos": Vector3(-3, 0, -2), "rot": 0.0},
		{"id": "table", "name": "Table", "pos": Vector3(2, 0, 0), "rot": 0.0},
		{"id": "chair", "name": "Chair", "pos": Vector3(2, 0, 1.2), "rot": 0.0},
		{"id": "desk", "name": "Detective Desk", "pos": Vector3(-2, 0, 2), "rot": 0.0},
		{"id": "lamp", "name": "Lamp", "pos": Vector3(-1.2, 0, 2), "rot": 0.0},
		{"id": "sink", "name": "Sink", "pos": Vector3(3, 0, -2), "rot": 0.0},
	]


func tick_needs(delta: float) -> void:
	if phase != GamePhase.PLAYING:
		return
	hunger = clampf(hunger - delta * 0.28, 0.0, 100.0)
	thirst = clampf(thirst - delta * 0.38, 0.0, 100.0)
	energy = clampf(energy - delta * 0.18, 0.0, 100.0)
	hygiene = clampf(hygiene - delta * 0.12, 0.0, 100.0)
	var pressure := 0.0
	if hunger < 30.0:
		pressure += 0.12
	if thirst < 25.0:
		pressure += 0.14
	if energy < 25.0:
		pressure += 0.1
	if hygiene < 30.0:
		pressure += 0.08
	mood = clampf(mood - pressure * delta + delta * 0.015, 0.0, 100.0)
	_emit_needs()


func _emit_needs() -> void:
	EventBus.needs_changed.emit(hunger, energy, mood)
	EventBus.needs_full.emit(hunger, thirst, energy, hygiene, mood)


func eat(amount: float = 35.0) -> void:
	hunger = clampf(hunger + amount, 0.0, 100.0)
	mood = clampf(mood + 4.0, 0.0, 100.0)
	_emit_needs()
	EventBus.notification.emit("You eat. Hunger eases.", 2.0)


func drink(amount: float = 40.0) -> void:
	thirst = clampf(thirst + amount, 0.0, 100.0)
	_emit_needs()
	EventBus.notification.emit("You drink. Thirst eases.", 2.0)


func sleep(amount: float = 60.0) -> void:
	energy = clampf(energy + amount, 0.0, 100.0)
	mood = clampf(mood + 10.0, 0.0, 100.0)
	hygiene = clampf(hygiene - 8.0, 0.0, 100.0)
	TimeSystem.advance_hours(8.0)
	_emit_needs()
	EventBus.notification.emit("You sleep. A new day in Mystery Hollow.", 2.5)


func wash(amount: float = 50.0) -> void:
	hygiene = clampf(hygiene + amount, 0.0, 100.0)
	mood = clampf(mood + 3.0, 0.0, 100.0)
	_emit_needs()
	EventBus.notification.emit("You wash up. Hygiene restored.", 2.0)


func add_item(item: Dictionary) -> void:
	for existing in inventory:
		if existing.get("id") == item.get("id"):
			EventBus.notification.emit("Already have: %s" % item.get("name", "item"), 2.0)
			return
	inventory.append(item)
	EventBus.evidence_collected.emit(str(item.get("id", "")))
	EventBus.notification.emit("Collected: %s" % item.get("name", "item"), 2.5)


func has_item(item_id: String) -> bool:
	for item in inventory:
		if item.get("id") == item_id:
			return true
	return false


func change_relationship(npc_id: String, delta_val: int) -> void:
	var current: int = int(relationships.get(npc_id, 0))
	relationships[npc_id] = clampi(current + delta_val, -100, 100)
	EventBus.relationship_changed.emit(npc_id, relationships[npc_id])


func change_reputation(delta_val: int) -> void:
	reputation = clampi(reputation + delta_val, 0, 100)


func to_dict() -> Dictionary:
	return {
		"character": _character_to_json(character),
		"hunger": hunger,
		"thirst": thirst,
		"energy": energy,
		"hygiene": hygiene,
		"mood": mood,
		"reputation": reputation,
		"money": money,
		"inventory": inventory,
		"relationships": relationships,
		"house_furniture": house_furniture,
		"player_position": {"x": player_position.x, "y": player_position.y, "z": player_position.z},
		"player_rotation_y": player_rotation_y,
		"current_location": current_location,
		"weather": weather,
		"tutorial_done": tutorial_done,
		"active_case_id": active_case_id,
		"era_id": EraManager.current_era_id,
		"time": TimeSystem.to_dict(),
		"cases": CaseManager.to_dict(),
	}


func from_dict(data: Dictionary) -> void:
	character = data.get("character", character)
	if character.has("primary_color"):
		character["primary_color"] = _color_from(character["primary_color"])
	if character.has("secondary_color"):
		character["secondary_color"] = _color_from(character["secondary_color"])
	hunger = float(data.get("hunger", 80))
	thirst = float(data.get("thirst", 80))
	energy = float(data.get("energy", 90))
	hygiene = float(data.get("hygiene", 85))
	mood = float(data.get("mood", 75))
	reputation = int(data.get("reputation", 50))
	money = int(data.get("money", 500))
	inventory.clear()
	for item in data.get("inventory", []):
		inventory.append(item)
	relationships = data.get("relationships", {})
	_seed_default_relationships()
	house_furniture.clear()
	for f in data.get("house_furniture", _default_furniture()):
		house_furniture.append(f)
	var p: Dictionary = data.get("player_position", {})
	player_position = Vector3(float(p.get("x", 0)), float(p.get("y", 1.5)), float(p.get("z", 12)))
	player_rotation_y = float(data.get("player_rotation_y", 0))
	current_location = str(data.get("current_location", "town"))
	weather = str(data.get("weather", "clear"))
	tutorial_done = bool(data.get("tutorial_done", false))
	active_case_id = str(data.get("active_case_id", ""))
	EraManager.set_era(str(data.get("era_id", "present")))
	TimeSystem.from_dict(data.get("time", {}))
	CaseManager.from_dict(data.get("cases", {}))
	phase = GamePhase.PLAYING
	_emit_needs()
	EventBus.game_loaded.emit()


func _character_to_json(c: Dictionary) -> Dictionary:
	var out := c.duplicate(true)
	if out.get("primary_color") is Color:
		var col: Color = out["primary_color"]
		out["primary_color"] = {"r": col.r, "g": col.g, "b": col.b, "a": col.a}
	if out.get("secondary_color") is Color:
		var col2: Color = out["secondary_color"]
		out["secondary_color"] = {"r": col2.r, "g": col2.g, "b": col2.b, "a": col2.a}
	return out


func _color_from(v: Variant) -> Color:
	if v is Color:
		return v
	if v is Dictionary:
		return Color(float(v.get("r", 0.2)), float(v.get("g", 0.2)), float(v.get("b", 0.3)), float(v.get("a", 1)))
	return Color(0.18, 0.22, 0.32)
