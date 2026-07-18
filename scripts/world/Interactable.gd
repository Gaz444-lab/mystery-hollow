extends StaticBody3D
class_name Interactable
## Generic world interactable: door, evidence, bed, food, case board, etc.

@export var interact_id: String = ""
@export var label: String = "Interact"
@export var interact_type: String = "generic"  # evidence, door, bed, food, npc, case_board, accuse, furniture

signal interacted(actor: Node)


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 4
	collision_mask = 0


func get_interact_label() -> String:
	return "E — %s" % label


func interact(actor: Node) -> void:
	interacted.emit(actor)
	match interact_type:
		"evidence":
			_collect_evidence()
		"bed":
			GameState.sleep()
		"food":
			GameState.eat()
		"door_house":
			EventBus.notification.emit("Entering your home…", 1.5)
			get_tree().call_group("game_root", "enter_location", "house")
		"door_office":
			EventBus.notification.emit("Entering the Detective Agency…", 1.5)
			get_tree().call_group("game_root", "enter_location", "office")
		"door_town":
			get_tree().call_group("game_root", "enter_location", "town")
		"case_accept":
			CaseManager.accept_case("case_01_riverside")
		"case_board":
			get_tree().call_group("hud", "open_journal")
		"accuse":
			get_tree().call_group("hud", "open_accusation")
		"npc":
			pass  # handled by NPC script override
		_:
			EventBus.notification.emit(label, 1.5)


func _collect_evidence() -> void:
	if interact_id == "":
		return
	if CaseManager.has_evidence(interact_id):
		EventBus.notification.emit("Already collected.", 1.5)
		return
	CaseManager.collect_evidence(interact_id)
	visible = false
	# Disable further interaction
	collision_layer = 0
