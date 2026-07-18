extends Node
## Central game state: player identity, needs, inventory, reputation, relationships.

enum GamePhase { MENU, CUSTOMIZE, PLAYING, PAUSED, DIALOGUE, BUILD }

var phase: GamePhase = GamePhase.MENU

# --- Character ---
var character: Dictionary = {
	"name": "Detective",
	"gender": "neutral",
	"body_type": 1,       # 0 slim, 1 average, 2 athletic
	"skin_tone": 2,       # 0-5
	"hair_style": 0,      # index
	"hair_color": 0,
	"face_style": 0,
	"outfit": 0,
	"accessory": 0,       # hat / glasses index
	"primary_color": Color(0.2, 0.25, 0.4),
	"secondary_color": Color(0.75, 0.7, 0.55),
}

# --- Needs (0-100) ---
var hunger: float = 80.0
var energy: float = 90.0
var mood: float = 75.0

# --- Meta ---
var reputation: int = 50          # 0-100 town standing
var money: int = 500
var inventory: Array[Dictionary] = []   # {id, name, type, desc}
var relationships: Dictionary = {}      # npc_id -> -100..100
var house_furniture: Array[Dictionary] = []
var player_position: Vector3 = Vector3(0, 1, 8)
var player_rotation_y: float = 0.0
var current_location: String = "town"   # town | house | office

# Flags
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
	energy = 90.0
	mood = 75.0
	reputation = 50
	money = 500
	inventory.clear()
	relationships.clear()
	_seed_default_relationships()
	house_furniture = _default_furniture()
	player_position = Vector3(0, 1.5, 10)
	player_rotation_y = 0.0
	current_location = "town"
	tutorial_done = false
	active_case_id = ""
	EraManager.set_era(era_id)
	TimeSystem.reset_clock()
	CaseManager.reset_cases()
	phase = GamePhase.PLAYING
	EventBus.needs_changed.emit(hunger, energy, mood)


func _default_furniture() -> Array[Dictionary]:
	return [
		{"id": "bed", "name": "Bed", "pos": Vector3(-3, 0, -2), "rot": 0.0},
		{"id": "table", "name": "Table", "pos": Vector3(2, 0, 0), "rot": 0.0},
		{"id": "chair", "name": "Chair", "pos": Vector3(2, 0, 1.2), "rot": 0.0},
		{"id": "desk", "name": "Detective Desk", "pos": Vector3(-2, 0, 2), "rot": 0.0},
		{"id": "lamp", "name": "Lamp", "pos": Vector3(-1.2, 0, 2), "rot": 0.0},
	]


func tick_needs(delta: float) -> void:
	if phase != GamePhase.PLAYING:
		return
	# Drain rates per real second (scaled by time speed elsewhere if desired)
	hunger = clampf(hunger - delta * 0.35, 0.0, 100.0)
	energy = clampf(energy - delta * 0.22, 0.0, 100.0)
	# Mood suffers when needs are low
	var pressure := 0.0
	if hunger < 30.0:
		pressure += 0.15
	if energy < 25.0:
		pressure += 0.12
	mood = clampf(mood - pressure * delta + delta * 0.02, 0.0, 100.0)
	EventBus.needs_changed.emit(hunger, energy, mood)


func eat(amount: float = 35.0) -> void:
	hunger = clampf(hunger + amount, 0.0, 100.0)
	mood = clampf(mood + 5.0, 0.0, 100.0)
	EventBus.needs_changed.emit(hunger, energy, mood)
	EventBus.notification.emit("You had a solid meal.", 2.0)


func sleep(amount: float = 60.0) -> void:
	energy = clampf(energy + amount, 0.0, 100.0)
	mood = clampf(mood + 10.0, 0.0, 100.0)
	TimeSystem.advance_hours(8.0)
	EventBus.needs_changed.emit(hunger, energy, mood)
	EventBus.notification.emit("You slept. A new day awaits.", 2.5)


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
		"character": character,
		"hunger": hunger,
		"energy": energy,
		"mood": mood,
		"reputation": reputation,
		"money": money,
		"inventory": inventory,
		"relationships": relationships,
		"house_furniture": house_furniture,
		"player_position": {"x": player_position.x, "y": player_position.y, "z": player_position.z},
		"player_rotation_y": player_rotation_y,
		"current_location": current_location,
		"tutorial_done": tutorial_done,
		"active_case_id": active_case_id,
		"era_id": EraManager.current_era_id,
		"time": TimeSystem.to_dict(),
		"cases": CaseManager.to_dict(),
	}


func from_dict(data: Dictionary) -> void:
	character = data.get("character", character)
	hunger = float(data.get("hunger", 80))
	energy = float(data.get("energy", 90))
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
	player_position = Vector3(float(p.get("x", 0)), float(p.get("y", 1)), float(p.get("z", 8)))
	player_rotation_y = float(data.get("player_rotation_y", 0))
	current_location = str(data.get("current_location", "town"))
	tutorial_done = bool(data.get("tutorial_done", false))
	active_case_id = str(data.get("active_case_id", ""))
	EraManager.set_era(str(data.get("era_id", "present")))
	TimeSystem.from_dict(data.get("time", {}))
	CaseManager.from_dict(data.get("cases", {}))
	phase = GamePhase.PLAYING
	EventBus.needs_changed.emit(hunger, energy, mood)
	EventBus.game_loaded.emit()
